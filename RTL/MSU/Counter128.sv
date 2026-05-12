`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2025 11:53:07 AM
// Design Name: 
// Module Name: Counter128
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Counter128(
input logic RST, CLK, EN,
output logic [127:0] CTR
    );
    always_ff@(posedge CLK or posedge RST) begin
    if(RST) begin
    CTR <= 128'b0;
    end else begin
    if(EN) begin
    CTR <= CTR + 1;
    end
    end    
    end
endmodule
