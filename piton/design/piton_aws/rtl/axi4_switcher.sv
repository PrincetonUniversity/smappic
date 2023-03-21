`include "axi_defines.vh"

module axi4_switcher #(
  parameter PITON_N = 4,
  parameter PITON_N_LOG = 2
) (
    input                                axis_clk,
    input                                axis_resetn,
    input  [`AXI4_ID_WIDTH     -1:0]     axis_awid,
    input  [`AXI4_ADDR_WIDTH   -1:0]     axis_awaddr,
    input  [`AXI4_LEN_WIDTH    -1:0]     axis_awlen,
    input  [`AXI4_SIZE_WIDTH   -1:0]     axis_awsize,
    input  [`AXI4_BURST_WIDTH  -1:0]     axis_awburst,
    input                                axis_awlock,
    input  [`AXI4_CACHE_WIDTH  -1:0]     axis_awcache,
    input  [`AXI4_PROT_WIDTH   -1:0]     axis_awprot,
    input  [`AXI4_QOS_WIDTH    -1:0]     axis_awqos,
    input  [`AXI4_REGION_WIDTH -1:0]     axis_awregion,
    input  [`AXI4_USER_WIDTH   -1:0]     axis_awuser,
    input                                axis_awvalid,
    output                               axis_awready,
    input   [`AXI4_ID_WIDTH     -1:0]    axis_wid,
    input   [`AXI4_DATA_WIDTH   -1:0]    axis_wdata,
    input   [`AXI4_STRB_WIDTH   -1:0]    axis_wstrb,
    input                                axis_wlast,
    input   [`AXI4_USER_WIDTH   -1:0]    axis_wuser,
    input                                axis_wvalid,
    output                               axis_wready,
    input   [`AXI4_ID_WIDTH     -1:0]    axis_arid,
    input   [`AXI4_ADDR_WIDTH   -1:0]    axis_araddr,
    input   [`AXI4_LEN_WIDTH    -1:0]    axis_arlen,
    input   [`AXI4_SIZE_WIDTH   -1:0]    axis_arsize,
    input   [`AXI4_BURST_WIDTH  -1:0]    axis_arburst,
    input                                axis_arlock,
    input   [`AXI4_CACHE_WIDTH  -1:0]    axis_arcache,
    input   [`AXI4_PROT_WIDTH   -1:0]    axis_arprot,
    input   [`AXI4_QOS_WIDTH    -1:0]    axis_arqos,
    input   [`AXI4_REGION_WIDTH -1:0]    axis_arregion,
    input   [`AXI4_USER_WIDTH   -1:0]    axis_aruser,
    input                                axis_arvalid,
    output                               axis_arready,
    output  [`AXI4_ID_WIDTH     -1:0]    axis_rid,
    output  [`AXI4_DATA_WIDTH   -1:0]    axis_rdata,
    output  [`AXI4_RESP_WIDTH   -1:0]    axis_rresp,
    output                               axis_rlast,
    output  [`AXI4_USER_WIDTH   -1:0]    axis_ruser,
    output                               axis_rvalid,
    input                                axis_rready,
    output  [`AXI4_ID_WIDTH     -1:0]    axis_bid,
    output  [`AXI4_RESP_WIDTH   -1:0]    axis_bresp,
    output  [`AXI4_USER_WIDTH   -1:0]    axis_buser,
    output                               axis_bvalid,
    input                                axis_bready,

    output                               axim_clk[PITON_N-1:0],
    output                               axim_resetn[PITON_N-1:0],
    output  [`AXI4_ID_WIDTH     -1:0]    axim_awid[PITON_N-1:0],
    output  [`AXI4_ADDR_WIDTH   -1:0]    axim_awaddr[PITON_N-1:0],
    output  [`AXI4_LEN_WIDTH    -1:0]    axim_awlen[PITON_N-1:0],
    output  [`AXI4_SIZE_WIDTH   -1:0]    axim_awsize[PITON_N-1:0],
    output  [`AXI4_BURST_WIDTH  -1:0]    axim_awburst[PITON_N-1:0],
    output                               axim_awlock[PITON_N-1:0],
    output  [`AXI4_CACHE_WIDTH  -1:0]    axim_awcache[PITON_N-1:0],
    output  [`AXI4_PROT_WIDTH   -1:0]    axim_awprot[PITON_N-1:0],
    output  [`AXI4_QOS_WIDTH    -1:0]    axim_awqos[PITON_N-1:0],
    output  [`AXI4_REGION_WIDTH -1:0]    axim_awregion[PITON_N-1:0],
    output  [`AXI4_USER_WIDTH   -1:0]    axim_awuser[PITON_N-1:0],
    output                               axim_awvalid[PITON_N-1:0],
    input                                axim_awready[PITON_N-1:0],
    output  [`AXI4_ID_WIDTH     -1:0]    axim_wid[PITON_N-1:0],
    output  [`AXI4_DATA_WIDTH   -1:0]    axim_wdata[PITON_N-1:0],
    output  [`AXI4_STRB_WIDTH   -1:0]    axim_wstrb[PITON_N-1:0],
    output                               axim_wlast[PITON_N-1:0],
    output  [`AXI4_USER_WIDTH   -1:0]    axim_wuser[PITON_N-1:0],
    output                               axim_wvalid[PITON_N-1:0],
    input                                axim_wready[PITON_N-1:0],
    output  [`AXI4_ID_WIDTH     -1:0]    axim_arid[PITON_N-1:0],
    output  [`AXI4_ADDR_WIDTH   -1:0]    axim_araddr[PITON_N-1:0],
    output  [`AXI4_LEN_WIDTH    -1:0]    axim_arlen[PITON_N-1:0],
    output  [`AXI4_SIZE_WIDTH   -1:0]    axim_arsize[PITON_N-1:0],
    output  [`AXI4_BURST_WIDTH  -1:0]    axim_arburst[PITON_N-1:0],
    output                               axim_arlock[PITON_N-1:0],
    output  [`AXI4_CACHE_WIDTH  -1:0]    axim_arcache[PITON_N-1:0],
    output  [`AXI4_PROT_WIDTH   -1:0]    axim_arprot[PITON_N-1:0],
    output  [`AXI4_QOS_WIDTH    -1:0]    axim_arqos[PITON_N-1:0],
    output  [`AXI4_REGION_WIDTH -1:0]    axim_arregion[PITON_N-1:0],
    output  [`AXI4_USER_WIDTH   -1:0]    axim_aruser[PITON_N-1:0],
    output                               axim_arvalid[PITON_N-1:0],
    input                                axim_arready[PITON_N-1:0],
    input   [`AXI4_ID_WIDTH     -1:0]    axim_rid[PITON_N-1:0],
    input   [`AXI4_DATA_WIDTH   -1:0]    axim_rdata[PITON_N-1:0],
    input   [`AXI4_RESP_WIDTH   -1:0]    axim_rresp[PITON_N-1:0],
    input                                axim_rlast[PITON_N-1:0],
    input   [`AXI4_USER_WIDTH   -1:0]    axim_ruser[PITON_N-1:0],
    input                                axim_rvalid[PITON_N-1:0],
    output                               axim_rready[PITON_N-1:0],
    input   [`AXI4_ID_WIDTH     -1:0]    axim_bid[PITON_N-1:0],
    input   [`AXI4_RESP_WIDTH   -1:0]    axim_bresp[PITON_N-1:0],
    input   [`AXI4_USER_WIDTH   -1:0]    axim_buser[PITON_N-1:0],
    input                                axim_bvalid[PITON_N-1:0],
    output                               axim_bready[PITON_N-1:0],

    input [PITON_N_LOG-1:0] sw
);

    wire [`AXI4_ID_WIDTH     -1:0]     axis_q_awid;
    wire [`AXI4_ADDR_WIDTH   -1:0]     axis_q_awaddr;
    wire [`AXI4_LEN_WIDTH    -1:0]     axis_q_awlen;
    wire [`AXI4_SIZE_WIDTH   -1:0]     axis_q_awsize;
    wire [`AXI4_BURST_WIDTH  -1:0]     axis_q_awburst;
    wire                               axis_q_awlock;
    wire [`AXI4_CACHE_WIDTH  -1:0]     axis_q_awcache;
    wire [`AXI4_PROT_WIDTH   -1:0]     axis_q_awprot;
    wire [`AXI4_QOS_WIDTH    -1:0]     axis_q_awqos;
    wire [`AXI4_REGION_WIDTH -1:0]     axis_q_awregion;
    wire [`AXI4_USER_WIDTH   -1:0]     axis_q_awuser;
    wire                               axis_q_awvalid;
    wire                               axis_q_awready;
    wire  [`AXI4_ID_WIDTH     -1:0]    axis_q_wid;
    wire  [`AXI4_DATA_WIDTH   -1:0]    axis_q_wdata;
    wire  [`AXI4_STRB_WIDTH   -1:0]    axis_q_wstrb;
    wire                               axis_q_wlast;
    wire  [`AXI4_USER_WIDTH   -1:0]    axis_q_wuser;
    wire                               axis_q_wvalid;
    wire                               axis_q_wready;
    wire  [`AXI4_ID_WIDTH     -1:0]    axis_q_arid;
    wire  [`AXI4_ADDR_WIDTH   -1:0]    axis_q_araddr;
    wire  [`AXI4_LEN_WIDTH    -1:0]    axis_q_arlen;
    wire  [`AXI4_SIZE_WIDTH   -1:0]    axis_q_arsize;
    wire  [`AXI4_BURST_WIDTH  -1:0]    axis_q_arburst;
    wire                               axis_q_arlock;
    wire  [`AXI4_CACHE_WIDTH  -1:0]    axis_q_arcache;
    wire  [`AXI4_PROT_WIDTH   -1:0]    axis_q_arprot;
    wire  [`AXI4_QOS_WIDTH    -1:0]    axis_q_arqos;
    wire  [`AXI4_REGION_WIDTH -1:0]    axis_q_arregion;
    wire  [`AXI4_USER_WIDTH   -1:0]    axis_q_aruser;
    wire                               axis_q_arvalid;
    wire                               axis_q_arready;
    wire  [`AXI4_ID_WIDTH     -1:0]    axis_q_rid;
    wire  [`AXI4_DATA_WIDTH   -1:0]    axis_q_rdata;
    wire  [`AXI4_RESP_WIDTH   -1:0]    axis_q_rresp;
    wire                               axis_q_rlast;
    wire  [`AXI4_USER_WIDTH   -1:0]    axis_q_ruser;
    wire                               axis_q_rvalid;
    wire                               axis_q_rready;
    wire  [`AXI4_ID_WIDTH     -1:0]    axis_q_bid;
    wire  [`AXI4_RESP_WIDTH   -1:0]    axis_q_bresp;
    wire  [`AXI4_USER_WIDTH   -1:0]    axis_q_buser;
    wire                               axis_q_bvalid;
    wire                               axis_q_bready;

    wire  [`AXI4_ID_WIDTH     -1:0]    axim_q_awid[PITON_N-1:0];
    wire  [`AXI4_ADDR_WIDTH   -1:0]    axim_q_awaddr[PITON_N-1:0];
    wire  [`AXI4_LEN_WIDTH    -1:0]    axim_q_awlen[PITON_N-1:0];
    wire  [`AXI4_SIZE_WIDTH   -1:0]    axim_q_awsize[PITON_N-1:0];
    wire  [`AXI4_BURST_WIDTH  -1:0]    axim_q_awburst[PITON_N-1:0];
    wire                               axim_q_awlock[PITON_N-1:0];
    wire  [`AXI4_CACHE_WIDTH  -1:0]    axim_q_awcache[PITON_N-1:0];
    wire  [`AXI4_PROT_WIDTH   -1:0]    axim_q_awprot[PITON_N-1:0];
    wire  [`AXI4_QOS_WIDTH    -1:0]    axim_q_awqos[PITON_N-1:0];
    wire  [`AXI4_REGION_WIDTH -1:0]    axim_q_awregion[PITON_N-1:0];
    wire  [`AXI4_USER_WIDTH   -1:0]    axim_q_awuser[PITON_N-1:0];
    wire                               axim_q_awvalid[PITON_N-1:0];
    wire                               axim_q_awready[PITON_N-1:0];
    wire  [`AXI4_ID_WIDTH     -1:0]    axim_q_wid[PITON_N-1:0];
    wire  [`AXI4_DATA_WIDTH   -1:0]    axim_q_wdata[PITON_N-1:0];
    wire  [`AXI4_STRB_WIDTH   -1:0]    axim_q_wstrb[PITON_N-1:0];
    wire                               axim_q_wlast[PITON_N-1:0];
    wire  [`AXI4_USER_WIDTH   -1:0]    axim_q_wuser[PITON_N-1:0];
    wire                               axim_q_wvalid[PITON_N-1:0];
    wire                               axim_q_wready[PITON_N-1:0];
    wire  [`AXI4_ID_WIDTH     -1:0]    axim_q_arid[PITON_N-1:0];
    wire  [`AXI4_ADDR_WIDTH   -1:0]    axim_q_araddr[PITON_N-1:0];
    wire  [`AXI4_LEN_WIDTH    -1:0]    axim_q_arlen[PITON_N-1:0];
    wire  [`AXI4_SIZE_WIDTH   -1:0]    axim_q_arsize[PITON_N-1:0];
    wire  [`AXI4_BURST_WIDTH  -1:0]    axim_q_arburst[PITON_N-1:0];
    wire                               axim_q_arlock[PITON_N-1:0];
    wire  [`AXI4_CACHE_WIDTH  -1:0]    axim_q_arcache[PITON_N-1:0];
    wire  [`AXI4_PROT_WIDTH   -1:0]    axim_q_arprot[PITON_N-1:0];
    wire  [`AXI4_QOS_WIDTH    -1:0]    axim_q_arqos[PITON_N-1:0];
    wire  [`AXI4_REGION_WIDTH -1:0]    axim_q_arregion[PITON_N-1:0];
    wire  [`AXI4_USER_WIDTH   -1:0]    axim_q_aruser[PITON_N-1:0];
    wire                               axim_q_arvalid[PITON_N-1:0];
    wire                               axim_q_arready[PITON_N-1:0];
    wire  [`AXI4_ID_WIDTH     -1:0]    axim_q_rid[PITON_N-1:0];
    wire  [`AXI4_DATA_WIDTH   -1:0]    axim_q_rdata[PITON_N-1:0];
    wire  [`AXI4_RESP_WIDTH   -1:0]    axim_q_rresp[PITON_N-1:0];
    wire                               axim_q_rlast[PITON_N-1:0];
    wire  [`AXI4_USER_WIDTH   -1:0]    axim_q_ruser[PITON_N-1:0];
    wire                               axim_q_rvalid[PITON_N-1:0];
    wire                               axim_q_rready[PITON_N-1:0];
    wire  [`AXI4_ID_WIDTH     -1:0]    axim_q_bid[PITON_N-1:0];
    wire  [`AXI4_RESP_WIDTH   -1:0]    axim_q_bresp[PITON_N-1:0];
    wire  [`AXI4_USER_WIDTH   -1:0]    axim_q_buser[PITON_N-1:0];
    wire                               axim_q_bvalid[PITON_N-1:0];
    wire                               axim_q_bready[PITON_N-1:0];


    genvar i;
    generate
    for (i = 0; i < PITON_N; i = i + 1)
    begin
        assign axim_clk[i] = axis_clk;
        assign axim_resetn[i] = axis_resetn;
        assign axim_q_awid[i] = axis_q_awid;
        assign axim_q_awaddr[i] = axis_q_awaddr;
        assign axim_q_awlen[i] = axis_q_awlen;
        assign axim_q_awsize[i] = axis_q_awsize;
        assign axim_q_awburst[i] = axis_q_awburst;
        assign axim_q_awlock[i] = axis_q_awlock;
        assign axim_q_awcache[i] = axis_q_awcache;
        assign axim_q_awprot[i] = axis_q_awprot;
        assign axim_q_awqos[i] = axis_q_awqos;
        assign axim_q_awregion[i] = axis_q_awregion;
        assign axim_q_awuser[i] = axis_q_awuser;
        assign axim_q_wid[i] = axis_q_wid;
        assign axim_q_wdata[i] = axis_q_wdata;
        assign axim_q_wstrb[i] = axis_q_wstrb;
        assign axim_q_wlast[i] = axis_q_wlast;
        assign axim_q_wuser[i] = axis_q_wuser;
        assign axim_q_arid[i] = axis_q_arid;
        assign axim_q_araddr[i] = axis_q_araddr;
        assign axim_q_arlen[i] = axis_q_arlen;
        assign axim_q_arsize[i] = axis_q_arsize;
        assign axim_q_arburst[i] = axis_q_arburst;
        assign axim_q_arlock[i] = axis_q_arlock;
        assign axim_q_arcache[i] = axis_q_arcache;
        assign axim_q_arprot[i] = axis_q_arprot;
        assign axim_q_arqos[i] = axis_q_arqos;
        assign axim_q_arregion[i] = axis_q_arregion;
        assign axim_q_aruser[i] = axis_q_aruser;

        assign axim_q_awvalid[i] = (i == sw) ? axis_q_awvalid : 1'b0;
        assign axim_q_arvalid[i] = (i == sw) ? axis_q_arvalid : 1'b0;
        assign axim_q_rready[i] = (i == sw) ? axis_q_rready : 1'b0;
        assign axim_q_bready[i] = (i == sw) ? axis_q_bready : 1'b0;
        assign axim_q_wvalid[i] = (i == sw) ? axis_q_wvalid : 1'b0;
    end
    endgenerate

    assign axis_q_awready = axim_q_awready[sw];
    assign axis_q_wready = axim_q_wready[sw];
    assign axis_q_arready = axim_q_arready[sw];
    assign axis_q_rid = axim_q_rid[sw];
    assign axis_q_rdata = axim_q_rdata[sw];
    assign axis_q_rresp = axim_q_rresp[sw];
    assign axis_q_rlast = axim_q_rlast[sw];
    assign axis_q_ruser = axim_q_ruser[sw];
    assign axis_q_rvalid = axim_q_rvalid[sw];
    assign axis_q_bid = axim_q_bid[sw];
    assign axis_q_bresp = axim_q_bresp[sw];
    assign axis_q_buser = axim_q_buser[sw];
    assign axis_q_bvalid = axim_q_bvalid[sw];


// flop interfaces for timing

    axi_register_slice input_regs (
        .aclk          (axis_clk),
        .aresetn       (axis_resetn),

        .s_axi_awid    (axis_awid),
        .s_axi_awaddr  (axis_awaddr),
        .s_axi_awlen   (axis_awlen),
        .s_axi_awvalid (axis_awvalid),
        .s_axi_awsize  (axis_awsize),
        .s_axi_awready (axis_awready),
        .s_axi_wdata   (axis_wdata),
        .s_axi_wstrb   (axis_wstrb),
        .s_axi_wlast   (axis_wlast),
        .s_axi_wvalid  (axis_wvalid),
        .s_axi_wready  (axis_wready),
        .s_axi_bid     (axis_bid),
        .s_axi_bresp   (axis_bresp),
        .s_axi_bvalid  (axis_bvalid),
        .s_axi_bready  (axis_bready),
        .s_axi_arid    (axis_arid),
        .s_axi_araddr  (axis_araddr),
        .s_axi_arlen   (axis_arlen),
        .s_axi_arvalid (axis_arvalid),
        .s_axi_arsize  (axis_arsize),
        .s_axi_arready (axis_arready),
        .s_axi_rid     (axis_rid),
        .s_axi_rdata   (axis_rdata),
        .s_axi_rresp   (axis_rresp),
        .s_axi_rlast   (axis_rlast),
        .s_axi_rvalid  (axis_rvalid),
        .s_axi_rready  (axis_rready),

        .m_axi_awid    (axis_q_awid),
        .m_axi_awaddr  (axis_q_awaddr),
        .m_axi_awlen   (axis_q_awlen),
        .m_axi_awvalid (axis_q_awvalid),
        .m_axi_awsize  (axis_q_awsize),
        .m_axi_awready (axis_q_awready),
        .m_axi_wdata   (axis_q_wdata),
        .m_axi_wstrb   (axis_q_wstrb),
        .m_axi_wvalid  (axis_q_wvalid),
        .m_axi_wlast   (axis_q_wlast),
        .m_axi_wready  (axis_q_wready),
        .m_axi_bresp   (axis_q_bresp),
        .m_axi_bvalid  (axis_q_bvalid),
        .m_axi_bid     (axis_q_bid),
        .m_axi_bready  (axis_q_bready),
        .m_axi_arid    (axis_q_arid),
        .m_axi_araddr  (axis_q_araddr),
        .m_axi_arlen   (axis_q_arlen),
        .m_axi_arsize  (axis_q_arsize),
        .m_axi_arvalid (axis_q_arvalid),
        .m_axi_arready (axis_q_arready),
        .m_axi_rid     (axis_q_rid),
        .m_axi_rdata   (axis_q_rdata),
        .m_axi_rresp   (axis_q_rresp),
        .m_axi_rlast   (axis_q_rlast),
        .m_axi_rvalid  (axis_q_rvalid),
        .m_axi_rready  (axis_q_rready)
    );

    generate
    for (i = 0; i < PITON_N; i = i + 1)
    begin
        axi_register_slice output_regs (
            .aclk          (axim_clk[i]),
            .aresetn       (axim_resetn[i]),

            .s_axi_awid    (axim_q_awid[i]),
            .s_axi_awaddr  (axim_q_awaddr[i]),
            .s_axi_awlen   (axim_q_awlen[i]),
            .s_axi_awvalid (axim_q_awvalid[i]),
            .s_axi_awsize  (axim_q_awsize[i]),
            .s_axi_awready (axim_q_awready[i]),
            .s_axi_wdata   (axim_q_wdata[i]),
            .s_axi_wstrb   (axim_q_wstrb[i]),
            .s_axi_wlast   (axim_q_wlast[i]),
            .s_axi_wvalid  (axim_q_wvalid[i]),
            .s_axi_wready  (axim_q_wready[i]),
            .s_axi_bid     (axim_q_bid[i]),
            .s_axi_bresp   (axim_q_bresp[i]),
            .s_axi_bvalid  (axim_q_bvalid[i]),
            .s_axi_bready  (axim_q_bready[i]),
            .s_axi_arid    (axim_q_arid[i]),
            .s_axi_araddr  (axim_q_araddr[i]),
            .s_axi_arlen   (axim_q_arlen[i]),
            .s_axi_arvalid (axim_q_arvalid[i]),
            .s_axi_arsize  (axim_q_arsize[i]),
            .s_axi_arready (axim_q_arready[i]),
            .s_axi_rid     (axim_q_rid[i]),
            .s_axi_rdata   (axim_q_rdata[i]),
            .s_axi_rresp   (axim_q_rresp[i]),
            .s_axi_rlast   (axim_q_rlast[i]),
            .s_axi_rvalid  (axim_q_rvalid[i]),
            .s_axi_rready  (axim_q_rready[i]),

            .m_axi_awid    (axim_awid[i]),
            .m_axi_awaddr  (axim_awaddr[i]),
            .m_axi_awlen   (axim_awlen[i]),
            .m_axi_awvalid (axim_awvalid[i]),
            .m_axi_awsize  (axim_awsize[i]),
            .m_axi_awready (axim_awready[i]),
            .m_axi_wdata   (axim_wdata[i]),
            .m_axi_wstrb   (axim_wstrb[i]),
            .m_axi_wvalid  (axim_wvalid[i]),
            .m_axi_wlast   (axim_wlast[i]),
            .m_axi_wready  (axim_wready[i]),
            .m_axi_bresp   (axim_bresp[i]),
            .m_axi_bvalid  (axim_bvalid[i]),
            .m_axi_bid     (axim_bid[i]),
            .m_axi_bready  (axim_bready[i]),
            .m_axi_arid    (axim_arid[i]),
            .m_axi_araddr  (axim_araddr[i]),
            .m_axi_arlen   (axim_arlen[i]),
            .m_axi_arsize  (axim_arsize[i]),
            .m_axi_arvalid (axim_arvalid[i]),
            .m_axi_arready (axim_arready[i]),
            .m_axi_rid     (axim_rid[i]),
            .m_axi_rdata   (axim_rdata[i]),
            .m_axi_rresp   (axim_rresp[i]),
            .m_axi_rlast   (axim_rlast[i]),
            .m_axi_rvalid  (axim_rvalid[i]),
            .m_axi_rready  (axim_rready[i])
        );
    end
    endgenerate

endmodule : axi4_switcher