// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module rvic_wrap #(
    parameter int unsigned DataWidth       = 64,
    parameter int unsigned NumSources      = 15,
    parameter int unsigned NumHarts        =  4,
    parameter int unsigned NumPlicHarts    =  4,
    parameter int unsigned PlicMaxPriority =  7,

    parameter logic [63:0] ClintBase       = 64'he100f00000,
    parameter logic [63:0] PlicBase        = 64'he200000000
) (
    input clk,
    input rst_n,

    // AXI Write Address Channel Signals
    input       [63:0]      axi_awaddr,
    input                   axi_awvalid,
    output                  axi_awready,

    // AXI Write Data Channel Signals
    input       [63:0]      axi_wdata,
    input       [7:0]       axi_wstrb,
    input                   axi_wvalid,
    output                  axi_wready,

    // AXI Read Address Channel Signals
    input       [63:0]      axi_araddr,
    input                   axi_arvalid,
    output                  axi_arready,

    // AXI Read Data Channel Signals
    output       [63:0]     axi_rdata,
    output       [1:0]      axi_rresp,
    output                  axi_rvalid,
    input                   axi_rready,

    // AXI Write Response Channel Signals
    output       [1:0]      axi_bresp,
    output                  axi_bvalid,
    input                   axi_bready,

    // this does not belong to axi lite and is non-standard
    input       [2:0]       w_reqbuf_size,
    input       [2:0]       r_reqbuf_size,

    // PLIC
    input  [NumSources-1:0] irq_sources_i,
    input  [NumSources-1:0] irq_le_i,     // 0:level 1:edge
    output [NumHarts*2-1:0] irq_o,        // level sensitive IR lines, mip & sip (async)

    // CLINT AXI
    input       [63:0]      clint_axi_awaddr,
    input                   clint_axi_awvalid,
    output                  clint_axi_awready,

    input       [63:0]      clint_axi_wdata,
    input       [7:0]       clint_axi_wstrb,
    input                   clint_axi_wvalid,
    output                  clint_axi_wready,

    input       [63:0]      clint_axi_araddr,
    input                   clint_axi_arvalid,
    output                  clint_axi_arready,

    output       [63:0]     clint_axi_rdata,
    output       [1:0]      clint_axi_rresp,
    output                  clint_axi_rvalid,
    input                   clint_axi_rready,

    output       [1:0]      clint_axi_bresp,
    output                  clint_axi_bvalid,
    input                   clint_axi_bready,

    input                   testmode_i,   // Not sure: tie this to 1'b0 for using clint

    input                   rtc_i,        // Real-time clock in (usually 32.768 kHz)
    output [NumHarts-1:0]   timer_irq_o,  // Timer interrupts
    output [NumHarts-1:0]   ipi_o         // software interrupt (a.k.a inter-process-interrupt)
);

