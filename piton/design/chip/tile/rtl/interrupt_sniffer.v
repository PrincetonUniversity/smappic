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

module interrupt_sniffer (
    input clk,    // Clock
    input rst_n,  // Asynchronous reset active low
    
    input        l15_transducer_val,
    input [3:0]  l15_transducer_returntype,
    input [63:0] l15_transducer_data_0,

    output reg ipi, 
    output reg timer_irq, 
    output reg [1:0] irq
);

wire incoming_update = l15_transducer_val & 
                       (l15_transducer_returntype == `CPX_RESTYPE_INTERRUPT) &
                       l15_transducer_data_0[17];
wire is_plic = l15_transducer_data_0[17:16] == 2'b10;
wire goes_up = l15_transducer_data_0[1];
wire second = l15_transducer_data_0[0];

always @(posedge clk) begin 
    if(~rst_n) begin
        ipi <= 0;
        timer_irq <= 0;
        irq <= 0;
    end 
    else begin
        if (incoming_update) begin
            case ({is_plic, second})
                2'b00: begin
                    ipi <= goes_up;
                end
                2'b01: begin
                    timer_irq <= goes_up;
                end
                2'b10: begin
                    irq[0] <= goes_up;
                end
                2'b11: begin
                    irq[1] <= goes_up;
                end
            endcase
        end
    end
end



endmodule