`timescale 1ns / 1ps
module mux15_1(
input logic [31:0] IN0,IN1,IN2,IN3,IN4,IN5,IN6,IN7,IN8,IN9,IN10,IN11,IN12,IN13,IN14,
input logic [3:0] S15,
output logic [31:0] Dout
    );
assign Dout = S15[3] ? (S15[2] ? (S15[1] ? IN14 : (S15[0] ? IN13 : IN12 ) ) : (S15[1] ? (S15[0] ? IN11 : IN10 ) : (S15[0] ? IN9 : IN8 ) ) ) : (S15[2] ? (S15[1] ? (S15[0] ? IN7 : IN6 ) : (S15[0] ? IN5 : IN4 ) ) : (S15[1] ? (S15[0] ? IN3 : IN2 ) : (S15[0] ? IN1 : IN0 ) ) ) ;
endmodule