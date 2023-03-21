// ========== Copyright Header Begin ============================================
// Copyright (c) 2023 Princeton University
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
// ========== Copyright Header End ============================================

// /home/gchirkov/tank/smappic/piton/verif/env/manycore/devices_ariane.xml


module traffic_shaper #(
    parameter DATA_WIDTH = 64,
    parameter ADD_LATENCY_FAST = 20,
    parameter ADD_LATENCY_SLOW = 100,
    parameter PKGS_PER_128_CYCLES_FAST = 0, 
    parameter PKGS_PER_128_CYCLES_SLOW = 0
) (
    input clk_in,
    input rst_n_in,
    input clk_out,
    input rst_n_out,
    input fast,

    input wire [DATA_WIDTH-1:0] data_in, // Data to be sent
    input wire valid_in,                // Data valid
    output wire ready_in,              // Ready to receive data

    output wire [DATA_WIDTH-1:0] data_out, // Data to be sent
    output wire valid_out,                // Data valid
    input wire  ready_out                   // Ready to receive data
);

localparam CLOCK_WIDTH = 32;

reg [CLOCK_WIDTH-1:0] clock;
always @(posedge clk_out) begin
    if (~rst_n_out) begin
        clock <= 0;
    end
    else begin
        clock <= clock + 1;
    end
end

wire out_go = valid_out & ready_out;
reg [31:0] pkg_counter;
wire [31:0] pkg_counter_plus_request = pkg_counter + out_go;
always @(posedge clk_out) begin
    if (~rst_n_out) begin
        pkg_counter <= 0;
    end
    else begin
        if (clock[6:0] == 0) begin
            pkg_counter <= out_go;
        end
        else begin
            pkg_counter <= pkg_counter_plus_request;
        end
    end
end
wire bw_ok_slow = (PKGS_PER_128_CYCLES_SLOW == 0) | (pkg_counter < PKGS_PER_128_CYCLES_SLOW);
wire bw_ok_fast = (PKGS_PER_128_CYCLES_FAST == 0) | (pkg_counter < PKGS_PER_128_CYCLES_FAST);
wire bw_ok = fast ? bw_ok_fast : bw_ok_slow;

wire fifo_full;
wire fifo_empty;
wire [DATA_WIDTH+CLOCK_WIDTH-1:0] fifo_out;
wire [DATA_WIDTH-1:0] fifo_data_out = fifo_out[DATA_WIDTH-1:0];
wire [CLOCK_WIDTH-1:0] fifo_clock_out = fifo_out[DATA_WIDTH+CLOCK_WIDTH-1:DATA_WIDTH];

wire [CLOCK_WIDTH-1:0] add_time = fast ? ADD_LATENCY_FAST : ADD_LATENCY_SLOW;
wire [CLOCK_WIDTH-1:0] interval_low = fifo_clock_out;
wire [CLOCK_WIDTH-1:0] interval_high = {~fifo_clock_out[CLOCK_WIDTH-1], fifo_clock_out[CLOCK_WIDTH-2:0]};
wire its_time = (interval_low < interval_high) ? ((interval_low <= clock) & (clock <= interval_high)) : ((interval_low <= clock) | (clock <= interval_high));

wire ren = its_time & ready_out;
assign ready_in = ~fifo_full;
assign data_out = fifo_data_out;
assign valid_out = ~fifo_empty & its_time & bw_ok;


`ifdef PITON_FPGA_SYNTH
afifo_w96_d128  shaper_fifo(
    .rst(~rst_n_out),
    .wr_clk(clk_in),
    .rd_clk(clk_out),
    .rd_en(ren),
    .wr_en(valid_in),
    .din({clock + add_time, data_in}),
    .dout(fifo_out),
    .full(fifo_full),
    .empty(fifo_empty)
);
`else
async_fifo #(
    .DSIZE(DATA_WIDTH + CLOCK_WIDTH),
    .ASIZE(8),
    .MEMSIZE(128) 
) shaper_fifo (
    .rreset(~rst_n_out),
    .wreset(~rst_n_in),
    .wclk(clk_in),
    .rclk(clk_out),
    .ren(ren),
    .wval(valid_in),
    .wdata({clock + add_time, data_in}),
    .rdata(fifo_out),
    .wfull(fifo_full), 
    .rempty(fifo_empty)
);
`endif

// `ifdef PITON_FPGA_SYNTH
// generate
// if (BW_RATIO == 69) begin    
//     ila_0 shaper_ila_1(
//         .clk(clk_in), 
//         .probe0(valid_in), 
//         .probe1(data_in), 
//         .probe2(ready_in), 
//         .probe3(valid_out), 
//         .probe4(data_out), 
//         .probe5(ready_out)
//     );
// end
// endgenerate

endmodule : traffic_shaper

