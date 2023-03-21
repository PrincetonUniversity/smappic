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

module gng_top (
    // Clock and reset
    input  wire                             clk,
    input  wire                             rst_n,

    // NOC interface
    input  wire                             in_val,
    input  wire [`NOC_DATA_WIDTH-1:0]       in_data,
    output wire                             in_rdy,

    output wire                             out_val,
    output wire [`NOC_DATA_WIDTH-1:0]       out_data,
    input  wire                             out_rdy
);


wire awvalid;
wire wvalid;
wire bready;
reg wr_pend;
wire awready = bready | (~wr_pend);
wire wready = bready | (~wr_pend);

wire arvalid;
wire rready;
wire rvalid;
wire [63:0] rdata;

noc_axilite_bridge  #(
    .SLAVE_RESP_BYTEWIDTH   (8), 
    .SWAP_ENDIANESS         (1)
) gng_bridge(
    .clk(clk), 
    .rst(~rst_n), 

    .splitter_bridge_val (in_val), 
    .splitter_bridge_data(in_data), 
    .bridge_splitter_rdy(in_rdy), 

    .bridge_splitter_val(out_val), 
    .bridge_splitter_data(out_data), 
    .splitter_bridge_rdy(out_rdy), 

    .m_axi_awaddr(), 
    .m_axi_awvalid(awvalid), 
    .m_axi_awready(awready), 
    .m_axi_wdata(), 
    .m_axi_wstrb(), 
    .m_axi_wvalid(wvalid), 
    .m_axi_wready(wready), 
    .m_axi_bresp(2'b0), 
    .m_axi_bvalid(wr_pend), 
    .m_axi_bready(bready),

    .m_axi_araddr(), 
    .m_axi_arvalid(arvalid), 
    .m_axi_arready(1'b1), 
    .m_axi_rdata(rdata), 
    .m_axi_rresp(2'b0), 
    .m_axi_rvalid(rvalid), 
    .m_axi_rready(rready)
);

always @(posedge clk) begin
    if(~rst_n) begin
        wr_pend <= 0;
    end 
    else begin
        if (bready)
            wr_pend <= (awvalid | wvalid);
        else 
            wr_pend <= (wr_pend | awvalid | wvalid);
    end
end


wire [15:0] gng_dat;
wire gng_val;
reg [3:0] gng_cnt;

gng gng(
    .clk(clk), 
    .rstn(rst_n), 

    .ce(|(~gng_cnt)), 
    .valid_out(gng_val), 
    .data_out(gng_dat)
);

reg [63:0] gng_dat_r;
reg [3:0] gng_val_r;

always @(posedge clk) begin
    if(~rst_n) begin
        gng_dat_r <= 64'b0;
        gng_val_r <= 0;
        gng_cnt <= 4'b1000;
    end 
    else begin
        if (gng_val) begin
            gng_val_r <= ((gng_val_r << 1 ) | 4'b1);
            gng_dat_r <= ((gng_dat_r << 16) | gng_dat);
        end
        else if (rvalid & rready) begin
            gng_val_r <= 0;
            gng_cnt <= 4'b1000;
        end
        else begin
            gng_cnt <= (gng_cnt >> 1);      
        end
    end
end

assign rvalid = &gng_val_r;
assign rdata = gng_dat_r;

always @ (negedge clk)
begin
    if (in_val) begin
        $display("%d: GNG incoming request ", $time);
    end
    if (out_val) begin
        $display("%d: GNG outgoing response ", $time);
    end
end
endmodule