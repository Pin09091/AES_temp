`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2025 02:34:28 PM
// Design Name: 
// Module Name: Xtime
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


module Xtime(
input logic [7:0] A, // Input Byte
output logic [7:0] B // Output Byte
    );
    assign B = A[7] ? ((A<<1)^8'h1b) : (A<<1) ; 
endmodule