localparam int unsigned AxiIdWidth    =  1;
localparam int unsigned AxiAddrWidth  = 64;
localparam int unsigned AxiDataWidth  = 64;
localparam int unsigned AxiUserWidth  =  1;

  /////////////////////////////
  // CLINT
  /////////////////////////////

  ariane_axi::req_t    clint_axi_req;
  ariane_axi::resp_t   clint_axi_resp;

  clint #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .NR_CORES       ( NumHarts     )
  ) i_clint (
    .clk_i       ( clk            ),
    .rst_ni      ( rst_n          ),
    .testmode_i,
    .axi_req_i   ( clint_axi_req  ),
    .axi_resp_o  ( clint_axi_resp ),
    .rtc_i                         ,
    .timer_irq_o                   ,
    .ipi_o
  );
  
  // tie axi to req/resp
  // wire signals used by AXI-lite
  assign clint_axi_req.aw.addr     = clint_axi_awaddr;
  assign clint_axi_req.aw_valid    = clint_axi_awvalid;
  assign clint_axi_req.w.data      = clint_axi_wdata;
  assign clint_axi_req.w.strb      = clint_axi_wstrb;
  assign clint_axi_req.w_valid     = clint_axi_wvalid;
  assign clint_axi_req.ar.addr     = clint_axi_araddr;
  assign clint_axi_req.ar_valid    = clint_axi_arvalid;
  assign clint_axi_req.r_ready     = clint_axi_rready;
  assign clint_axi_req.b_ready     = clint_axi_bready;
  // Assign AXI-lite outputs
  assign clint_axi_awready = clint_axi_resp.aw_ready;
  assign clint_axi_wready  = clint_axi_resp.w_ready;
  assign clint_axi_arready = clint_axi_resp.ar_ready;
  assign clint_axi_rdata   = clint_axi_resp.r.data;
  assign clint_axi_rresp   = clint_axi_resp.r.resp;
  assign clint_axi_rvalid  = clint_axi_resp.r_valid;
  assign clint_axi_bvalid  = clint_axi_resp.b_valid;
  assign clint_axi_bresp   = clint_axi_resp.b.resp;

  // tie off signals not used by AXI-lite
  assign clint_axi_req.aw.id     = '0;
  assign clint_axi_req.aw.len    = '0;
  assign clint_axi_req.aw.size   = 3'b11;// 8byte
  assign clint_axi_req.aw.burst  = '0;
  assign clint_axi_req.aw.lock   = '0;
  assign clint_axi_req.aw.cache  = '0;
  assign clint_axi_req.aw.prot   = '0;
  assign clint_axi_req.aw.qos    = '0;
  assign clint_axi_req.aw.region = '0;
  assign clint_axi_req.aw.atop   = '0;
  assign clint_axi_req.w.last    = 1'b1;
  assign clint_axi_req.ar.id     = '0;
  assign clint_axi_req.ar.len    = '0;
  assign clint_axi_req.ar.size   = 3'b11;// 8byte
  assign clint_axi_req.ar.burst  = '0;
  assign clint_axi_req.ar.lock   = '0;
  assign clint_axi_req.ar.cache  = '0;
  assign clint_axi_req.ar.prot   = '0;
  assign clint_axi_req.ar.qos    = '0;
  assign clint_axi_req.ar.region = '0;


  /////////////////////////////
  // PLIC
  /////////////////////////////

AXI_BUS #(
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_USER_WIDTH ( AxiUserWidth )
) plic_axi();

// wire signals used by AXI-lite
assign plic_axi.aw_addr     = axi_awaddr;
assign plic_axi.aw_valid    = axi_awvalid;
assign plic_axi.w_data      =  axi_wdata;
assign plic_axi.w_strb      =  axi_wstrb;
assign plic_axi.w_valid     =  axi_wvalid;
assign plic_axi.ar_addr     = axi_araddr;
assign plic_axi.ar_valid    = axi_arvalid;
assign plic_axi.r_ready     = axi_rready;
assign plic_axi.b_ready     = axi_bready;
assign plic_axi.aw_size     = w_reqbuf_size;
assign plic_axi.ar_size     = r_reqbuf_size;
// tie off signals not used by AXI-lite
assign plic_axi.aw_id     = '0;
assign plic_axi.aw_len    = '0;
assign plic_axi.aw_burst  = '0;
assign plic_axi.aw_lock   = '0;
assign plic_axi.aw_cache  = '0;
assign plic_axi.aw_prot   = '0;
assign plic_axi.aw_qos    = '0;
assign plic_axi.aw_region = '0;
assign plic_axi.aw_atop   = '0;
assign plic_axi.w_last    = 1'b1;
assign plic_axi.ar_id     = '0;
assign plic_axi.ar_len    = '0;
assign plic_axi.ar_burst  = '0;
assign plic_axi.ar_lock   = '0;
assign plic_axi.ar_cache  = '0;
assign plic_axi.ar_prot   = '0;
assign plic_axi.ar_qos    = '0;
assign plic_axi.ar_region = '0;

// Assign AXI-lite outputs
assign axi_awready = plic_axi.aw_ready;
assign axi_wready  = plic_axi.w_ready;
assign axi_arready = plic_axi.ar_ready;
assign axi_rvalid  = plic_axi.r_valid;
assign axi_rresp   = plic_axi.r_resp;
assign axi_bvalid  = plic_axi.b_valid;
assign axi_bresp   = plic_axi.b_resp;







reg_intf::reg_intf_resp_d32 plic_resp;
reg_intf::reg_intf_req_a32_d32 plic_req;

enum logic [2:0] {Idle, WriteSecond, ReadSecond, WriteResp, ReadResp} state_d, state_q;
logic [31:0] rword_d, rword_q;

// register read data
assign rword_d = (plic_req.valid && !plic_req.write) ? plic_resp.rdata : rword_q;
assign axi_rdata = {plic_resp.rdata, rword_q};

always_ff @(posedge clk) begin : p_plic_regs
  if (~rst_n) begin
    state_q <= Idle;
    rword_q <= '0;
  end else begin
    state_q <= state_d;
    rword_q <= rword_d;
  end
