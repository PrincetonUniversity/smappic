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

//==================================================================================================
//  Filename      : int_pkt_gen
//  Author        : Kaifeng Xu
//  Company       : Princeton University
//  Email         : kaifengx@princeton.edu
//
//  Description   : inturrput package generator
//=================================================================================================

`include "define.tmp.h"

module dev_int_pkt_gen (
 //   input                               chip_clk,
    input                               fpga_clk,
    input                               rst_n,

    output                              noc_out_val,
    output reg [`NOC_DATA_WIDTH-1:0]    noc_out_data,
    input                               noc_out_rdy,

    input                               interrupt,

    input  [13:0]                       chip_id,
    input  [7:0]                        x_pos,
    input  [7:0]                        y_pos,
    input                               irq_le,      // 0:level, 1: edge
    input  [4:0]                        device_id    // 32 devices
);

// synchronize interrupt signals
wire sync_int;

synchronizer int_sync(
    .clk           (fpga_clk),
    .presyncdata   (interrupt),
    .syncdata      (sync_int)
);

reg   [1:0]      flit_cnt;
wire             pose_edge;
wire             fall_edge;

reg   [63:0]     pkt_flit1;
reg   [63:0]     pkt_flit2;
reg   [63:0]     pkt_flit2_fall;
reg              buffer_flit2_type; // 0:pose edge, 1:falling edge
//reg              last_pkt_type; // only used in level sensitive interrupts, to avoid losing low->high
reg   [63:0]     buffer_flit2_send;

// packet 
reg              prev_interrupt; // last cycle
reg              buf_prev_int; // last last cycle
reg              pending_interrupt;
reg              interrupt_in_prog;



// making wake up packet
parameter FLIT_TO_SEND = 2;


always @(posedge fpga_clk) begin
    if (~rst_n) begin
        flit_cnt <= 2'b0;
        pending_interrupt <= 1'b0;
        interrupt_in_prog <= 1'b0;
        buffer_flit2_type <= 1'b0;
        //last_pkt_type     <= 1'b1;
        buffer_flit2_send <= 64'b0;
    end
    else begin
        // the flit2 type, 0: pose edge, 1
        buffer_flit2_type <= (!prev_interrupt & sync_int)           ?  1'b0 // pose edge
                           : (!irq_le & prev_interrupt & !sync_int) ?  1'b1 // falling edge
                           :                                           1'b0;

        // Set pending bit
        pending_interrupt <= (pending_interrupt & interrupt_in_prog)  // already pending
                           | (irq_le & pose_edge)                     // edge sensitive
                           | (!irq_le & (pose_edge|fall_edge));       // level sensitive

        // from pending to operate
        if (pending_interrupt & !interrupt_in_prog) begin
            flit_cnt <= 2'b0;
            interrupt_in_prog <= 1'b1;
            buffer_flit2_send <= buffer_flit2_type ? pkt_flit2_fall : pkt_flit2;
            // last_pkt_type <= irq_le ? 1'b0 : buffer_flit2_type;
        end
        else if (interrupt_in_prog & (flit_cnt < FLIT_TO_SEND)) begin             
            flit_cnt <= noc_out_rdy ? flit_cnt + 2'b1 : flit_cnt;
            interrupt_in_prog <= ~( noc_out_val & noc_out_rdy & (flit_cnt == 2'b1) );
            buffer_flit2_send <= buffer_flit2_send;
        end
        else begin
            flit_cnt <= 2'd0;
            interrupt_in_prog <= 1'b0;
            buffer_flit2_send <= buffer_flit2_send;
        end
    end 
end

always @(posedge fpga_clk) begin
    if (~rst_n) begin
        prev_interrupt <= 1'b0;
        buf_prev_int <= 1'b0;
    end
    else begin
        prev_interrupt <= sync_int;
        buf_prev_int <= prev_interrupt;
    end
end


assign noc_out_val = interrupt_in_prog & (flit_cnt < FLIT_TO_SEND);
assign pose_edge = (~prev_interrupt) & sync_int;
assign fall_edge = prev_interrupt & (~sync_int);

// flit1: header
//     63:50 CHIPID
//     49:42 XPOS
//     41:34 YPOS
//     33:30 FBITS
//     29:22 PAYLOAD LENGTH
//     21:14 MESSAGE TYPE
//     13:6  MSHR/TAG
//     5:0   OPTIONS1
// flit2: 
//     63    1
//     62:34 0
//     33:26 ypos
//     25:18 xpos
//     17:16 type
//     15:9  0
//     8     threadid
//     7     0:level, 1:edge
//     6     0:rising, 1:falling
//     5     0
//     4:0   source id
// send packet
always @(*) begin
    pkt_flit1 = 64'b0;
    pkt_flit2 = 64'b0;

    pkt_flit1[63:50] = chip_id;
    pkt_flit1[49:42] = x_pos;
    pkt_flit1[41:34] = y_pos;
    pkt_flit1[33:30] = 4'b0; // processor
    pkt_flit1[29:22] = 8'b1;
    pkt_flit1[21:14] = 8'd33; // interrupt

    pkt_flit2[63]    = 1'b1;
    pkt_flit2[33:26] = y_pos;
    pkt_flit2[25:18] = x_pos;
    pkt_flit2[17:16] = 2'b0;  // hw int
    pkt_flit2[7]     = irq_le;
    pkt_flit2[6]     = 1'b0;  // default: rising edge
    pkt_flit2[4:0]   = device_id; // interrupt source device ID

    pkt_flit2_fall    = pkt_flit2;
    pkt_flit2_fall[6] = 1'b1; // falling edge packet

    if (interrupt_in_prog) begin
        if(flit_cnt == 2'b0) begin
            noc_out_data = pkt_flit1;
        end else if (flit_cnt == 2'b1) begin
            noc_out_data = buffer_flit2_send;
        end else begin
            noc_out_data =  {`NOC_DATA_WIDTH{1'b0}};
        end
    end
    else begin
        noc_out_data =  {`NOC_DATA_WIDTH{1'b0}};
    end
end

endmodule
