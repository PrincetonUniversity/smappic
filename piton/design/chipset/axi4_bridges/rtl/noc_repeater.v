// ========== Copyright Header Begin ============================================
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
// ========== Copyright Header End ============================================

module noc_repeater #(
    parameter SRC = 0, 
    parameter DST = 1
) (
    input piton_clk,    // Clock
    input piton_rst_n,  // Asynchronous reset active low
    input axi_clk, 
    input axi_rst_n,
    
    input   wire                                   noc1_in_val,
    input   wire [`NOC_DATA_WIDTH-1:0]             noc1_in_data,
    output  wire                                   noc1_in_rdy,

    input   wire                                   noc2_in_val,
    input   wire [`NOC_DATA_WIDTH-1:0]             noc2_in_data,
    output  wire                                   noc2_in_rdy,

    input   wire                                   noc3_in_val,
    input   wire [`NOC_DATA_WIDTH-1:0]             noc3_in_data,
    output  wire                                   noc3_in_rdy,

    output  wire                                   noc1_out_val,
    output  wire [`NOC_DATA_WIDTH-1:0]             noc1_out_data,
    input   wire                                   noc1_out_rdy,

    output  wire                                   noc2_out_val,
    output  wire [`NOC_DATA_WIDTH-1:0]             noc2_out_data,
    input   wire                                   noc2_out_rdy,

    output  wire                                   noc3_out_val,
    output  wire [`NOC_DATA_WIDTH-1:0]             noc3_out_data,
    input   wire                                   noc3_out_rdy
);


`ifndef REPEATER_BYPASS

wire [`AXI4_ID_WIDTH     -1:0]     axi_awid;
wire [`AXI4_ADDR_WIDTH   -1:0]     axi_awaddr;
wire [`AXI4_LEN_WIDTH    -1:0]     axi_awlen;
wire [`AXI4_SIZE_WIDTH   -1:0]     axi_awsize;
wire [`AXI4_USER_WIDTH   -1:0]     axi_awuser;
wire                               axi_awvalid;
wire                               axi_awready;
wire  [`AXI4_DATA_WIDTH   -1:0]    axi_wdata;
wire  [`AXI4_STRB_WIDTH   -1:0]    axi_wstrb;
wire                               axi_wlast;
wire                               axi_wvalid;
wire                               axi_wready;
wire  [`AXI4_ID_WIDTH     -1:0]    axi_arid;
wire  [`AXI4_ADDR_WIDTH   -1:0]    axi_araddr;
wire  [`AXI4_LEN_WIDTH    -1:0]    axi_arlen;
wire  [`AXI4_SIZE_WIDTH   -1:0]    axi_arsize;
wire  [`AXI4_USER_WIDTH   -1:0]    axi_aruser;
wire                               axi_arvalid;
wire                               axi_arready;
wire  [`AXI4_ID_WIDTH     -1:0]    axi_rid;
wire  [`AXI4_DATA_WIDTH   -1:0]    axi_rdata;
wire  [`AXI4_RESP_WIDTH   -1:0]    axi_rresp;
wire                               axi_rlast;
wire                               axi_rvalid;
wire                               axi_rready;
wire  [`AXI4_ID_WIDTH     -1:0]    axi_bid;
wire  [`AXI4_RESP_WIDTH   -1:0]    axi_bresp;
wire                               axi_bvalid;
wire                               axi_bready;