end

// this is a simplified AXI statemachine, since the
// W and AW requests always arrive at the same time here
always_comb begin : p_plic_if
  automatic logic [31:0] waddr, raddr;
  // subtract the base offset (truncated to 32 bits)
  waddr = plic_axi.aw_addr[31:0] - 32'(PlicBase) + 32'hc000000;
  raddr = plic_axi.ar_addr[31:0] - 32'(PlicBase) + 32'hc000000;

  // AXI-lite
  plic_axi.aw_ready = plic_resp.ready;
  plic_axi.w_ready  = plic_resp.ready;
  plic_axi.ar_ready = plic_resp.ready;

  plic_axi.r_valid  = 1'b0;
  plic_axi.r_resp   = '0;
  plic_axi.b_valid  = 1'b0;
  plic_axi.b_resp   = '0;

  // PLIC
  plic_req.valid       = 1'b0;
  plic_req.wstrb       = '0;
  plic_req.write       = 1'b0;
  plic_req.wdata       = plic_axi.w_data[31:0];
  plic_req.addr        = waddr;

  // default
  state_d              = state_q;

  unique case (state_q)
    Idle: begin
      if (plic_axi.w_valid && plic_axi.aw_valid && plic_resp.ready) begin
        plic_req.valid = 1'b1;
        plic_req.write = plic_axi.w_strb[3:0];
        plic_req.wstrb = '1;
        // this is a 64bit write, need to write second 32bit chunk in second cycle
        if (plic_axi.aw_size == 3'b11) begin
          state_d = WriteSecond;
        end else begin
          state_d = WriteResp;
        end
      end else if (plic_axi.ar_valid && plic_resp.ready) begin
        plic_req.valid = 1'b1;
        plic_req.addr  = raddr;
        // this is a 64bit read, need to read second 32bit chunk in second cycle
        if (plic_axi.ar_size == 3'b11) begin
          state_d = ReadSecond;
        end else begin
          state_d = ReadResp;
        end
      end
    end
    // write high word
    WriteSecond: begin
      plic_axi.aw_ready = 1'b0;
      plic_axi.w_ready  = 1'b0;
      plic_axi.ar_ready = 1'b0;
      plic_req.addr        = waddr + 32'h4;
      plic_req.wdata       = plic_axi.w_data[63:32];
      if (plic_resp.ready && plic_axi.b_ready) begin
        plic_req.valid       = 1'b1;
        plic_req.write       = 1'b1;
        plic_req.wstrb       = '1;
        plic_axi.b_valid  = 1'b1;
        state_d              = Idle;
      end
    end
    // read high word
    ReadSecond: begin
      plic_axi.aw_ready = 1'b0;
      plic_axi.w_ready  = 1'b0;
      plic_axi.ar_ready = 1'b0;
      plic_req.addr        = raddr + 32'h4;
      if (plic_resp.ready && plic_axi.r_ready) begin
        plic_req.valid      = 1'b1;
        plic_axi.r_valid = 1'b1;
        state_d             = Idle;
      end
    end
    WriteResp: begin
      plic_axi.aw_ready = 1'b0;
      plic_axi.w_ready  = 1'b0;
      plic_axi.ar_ready = 1'b0;
      if (plic_axi.b_ready) begin
        plic_axi.b_valid  = 1'b1;
        state_d              = Idle;
      end
    end
    ReadResp: begin
      plic_axi.aw_ready = 1'b0;
      plic_axi.w_ready  = 1'b0;
      plic_axi.ar_ready = 1'b0;
      if (plic_axi.r_ready) begin
        plic_axi.r_valid = 1'b1;
        state_d             = Idle;
      end
    end
    default: state_d = Idle;
  endcase
end

plic_top #(
  .N_SOURCE    ( NumSources      ),
  .N_TARGET    ( 2 * NumPlicHarts),
  .MAX_PRIO    ( PlicMaxPriority )
) i_plic (
  .clk_i            ( clk       ),
  .rst_ni           ( rst_n     ),
  .req_i            ( plic_req  ),
  .resp_o           ( plic_resp ),
  .le_i             ( irq_le_i  ),  // 0:level 1:edge
  .irq_sources_i,                   // already synchronized
  .eip_targets_o    ( irq_o[2*NumPlicHarts-1:0] )
);

// assign irq_o[2*NumHarts-1:2*NumPlicHarts] = '0;

endmodule
