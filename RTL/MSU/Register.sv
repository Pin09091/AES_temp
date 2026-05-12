`timescale 1ns / 1ps

module Register(
input logic CLK, reset, EN,
input logic [31:0] Din,
output logic [31:0] Dout
    );
    always_ff@(posedge CLK or posedge reset) begin
    if(reset) begin
    Dout <= 32'h00000000; 
    end else begin
    if(EN) begin
    Dout <= Din;
    end
    end
    end
endmodule