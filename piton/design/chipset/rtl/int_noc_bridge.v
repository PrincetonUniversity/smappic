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


`include "define.tmp.h"

module int_noc_bridge(
    input                               chip_clk,
    input                               fpga_clk,
    input                               rst_n,

    input [2:0]                         interrupt,
    input [2:0]                         irq_le,
    input [14:0]                        device_id,

    input                               ciop_iob_out_val,
    input [`NOC_DATA_WIDTH-1:0]         ciop_iob_out_data,
    output                              ciop_iob_out_rdy,

    output                              merger_iob_gen_noc_val,
    output [`NOC_DATA_WIDTH-1:0]        merger_iob_gen_noc_data,
    input                               merger_iob_gen_noc_rdy

);

wire                         gen_noc1_val;
wire [`NOC_DATA_WIDTH-1:0]   gen_noc1_data;
wire                         gen_noc1_rdy;

wire                         gen_noc2_val;
wire [`NOC_DATA_WIDTH-1:0]   gen_noc2_data;
wire                         gen_noc2_rdy;

wire                         gen_noc3_val;
wire [`NOC_DATA_WIDTH-1:0]   gen_noc3_data;
wire                         gen_noc3_rdy;

// Source1
dev_int_pkt_gen int_pkt_gen_src1(
    .fpga_clk                (fpga_clk),
    .rst_n                   (rst_n),
    .noc_out_val             (gen_noc1_val),
    .noc_out_data            (gen_noc1_data),
    .noc_out_rdy             (gen_noc1_rdy),
    .interrupt               (interrupt[0]),

    .chip_id                 (14'b0),
    .x_pos                   (8'd0),
    .y_pos                   (8'd0),
    .irq_le                  (irq_le[0]),   // 0:level, 1: edge
    .device_id               (device_id[4:0]) // Up to 31 devices
);

dev_int_pkt_gen int_pkt_gen_src2(
    .fpga_clk                (fpga_clk),
    .rst_n                   (rst_n),
    .noc_out_val             (gen_noc2_val),
    .noc_out_data            (gen_noc2_data),
    .noc_out_rdy             (gen_noc2_rdy),
    .interrupt               (interrupt[1]),

    .chip_id                 (14'b0),
    .x_pos                   (8'd0),
    .y_pos                   (8'd0),
    .irq_le                  (irq_le[1]),   // 0:level, 1: edge
    .device_id               (device_id[9:5]) // Up to 31 devices
);

dev_int_pkt_gen int_pkt_gen_src3(
    .fpga_clk                (fpga_clk),
    .rst_n                   (rst_n),
    .noc_out_val             (gen_noc3_val),
    .noc_out_data            (gen_noc3_data),
    .noc_out_rdy             (gen_noc3_rdy),
    .interrupt               (interrupt[2]),

    .chip_id                 (14'b0),
    .x_pos                   (8'd0),
    .y_pos                   (8'd0),
    .irq_le                  (irq_le[2]),   // 0:level, 1: edge
    .device_id               (device_id[14:10]) // Up to 31 devices
);

noc_prio_merger int_noc_merger(   
    .clk                          (fpga_clk),
    .rst_n                        (rst_n),
    
    .num_sources                  (3'd4),
                                                      
    .src0_merger_vr_noc_val       (ciop_iob_out_val), 
    .src0_merger_vr_noc_dat       (ciop_iob_out_data),
    .src0_merger_vr_noc_rdy       (ciop_iob_out_rdy),
                                                      
    .src1_merger_vr_noc_val       (gen_noc1_val),
    .src1_merger_vr_noc_dat       (gen_noc1_data),
    .src1_merger_vr_noc_rdy       (gen_noc1_rdy),

    .src2_merger_vr_noc_val       (gen_noc2_val),
    .src2_merger_vr_noc_dat       (gen_noc2_data),
    .src2_merger_vr_noc_rdy       (gen_noc2_rdy),

    .src3_merger_vr_noc_val       (gen_noc3_val),
    .src3_merger_vr_noc_dat       (gen_noc3_data),
    .src3_merger_vr_noc_rdy       (gen_noc3_rdy),
                                
    .src4_merger_vr_noc_val       (0),
    .src4_merger_vr_noc_dat       (0),
    .src4_merger_vr_noc_rdy       (),
                                                      
    .merger_dst_vr_noc_val         (merger_iob_gen_noc_val),  
    .merger_dst_vr_noc_dat         (merger_iob_gen_noc_data) ,
    .merger_dst_vr_noc_rdy         (merger_iob_gen_noc_rdy)   
);
    


endmodule
