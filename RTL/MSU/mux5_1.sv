`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2025 09:48:31 AM
// Design Name: 
// Module Name: mux5_1
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


module mux5_1(
input logic [31:0] IN0,IN1,IN2,IN3,IN4,
input logic [2:0] S5,
output logic [31:0] Dout
    );
assign Dout = S5[2] ? (IN4) : (S5[1] ? (S5[0] ? IN3 : IN2 ) : (S5[0] ? IN1 : IN0 ) )  ;
endmodule   
