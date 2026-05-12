`timescale 1ns / 1ps


module dem1_8(
input logic Din,
input logic [2:0] SD8,
output logic O0,O1,O2,O3,O4,O5,O6,O7
    );
logic S2,S_2,S1,S_1,S0,S_0;
assign S2 = SD8[2];
assign S_2 = ~SD8[2];
assign S1 = SD8[1];
assign S_1 = ~SD8[1];
assign S0 = SD8[0];
assign S_0 = ~SD8[0];
assign O0 = Din & S_2 & S_1 & S_0;
assign O1 = Din & S_2 & S_1 & S0;
assign O2 = Din & S_2 & S1 & S_0;
assign O3 = Din & S_2 & S1 & S0;
assign O4 = Din & S2 & S_1 & S_0;
assign O5 = Din & S2 & S_1 & S0;
assign O6 = Din & S2 & S1 & S_0;
assign O7 = Din & S2 & S1 & S0;
endmodule