noc2axi noc2axi(
    .piton_clk           (piton_clk),
    .piton_rst_n         (piton_rst_n),
    .axi_clk           (axi_clk),
    .axi_rst_n         (axi_rst_n),

    .noc1_val       (noc1_in_val), 
    .noc1_data      (noc1_in_data), 
    .noc1_rdy       (noc1_in_rdy), 
    .noc2_val       (noc2_in_val), 
    .noc2_data      (noc2_in_data), 
    .noc2_rdy       (noc2_in_rdy), 
    .noc3_val       (noc3_in_val), 
    .noc3_data      (noc3_in_data), 
    .noc3_rdy       (noc3_in_rdy), 

    .m_axi_awid    (axi_awid), 
    .m_axi_awaddr  (axi_awaddr), 
    .m_axi_awlen   (axi_awlen), 
    .m_axi_awsize  (axi_awsize), 
    .m_axi_awuser  (axi_awuser), 
    .m_axi_awvalid (axi_awvalid), 
    .m_axi_awready (axi_awready), 
    .m_axi_wdata   (axi_wdata), 
    .m_axi_wstrb   (axi_wstrb), 
    .m_axi_wlast   (axi_wlast), 
    .m_axi_wvalid  (axi_wvalid), 
    .m_axi_wready  (axi_wready), 
    .m_axi_arid    (axi_arid), 
    .m_axi_araddr  (axi_araddr),
    .m_axi_arlen   (axi_arlen), 
    .m_axi_arsize  (axi_arsize),
    .m_axi_aruser  (axi_aruser), 
    .m_axi_arvalid (axi_arvalid), 
    .m_axi_arready (axi_arready), 
    .m_axi_rid     (axi_rid), 
    .m_axi_rdata   (axi_rdata), 
    .m_axi_rresp   (axi_rresp), 
    .m_axi_rlast   (axi_rlast), 
    .m_axi_rvalid  (axi_rvalid), 
    .m_axi_rready  (axi_rready), 
    .m_axi_bid     (axi_bid), 
    .m_axi_bresp   (axi_bresp), 
    .m_axi_bvalid  (axi_bvalid), 
    .m_axi_bready  (axi_bready), 

    .chipid       (SRC), 
    .chip0_base   (`AXI4_ADDR_WIDTH'h00000), 
    .chip1_base   (`AXI4_ADDR_WIDTH'h10000), 
    .host_base    (`AXI4_ADDR_WIDTH'h40000)
);

axi2noc axi2noc(
    .piton_clk           (piton_clk),
    .piton_rst_n         (piton_rst_n),
    .axi_clk           (axi_clk),
    .axi_rst_n         (axi_rst_n),

    .noc1_data      (noc1_out_data), 
    .noc1_rdy       (noc1_out_rdy), 
    .noc1_val       (noc1_out_val), 
    .noc2_data      (noc2_out_data), 
    .noc2_rdy       (noc2_out_rdy), 
    .noc2_val       (noc2_out_val), 
    .noc3_data      (noc3_out_data), 
    .noc3_rdy       (noc3_out_rdy), 
    .noc3_val       (noc3_out_val), 

    .s_axi_awid    (axi_awid), 
    .s_axi_awaddr  (axi_awaddr), 
    .s_axi_awlen   (axi_awlen), 
    .s_axi_awsize  (axi_awsize), 
    .s_axi_awvalid (axi_awvalid), 
    .s_axi_awready (axi_awready), 
    .s_axi_wdata   (axi_wdata), 
    .s_axi_wstrb   (axi_wstrb), 
    .s_axi_wlast   (axi_wlast), 
    .s_axi_wvalid  (axi_wvalid), 
    .s_axi_wready  (axi_wready), 
    .s_axi_arid    (axi_arid), 
    .s_axi_araddr  (axi_araddr), 
    .s_axi_arlen   (axi_arlen), 
    .s_axi_arsize  (axi_arsize), 
    .s_axi_arvalid (axi_arvalid), 
    .s_axi_arready (axi_arready), 
    .s_axi_rid     (axi_rid), 
    .s_axi_rdata   (axi_rdata), 
    .s_axi_rresp   (axi_rresp), 
    .s_axi_rlast   (axi_rlast), 
    .s_axi_rvalid  (axi_rvalid), 
    .s_axi_rready  (axi_rready), 
    .s_axi_bid     (axi_bid), 
    .s_axi_bresp   (axi_bresp), 
    .s_axi_bvalid  (axi_bvalid), 
    .s_axi_bready  (axi_bready), 

    .chipid       (DST)

);

repeater_checker checker1(
    .clk(piton_clk), 
    .rst_n(piton_rst_n), 

    .val1 (noc1_in_val), 
    .rdy1 (noc1_in_rdy), 
    .dat1 (noc1_in_data), 

    .val2 (noc1_out_val), 
    .rdy2 (noc1_out_rdy), 
    .dat2 (noc1_out_data)
);

repeater_checker checker2(
    .clk(piton_clk), 
    .rst_n(piton_rst_n), 

    .val1 (noc2_in_val), 
    .rdy1 (noc2_in_rdy), 
    .dat1 (noc2_in_data), 

    .val2 (noc2_out_val), 
    .rdy2 (noc2_out_rdy), 
    .dat2 (noc2_out_data)
);

repeater_checker checker3(
    .clk(piton_clk), 
    .rst_n(piton_rst_n), 

    .val1 (noc3_in_val), 
    .rdy1 (noc3_in_rdy), 
    .dat1 (noc3_in_data), 

    .val2 (noc3_out_val), 
    .rdy2 (noc3_out_rdy), 
    .dat2 (noc3_out_data)
);

`else 

assign noc1_out_val =  noc1_in_val;
assign noc1_out_data = noc1_in_data;
assign noc1_in_rdy =   noc1_out_rdy;

assign noc2_out_val =  noc2_in_val;
assign noc2_out_data = noc2_in_data;
assign noc2_in_rdy =   noc2_out_rdy;

assign noc3_out_val =  noc3_in_val;
assign noc3_out_data = noc3_in_data;
assign noc3_in_rdy =   noc3_out_rdy;

`endif

endmodule