`timescale 1ns / 1ps


module mux3_1(
    input logic [31:0] IN0,IN1,IN2,
    input logic [1:0] S3,
    output logic [31:0] Dout
    );
    assign Dout = S3[1] ? IN2 : (S3[0] ? IN1 : IN0 ) ;
    
endmodule