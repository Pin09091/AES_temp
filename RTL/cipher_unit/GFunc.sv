`timescale 1ns / 1ps


module GFunc(
input logic [31:0] Gin,
input logic [7:0] RC,
output logic [31:0] Gout
    );
    logic [31:0] V;
    S_Box s1(.A(Gin [31:24]), .B(V [7:0]));
    S_Box s2(.A(Gin [23:16]), .B(V [31:24]));
    S_Box s3(.A(Gin [15:8]), .B(V [23:16]));
    S_Box s4(.A(Gin [7:0]), .B(V [15:8]));
    assign Gout = {(V[31:24] ^ RC),V[23:0]};
endmodule