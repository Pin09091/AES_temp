`timescale 1ns / 1ps

module HFunc(
input logic [31:0] Hin,
output logic [31:0] Hout
    );
    S_Box s1(.A(Hin [31:24]), .B(Hout [31:24]));
    S_Box s2(.A(Hin [23:16]), .B(Hout [23:16]));
    S_Box s3(.A(Hin [15:8]), .B(Hout [15:8]));
    S_Box s4(.A(Hin [7:0]), .B(Hout [7:0]));
endmodule