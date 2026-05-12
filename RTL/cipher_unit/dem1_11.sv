`timescale 1ns / 1ps


module dem1_11(
input logic Din,
input logic [3:0] SD11,
output logic O0,O1,O2,O3,O4,O5,O6,O7,O8,O9,O10
    );
logic S3,S_3,S2,S_2,S1,S_1,S0,S_0;
assign S3 = SD11[3];
assign S_3 = ~SD11[3];
assign S2 = SD11[2];
assign S_2 = ~SD11[2];
assign S1 = SD11[1];
assign S_1 = ~SD11[1];
assign S0 = SD11[0];
assign S_0 = ~SD11[0];
assign O0 = Din & S_3 & S_2 & S_1 & S_0;
assign O1 = Din & S_3 & S_2 & S_1 & S0;
assign O2 = Din & S_3 & S_2 & S1 & S_0;
assign O3 = Din & S_3 & S_2 & S1 & S0;
assign O4 = Din & S_3 & S2 & S_1 & S_0;
assign O5 = Din & S_3 & S2 & S_1 & S0;
assign O6 = Din & S_3 & S2 & S1 & S_0;
assign O7 = Din & S_3 & S2 & S1 & S0;
assign O8 = Din & S3 & S_2 & S_1 & S_0;
assign O9 = Din & S3 & S_2 & S_1 & S0;
assign O10 = Din & S3 & S_2 & S1 & S_0;
endmodule