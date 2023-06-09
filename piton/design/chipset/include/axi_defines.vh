// ========== Copyright Header Begin ============================================
// Copyright (c) 2019 Princeton University
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

`ifndef AXI_DEFINES_VH
`define AXI_DEFINES_VH


`define AXI4_DATA_WIDTH  512
`define AXI4_ID_WIDTH    16
`define AXI4_ADDR_WIDTH  64
`define AXI4_LEN_WIDTH   8
`define AXI4_SIZE_WIDTH  3
`define AXI4_STRB_WIDTH  64
`define AXI4_BURST_WIDTH 2
`define AXI4_RESP_WIDTH  2
`define AXI4_CACHE_WIDTH 4
`define AXI4_PROT_WIDTH 3
`define AXI4_QOS_WIDTH 4
`define AXI4_REGION_WIDTH 4
`define AXI4_USER_WIDTH 11

`define AXIL_ADDR_WIDTH 32
`define AXIL_PROT_WIDTH 3
`define AXIL_DATA_WIDTH 32
`define AXIL_STRB_WIDTH 4
`define AXIL_RESP_WIDTH 2

`endif