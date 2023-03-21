// Copyright (c) 2922 Princeton University
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

module uart_switcher #(
  parameter PITON_N = 4,
  parameter PITON_N_LOG = 2
) (
    input shell_clk,
    input piton_clk,

    input piton_tx[PITON_N-1:0], 
    output piton_rx[PITON_N-1:0], 

    input shell_tx, 
    output shell_rx, 

    `ifdef PITONSYS_UART_CTS
    output piton_cts[PITON_N-1:0],
    input  piton_rts[PITON_N-1:0],
    output shell_cts,
    input  shell_rts,
    `endif

    input [PITON_N_LOG-1:0] sw
);

    assign shell_rx = piton_tx[sw];
    `ifdef PITONSYS_UART_CTS
    assign shell_cts = piton_rts[sw];
    `endif
    genvar i;
    generate
    for (i = 0; i < PITON_N; i = i + 1)
    begin
        assign piton_rx[i] = (i == sw) ? shell_tx : 1'b0;
        `ifdef PITONSYS_UART_CTS
        assign piton_cts[i] = (i == sw) ? shell_rts : 1'b0;
        `endif 
    end
    endgenerate
endmodule : uart_switcher