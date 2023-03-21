// Copyright (c) 2022 Princeton University
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Princeton University nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

`include "l15.tmp.h"
`include "define.tmp.h"

module int_pktizer #(
    parameter NUM_HARTS = 4,
    parameter PLIC = 1'b0
) (
    input clk, 
    input rst_n, 

    input [2*NUM_HARTS-1:0] ints,

    output noc_val, 
    output [`NOC_DATA_WIDTH-1:0] noc_data, 
    input noc_rdy 
);

reg [2*NUM_HARTS-1:0] prev_ints;
always @(posedge clk) begin
    prev_ints <= ints;
end

wire int_different = |(prev_ints ^ ints);
wire read_new_int;
wire [2*NUM_HARTS-1:0] buf_ints;
wire buf_empty;

`ifdef PITON_PROTO
fifo_w128_d16 sync_fifo_1(
`ifdef PITON_FPGA_AFIFO_NO_SRST
    .rst(~rst_n),
`else // ifndef PITON_FPGA_AFIFO_NO_SRST
    .srst(~rst_n),
`endif // endif PITON_FPGA_AFIFO_NO_SRST
    .clk(clk),
    .rd_en(read_new_int),
    .wr_en(int_different),
    .din({{(128-2*NUM_HARTS){1'b0}}, ints}),
    .dout(buf_ints),
    .full(),
    .empty(buf_empty)
);
`else // ifndef PITON_PROTO
sync_fifo #(
.DSIZE(128),
.ASIZE(5),
.MEMSIZE(16) )
sync_fifo_1(
    .reset(~rst_n),
    .clk(clk),
    .ren(read_new_int),
    .wval(int_different),
    .wdata({{(128-2*NUM_HARTS){1'b0}}, ints}),
    .rdata(buf_ints),
    .full(), 
    .empty(buf_empty)
);
`endif //endif PITON_PROTO

// track interrupt state at remote destinations
reg [2*NUM_HARTS-1:0] remote_ints;



// flow control
localparam IDLE = 2'd0;
localparam SEND_FIRST = 2'd1;
localparam SEND_SECOND = 2'd2;

reg [1:0] state;
reg [`NOC_DATA_WIDTH-1:0] flit0;
reg [`NOC_DATA_WIDTH-1:0] flit1;

wire noc_go = noc_val & noc_rdy;
wire interrupt_incoming = |(remote_ints^buf_ints) & ~buf_empty;
assign read_new_int = ~interrupt_incoming;
wire interrupt_go = interrupt_incoming & ((state == IDLE) | (noc_go & (state == SEND_SECOND)));

always @(posedge clk) begin
    if(~rst_n) begin
        state <= IDLE;
    end else 
    begin
        case (state)
            IDLE: begin
                if (interrupt_incoming) begin
                    state <= SEND_FIRST;
                end
            end
            SEND_FIRST: begin
                if (noc_go) begin
                    state <= SEND_SECOND;
                end
            end 
            SEND_SECOND: begin
                if (noc_go) begin
                    state <= interrupt_incoming ? SEND_FIRST : IDLE;
                end
            end
            default: begin
                // nothing
            end        
        endcase
    end
end

assign noc_val = (state != IDLE);
assign noc_data = (state == SEND_FIRST)  ? flit0 
                : (state == SEND_SECOND) ? flit1
                :                          `NOC_DATA_WIDTH'b0;


wire [6:0] int_num;

int_pktizer_priority_encoder_7 prio_encoder(
    .data_in(buf_ints ^ remote_ints), 
    .data_out(int_num)
);


always @(posedge clk) begin
    if(~rst_n) begin
        remote_ints <= {2*NUM_HARTS{1'b0}};
    end 
    else begin
        if (state == SEND_FIRST && noc_go)
         remote_ints[int_num] <= buf_ints[int_num];
    end
end


// figure out pkt internals
// all this data (int_num, dst_hart, second, went_up, 
// chipid_dst, x_dst, y_dst) is valid only the cycle when 
// interrupt arrived from fifo

// in plic, input vector is (example with 2 harts)
// {irq_hart1[1], irq_hart1[0], irq_hart0[1], irq_hart0[0]}
// in clint:
// {timer_irq_hart1, timer_irq_hart0, ipi_hart1, ipi_hart0}
// first in PLIC is first irq, in CLINT - ipi
// second in PLIC is second irq, in CLINT - timer_irq
wire [`HOME_ID_WIDTH-1:0] dst_hart;
wire second; 
generate
if (PLIC == 1'b1) begin
    assign second = (int_num % 2) != 0;
    assign dst_hart = int_num >> 2;
end
else begin
    assign second = int_num >= NUM_HARTS;
    assign dst_hart = second ? int_num - NUM_HARTS : int_num;
end
endgenerate
wire went_up = buf_ints[int_num];



wire [`NOC_CHIPID_WIDTH-1:0] chipid_dst;
wire [`NOC_X_WIDTH-1:0] x_dst;
wire [`NOC_Y_WIDTH-1:0] y_dst;

flat_id_to_xychip coords(
    .flat_id(dst_hart), 
    .x_coord(x_dst),
    .y_coord(y_dst), 
    .chipid(chipid_dst)
);

// write data down in flits
always @(posedge clk) begin
    if(~rst_n) begin
        flit0 <= `NOC_DATA_WIDTH'b0;
        flit1 <= `NOC_DATA_WIDTH'b0;
    end 
    else begin
        if (interrupt_go) begin
            flit0[`MSG_DST_CHIPID] <= chipid_dst;
            flit0[`MSG_DST_X] <= x_dst;
            flit0[`MSG_DST_Y] <= y_dst;
            flit0[`MSG_DST_FBITS] <= 4'b0; // processor
            flit0[`MSG_LENGTH] <= 8'b1;
            flit0[`MSG_TYPE] <= `MSG_TYPE_INTERRUPT;

            flit1[1:0] <= {went_up, second};
            flit1[17:16] <= PLIC ? 2'b10 : 2'b11;
        end
    end
end

endmodule
