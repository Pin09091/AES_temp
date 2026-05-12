`timescale 1ns / 1ps

module CU_S_tb();

logic clk = 0;
logic clr;
logic e_d;
logic [1:0]kl;
logic kf;
logic MUX0;
logic MUX1;
logic [1:0]MUX2;
logic MUX3;
logic MUX4;
logic MUX5;
logic MUX6;
logic se;
logic SCLR;
logic CF;
logic [3:0]r;

CU_S s(
.CLK(clk),
.CLR(clr),
.enc_dec(e_d),
.KL(kl),
.KF(kf),
.mux0(MUX0),
.mux1(MUX1),
.mux2(MUX2),
.mux3(MUX3),
.mux4(MUX4),
.mux5(MUX5),
.mux6(MUX6),
.SE(se),
.SCLR(SCLR),
.CF(CF),
.R(r)
    ); 
    
logic [3:0]State;    
assign State = s.STATE;    
    
always #10 clk = ~clk;//clock alternating    
    
initial
begin
#10// initital
    clr = 1;
    e_d = 1;
    kl = 0;//4
    kf = 0;//RK has not been generated yet
#20// first cycle
    clr = 0;
    e_d = 1;
    kl = 0;//4
    kf = 0;//RK has not been generated yet
#200// all cycles till r = 9
    clr = 0;
    e_d = 1;
    kl = 0;//4
    kf = 1;
#20// r = 10
    clr = 0;
    e_d = 1;
    kl = 0;//4
    kf = 1;
#260//r = 10 again

    // initital
    clr = 1;
    e_d = 0;
    kl = 0;//4
    kf = 1;//RK has not been generated yet
    #20
    clr = 0;
    #260//r = 10 again


$stop;
$finish;
end    
    



endmodule
