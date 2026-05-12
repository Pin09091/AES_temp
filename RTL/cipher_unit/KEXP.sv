`timescale 1ns / 1ps
// =============================================================================
// Module: KEXP (AES Key Expansion)
// Description:
//   Implements the AES key schedule for all three key lengths in a single
//   shared hardware structure. The expanded key words are stored in a chain
//   of 60 registered 32-bit words (kout[0..59]), covering all words needed
//   for AES-256 (60 words). Shorter key schedules use the lower subset.
//
//   Key length encodings (KL):
//     KL = 2'b00 (A=0,B=0): AES-128, Nk=4, 11 round keys, 44 words (kout[0..43])
//     KL = 2'b01 (A=0,B=1): AES-192, Nk=6, 13 round keys, 52 words (kout[0..51])
//     KL = 2'b10 (A=1,B=0): AES-256, Nk=8, 15 round keys, 60 words (kout[0..59])
//     KL = 2'b11: invalid (must not be used)
//
//   Key input:
//     KEY[0..3]  = lower 128 bits of the key (all AES key sizes use these)
//     KEY[4..7]  = upper 128 bits of the key (used only for AES-192/256)
//
//   The expansion runs once after reset by letting the round counter R step
//   from 0 to Rt (10/12/14), with the demultiplexers (dem1_8/9/11) routing
//   clock enables to each group of register stages at the right cycle.
//
//   G-function (GFunc): RotWord + SubWord + Rcon XOR. Applied at key schedule
//   positions that are multiples of Nk.
//   H-function (HFunc): SubWord only (no rotation, no Rcon). Applied at
//   positions that are multiples of Nk and also a multiple of 4 within
//   AES-256 (i.e., positions Nk, 2*Nk, ... that are not G positions).
//
//   The key-expansion-finished flag (KF) is set after all words have been
//   stored, signalling to CU_S and cipher_unit that encryption/decryption
//   may begin.
//
//   Round-key output:
//     Four 15-to-1 muxes (mux15_1) select the four words of the active
//     round key (Rk[0..3]) based on round index R from CU_S.
//
// Inputs:
//   CLK        - System clock
//   CLR        - Asynchronous reset for KF flag; also the Register reset
//   R   [3:0]  - Current round index from CU_S (0..14)
//   KL  [1:0]  - Key length select
//   KEY [7:0]  - 256-bit key input as 8 x 32-bit words
//
// Outputs:
//   Rk  [3:0]  - Active round key (4 x 32-bit words) selected by R
//   KF         - Key expansion finished flag (1 = expansion complete)
//
// Dependencies: Register, GFunc, HFunc, dem1_8, dem1_9, dem1_11, mux3_1, mux15_1
// =============================================================================


module KEXP(input logic CLK, input logic [3:0] R, input logic [1:0] KL, input logic [31:0] KEY [7:0], output logic [31:0] Rk [3:0], input logic CLR, output logic KF);

logic [31:0] kin [3:0];
logic [31:0] kout [59:0];
logic EN, reset;
logic A,B,sel_nk4;
assign reset = CLR;
assign A = KL[1];
assign B = KL[0];
assign sel_nk4 = (~A)&(~B);
logic KF_, KF__;
logic demout4_0,demout4_1, demout4_2, demout4_3, demout4_4, demout4_5, demout4_6, demout4_7, demout4_8, demout4_9, demout4_10; 
logic demout6_0, demout6_1, demout6_2, demout6_3, demout6_4, demout6_5, demout6_6, demout6_7, demout6_8; 
logic demout8_0, demout8_1, demout8_2, demout8_3, demout8_4, demout8_5, demout8_6, demout8_7;



dem1_11 nk4 (.Din(sel_nk4 & (~KF)),.SD11(R),
.O0(demout4_0),.O1(demout4_1),.O2(demout4_2),.O3(demout4_3),.O4(demout4_4),.O5(demout4_5),
.O6(demout4_6),.O7(demout4_7),.O8(demout4_8),.O9(demout4_9),.O10(demout4_10));

dem1_9 nk6(.Din(B & (~KF)),.SD9(R),
.O0(demout6_0),.O1(demout6_1),.O2(demout6_2),.O3(demout6_3),.O4(demout6_4),
.O5(demout6_5),.O6(demout6_6),.O7(demout6_7),.O8(demout6_8));

dem1_8 nk8(.Din(A & (~KF)),.SD8(R),
.O0(demout8_0),.O1(demout8_1),.O2(demout8_2),.O3(demout8_3),.O4(demout8_4),
.O5(demout8_5),.O6(demout8_6),.O7(demout8_7));

logic or3_0, or3_1, or3_2, or3_3, or3_4, or3_5, or3_6, or3_7, or3_8;
logic or3_9, or3_10, or3_11, or3_12, or3_13, or3_14;
logic or2_0, or2_1;

assign or3_0 = demout4_0 | demout6_0 | demout8_0 ;
assign or3_1 = demout4_1 | demout6_0 | demout8_0 ; 
assign or3_2 = demout4_1 | demout6_1 | demout8_0 ;
assign or3_3 = demout4_2 | demout6_1 | demout8_1 ;
assign or3_4 = demout4_3 | demout6_2 | demout8_1 ;
assign or3_5 = demout4_4 | demout6_2 | demout8_2 ;
assign or3_6 = demout4_4 | demout6_3 | demout8_2 ;
assign or3_7 = demout4_5 | demout6_3 | demout8_2 ;
assign or3_8 = demout4_6 | demout6_4 | demout8_3 ;
assign or3_9 = demout4_7 | demout6_4 | demout8_3 ;
assign or3_10 = demout4_7 | demout6_5 | demout8_3 ;
assign or3_11 = demout4_8 | demout6_5 | demout8_4 ;
assign or3_12 = demout4_9 | demout6_6 | demout8_4 ;
assign or3_13 = demout4_10 | demout6_6 | demout8_5 ;
assign or3_14 = demout4_10 | demout6_7 | demout8_5 ;

assign or2_0 = demout6_7 | demout8_5;
assign or2_1 = demout6_8 | demout8_6;

//


assign kin [0] = KEY[0];
assign kin [1] = KEY[1];
assign kin [2] = KEY[2];
assign kin [3] = KEY[3];

Register R0 (.CLK(CLK), .reset(reset), .EN(or3_0), .Din(kin[0]), .Dout(kout[0]));
Register R1 (.CLK(CLK), .reset(reset), .EN(or3_0), .Din(kin[1]), .Dout(kout[1]));
Register R2 (.CLK(CLK), .reset(reset), .EN(or3_0), .Din(kin[2]), .Dout(kout[2]));
Register R3 (.CLK(CLK), .reset(reset), .EN(or3_0), .Din(kin[3]), .Dout(kout[3]));

//BREAK



logic [31:0] g3out, g5out, g7out, g11out, g15out, g17out, g19out, g23out, g27out, g29out, g31out, g35out, g39out, g41out, g47out, g55out;

logic [31:0] mux4out, mux5out, mux6out, mux6_1out, mux6_2out, mux7out, mux7_1out, mux8out, mux12out, mux16out, mux18out, mux30out, mux32out;
logic [31:0] mux36out, mux40out, mux42out, mux44out, mux44_1out, mux45out, mux46out, mux47out, mux48out, mux49out, mux50out, mux51out;

logic [31:0] mx8out, mx9out, mx10out, mx11out, mx12out, mx13out, mx14out, mx15out, mx16out, mx17out, mx18out, mx19out, mx20out, mx20_1out, mx21out, mx22out, mx23out;
logic [31:0] mx24out, mx25out, mx26out, mx27out, mx28out, mx28_1out, mx29out, mx30out, mx31out, mx32out, mx33out, mx34out, mx35out, mx36out, mx37out, mx38out, mx39out;
logic [31:0] mx40out, mx41out, mx42out, mx43out;

logic [31:0] xor8, xor9, xor10, xor11, xor12, xor13, xor14, xor15, xor16, xor17, xor18, xor19, xor20, xor21, xor22, xor23, xor24;
logic [31:0] xor25, xor26, xor27, xor28, xor29, xor30, xor31, xor32, xor33, xor34, xor35, xor36, xor37, xor38, xor39, xor40, xor41;
logic [31:0] xor42, xor43, xor44, xor45, xor46, xor47, xor48, xor49, xor50, xor51, xor52, xor53, xor54, xor55, xor56, xor57, xor58, xor59;
logic [31:0] h11out, h19out, h27out, h35out, h43out, h51out;

logic [7:0] gmux7, gmux11, gmux15, gmux23, gmux31, gmux35, gmux39, gmux47;




GFunc g3 (.Gin(kin[3]),.RC(8'h01), .Gout(g3out));
assign mux4out = (A | B) ? (KEY[4]) : (g3out ^ kout[0]);

Register R4 (.CLK(CLK), .reset(reset), .EN(or3_1), .Din(mux4out), .Dout(kout[4]));

assign mux5out = (A | B ) ? (KEY[5]) : (mux4out ^ kout[1]);
Register R5 (.CLK(CLK), .reset(reset), .EN(or3_1), .Din(mux5out), .Dout(kout[5]));

GFunc g5 (.Gin(mux5out), .RC(8'h01), .Gout(g5out));
assign mux6_1out =  (B) ? (g5out) : (mux5out);
assign mux6_2out =  (B) ? (kout[0]) : (kout[2]);
assign mux6out =  (A) ? (KEY[6]) : ( mux6_1out ^ mux6_2out );
Register R6 (.CLK(CLK), .reset(reset), .EN(or3_2), .Din(mux6out), .Dout(kout[6]));

assign mux7_1out = (B) ? (kout[1]) : (kout[3]);
assign mux7out = (A) ? (KEY[7]) : (mux6out ^ mux7_1out);
Register R7 (.CLK(CLK), .reset(reset), .EN(or3_2), .Din(mux7out), .Dout(kout[7]));

assign gmux7 = (A) ? 8'h01 : 8'h02;
GFunc g7 (.Gin(mux7out), .RC(gmux7), .Gout(g7out));
assign mux8out = (~B) ?  (g7out): (mux7out);
mux3_1 m8 (.IN0(kout[4]), .IN1(kout[2]), .IN2(kout[0]), .S3(KL), .Dout(mx8out));
assign xor8 = (mux8out) ^ (mx8out);
Register R8 (.CLK(CLK), .reset(reset), .EN(or3_3), .Din(xor8), .Dout(kout[8]));

mux3_1 m9 (.IN0(kout[5]), .IN1(kout[3]), .IN2(kout[1]), .S3(KL), .Dout(mx9out));
assign xor9 = (xor8) ^ (mx9out);
Register R9 (.CLK(CLK), .reset(reset), .EN(or3_3), .Din(xor9), .Dout(kout[9]));

mux3_1 m10 (.IN0(kout[6]), .IN1(kout[4]), .IN2(kout[2]), .S3(KL), .Dout(mx10out));
assign xor10 = (xor9) ^ (mx10out);
Register R10 (.CLK(CLK), .reset(reset), .EN(or3_3), .Din(xor10), .Dout(kout[10]));

mux3_1 m11 (.IN0(kout[7]), .IN1(kout[5]), .IN2(kout[3]), .S3(KL), .Dout(mx11out));
assign xor11 = (xor10) ^ (mx11out);
Register R11 (.CLK(CLK), .reset(reset), .EN(or3_3), .Din(xor11), .Dout(kout[11]));

assign gmux11 = (B) ? 8'h02: 8'h04;
GFunc g11 (.Gin(xor11), .RC(gmux11), .Gout(g11out));
HFunc h11 (.Hin(xor11), .Hout (h11out));
assign mux12out = (A) ? (h11out) : (g11out);
mux3_1 m12 (.IN0(kout[8]), .IN1(kout[6]), .IN2(kout[4]), .S3(KL), .Dout(mx12out));
assign xor12 = (mux12out) ^ (mx12out);
Register R12 (.CLK(CLK), .reset(reset), .EN(or3_4), .Din(xor12), .Dout(kout[12]));

mux3_1 m13 (.IN0(kout[9]), .IN1(kout[7]), .IN2(kout[5]), .S3(KL), .Dout(mx13out));
assign xor13 = (xor12) ^ (mx13out);
Register R13 (.CLK(CLK), .reset(reset), .EN(or3_4), .Din(xor13), .Dout(kout[13]));

mux3_1 m14 (.IN0(kout[10]), .IN1(kout[8]), .IN2(kout[6]), .S3(KL), .Dout(mx14out));
assign xor14 = (xor13) ^ (mx14out);
Register R14 (.CLK(CLK), .reset(reset), .EN(or3_4), .Din(xor14), .Dout(kout[14]));

mux3_1 m15 (.IN0(kout[11]), .IN1(kout[9]), .IN2(kout[7]), .S3(KL), .Dout(mx15out));
assign xor15 = (xor14) ^ (mx15out);
Register R15 (.CLK(CLK), .reset(reset), .EN(or3_4), .Din(xor15), .Dout(kout[15]));

assign gmux15 = (A) ? 8'h02 : 8'h08;
GFunc g15 (.Gin(xor15), .RC(gmux15), .Gout(g15out));
assign mux16out = (~B) ?  (g15out): (xor15);
mux3_1 m16 (.IN0(kout[12]), .IN1(kout[10]), .IN2(kout[8]), .S3(KL), .Dout(mx16out));
assign xor16 = (mux16out) ^ (mx16out);
Register R16 (.CLK(CLK), .reset(reset), .EN(or3_5), .Din(xor16), .Dout(kout[16]));

mux3_1 m17 (.IN0(kout[13]), .IN1(kout[11]), .IN2(kout[9]), .S3(KL), .Dout(mx17out));
assign xor17 = (xor16) ^ (mx17out);
Register R17 (.CLK(CLK), .reset(reset), .EN(or3_5), .Din(xor17), .Dout(kout[17]));

GFunc g17 (.Gin(xor17), .RC(8'h04), .Gout(g17out));
assign mux18out = (B) ? (g17out) : (xor17);
mux3_1 m18 (.IN0(kout[14]), .IN1(kout[12]), .IN2(kout[10]), .S3(KL), .Dout(mx18out));
assign xor18 = (mux18out) ^ (mx18out);
Register R18 (.CLK(CLK), .reset(reset), .EN(or3_6), .Din(xor18), .Dout(kout[18]));

mux3_1 m19 (.IN0(kout[15]), .IN1(kout[13]), .IN2(kout[11]), .S3(KL), .Dout(mx19out));
assign xor19 = (xor18) ^ (mx19out);
Register R19 (.CLK(CLK), .reset(reset), .EN(or3_6), .Din(xor19), .Dout(kout[19]));

GFunc g19 (.Gin(xor19), .RC(8'h10), .Gout(g19out));
HFunc h19 (.Hin(xor19), .Hout(h19out));
mux3_1 m20_1 (.IN0(g19out), .IN1(xor19), .IN2(h19out), .S3(KL), .Dout(mx20_1out));
mux3_1 m20 (.IN0(kout[16]), .IN1(kout[14]), .IN2(kout[12]), .S3(KL), .Dout(mx20out));
assign xor20 = (mx20out) ^ (mx20_1out);
Register R20 (.CLK(CLK), .reset(reset), .EN(or3_7), .Din(xor20), .Dout(kout[20]));

mux3_1 m21 (.IN0(kout[17]), .IN1(kout[15]), .IN2(kout[13]), .S3(KL), .Dout(mx21out));
assign xor21 = (xor20) ^ (mx21out);
Register R21 (.CLK(CLK), .reset(reset), .EN(or3_7), .Din(xor21), .Dout(kout[21]));

mux3_1 m22 (.IN0(kout[18]), .IN1(kout[16]), .IN2(kout[14]), .S3(KL), .Dout(mx22out));
assign xor22 = (xor21) ^ (mx22out);
Register R22 (.CLK(CLK), .reset(reset), .EN(or3_7), .Din(xor22), .Dout(kout[22]));

mux3_1 m23 (.IN0(kout[19]), .IN1(kout[17]), .IN2(kout[15]), .S3(KL), .Dout(mx23out));
assign xor23 = (xor22) ^ (mx23out);
Register R23 (.CLK(CLK), .reset(reset), .EN(or3_7), .Din(xor23), .Dout(kout[23]));

assign gmux23 = (KL[1]) ? 8'h04 : (KL[0]) ? 8'h08 : 8'h20; 
GFunc g23(.Gin(xor23), .RC(gmux23), .Gout(g23out));
mux3_1 m24 (.IN0(kout[20]), .IN1(kout[18]), .IN2(kout[16]), .S3(KL), .Dout(mx24out));
assign xor24 = (g23out) ^ (mx24out);
Register R24 (.CLK(CLK), .reset(reset), .EN(or3_8), .Din(xor24), .Dout(kout[24]));

mux3_1 m25 (.IN0(kout[21]), .IN1(kout[19]), .IN2(kout[17]), .S3(KL), .Dout(mx25out));
assign xor25 = (xor24) ^ (mx25out);
Register R25 (.CLK(CLK), .reset(reset), .EN(or3_8), .Din(xor25), .Dout(kout[25]));

mux3_1 m26 (.IN0(kout[22]), .IN1(kout[20]), .IN2(kout[18]), .S3(KL), .Dout(mx26out));
assign xor26 = (xor25) ^ (mx26out);
Register R26 (.CLK(CLK), .reset(reset), .EN(or3_8), .Din(xor26), .Dout(kout[26]));

mux3_1 m27 (.IN0(kout[23]), .IN1(kout[21]), .IN2(kout[19]), .S3(KL), .Dout(mx27out));
assign xor27 = (xor26) ^ (mx27out);
Register R27 (.CLK(CLK), .reset(reset), .EN(or3_8), .Din(xor27), .Dout(kout[27]));
 
GFunc g27 (.Gin(xor27), .RC(8'h40), .Gout(g27out));
HFunc h27 (.Hin(xor27), .Hout(h27out));
mux3_1 m28_1 (.IN0(g27out), .IN1(xor27), .IN2(h27out), .S3(KL), .Dout(mx28_1out));
mux3_1 m28 (.IN0(kout[24]), .IN1(kout[22]), .IN2(kout[20]), .S3(KL), .Dout(mx28out));
assign xor28 = (mx28out) ^ (mx28_1out);
Register R28 (.CLK(CLK), .reset(reset), .EN(or3_9), .Din(xor28), .Dout(kout[28]));

mux3_1 m29 (.IN0(kout[25]), .IN1(kout[23]), .IN2(kout[21]), .S3(KL), .Dout(mx29out));
assign xor29 = (xor28) ^ (mx29out);
Register R29 (.CLK(CLK), .reset(reset), .EN(or3_9), .Din(xor29), .Dout(kout[29]));

GFunc g29 (.Gin(xor29), .RC(8'h10), .Gout(g29out));
assign mux30out = (B) ? (g29out) : (xor29);
mux3_1 m30(.IN0(kout[26]), .IN1(kout[24]), .IN2(kout[22]), .S3(KL), .Dout(mx30out));
assign xor30 = (mux30out) ^ (mx30out);
Register R30 (.CLK(CLK), .reset(reset), .EN(or3_10), .Din(xor30), .Dout(kout[30]));

mux3_1 m31 (.IN0(kout[27]), .IN1(kout[25]), .IN2(kout[23]), .S3(KL), .Dout(mx31out));
assign xor31 = (xor30) ^ (mx31out);
Register R31 (.CLK(CLK), .reset(reset), .EN(or3_10), .Din(xor31), .Dout(kout[31]));

assign gmux31 = (A) ? 8'h08 : 8'h80;
GFunc g31 (.Gin(xor31), .RC(gmux31), .Gout(g31out));
assign mux32out = (~B) ?  (g31out): (xor31);
mux3_1 m32 (.IN0(kout[28]), .IN1(kout[26]), .IN2(kout[24]), .S3(KL), .Dout(mx32out));
assign xor32 = (mux32out) ^ (mx32out);
Register R32 (.CLK(CLK), .reset(reset), .EN(or3_11), .Din(xor32), .Dout(kout[32]));

mux3_1 m33 (.IN0(kout[29]), .IN1(kout[27]), .IN2(kout[25]), .S3(KL), .Dout(mx33out));
assign xor33 = (xor32) ^ (mx33out);
Register R33 (.CLK(CLK), .reset(reset), .EN(or3_11), .Din(xor33), .Dout(kout[33]));

mux3_1 m34 (.IN0(kout[30]), .IN1(kout[28]), .IN2(kout[26]), .S3(KL), .Dout(mx34out));
assign xor34 = (xor33) ^ (mx34out);
Register R34 (.CLK(CLK), .reset(reset), .EN(or3_11), .Din(xor34), .Dout(kout[34]));

mux3_1 m35 (.IN0(kout[31]), .IN1(kout[29]), .IN2(kout[27]), .S3(KL), .Dout(mx35out));
assign xor35 = (xor34) ^ (mx35out);
Register R35 (.CLK(CLK), .reset(reset), .EN(or3_11), .Din(xor35), .Dout(kout[35]));

assign gmux35 = (B) ? 8'h20 : 8'h1B;
GFunc g35 (.Gin(xor35), .RC(gmux35), .Gout(g35out));
HFunc h35 (.Hin(xor35), .Hout (h35out));
assign mux36out = (A) ? (h35out) : (g35out);
mux3_1 m36 (.IN0(kout[32]), .IN1(kout[30]), .IN2(kout[28]), .S3(KL), .Dout(mx36out));
assign xor36 = (mux36out) ^ (mx36out);
Register R36 (.CLK(CLK), .reset(reset), .EN(or3_12), .Din(xor36), .Dout(kout[36]));

mux3_1 m37 (.IN0(kout[33]), .IN1(kout[31]), .IN2(kout[29]), .S3(KL), .Dout(mx37out));
assign xor37 = (xor36) ^ (mx37out);
Register R37 (.CLK(CLK), .reset(reset), .EN(or3_12), .Din(xor37), .Dout(kout[37]));

mux3_1 m38 (.IN0(kout[34]), .IN1(kout[32]), .IN2(kout[30]), .S3(KL), .Dout(mx38out));
assign xor38 = (xor37) ^ (mx38out);
Register R38 (.CLK(CLK), .reset(reset), .EN(or3_12), .Din(xor38), .Dout(kout[38]));

mux3_1 m39 (.IN0(kout[35]), .IN1(kout[33]), .IN2(kout[31]), .S3(KL), .Dout(mx39out));
assign xor39 = (xor38) ^ (mx39out);
Register R39 (.CLK(CLK), .reset(reset), .EN(or3_12), .Din(xor39), .Dout(kout[39]));

assign gmux39 = (A) ? 8'h10 : 8'h36;
GFunc g39 (.Gin(xor39), .RC(gmux39), .Gout(g39out));
assign mux40out = (~B) ?  (g39out): (xor39);
mux3_1 m40 (.IN0(kout[36]), .IN1(kout[34]), .IN2(kout[32]), .S3(KL), .Dout(mx40out));
assign xor40 = (mux40out) ^ (mx40out);
Register R40 (.CLK(CLK), .reset(reset), .EN(or3_13), .Din(xor40), .Dout(kout[40]));

mux3_1 m41 (.IN0(kout[37]), .IN1(kout[35]), .IN2(kout[33]), .S3(KL), .Dout(mx41out));
assign xor41 = (xor40) ^ (mx41out);
Register R41 (.CLK(CLK), .reset(reset), .EN(or3_13), .Din(xor41), .Dout(kout[41]));

GFunc g41 (.Gin(xor41), .RC(8'h40), .Gout(g41out));
assign mux42out = (B) ? (g41out) : (xor41);
mux3_1 m42(.IN0(kout[38]), .IN1(kout[36]), .IN2(kout[34]), .S3(KL), .Dout(mx42out));
assign xor42 = (mux42out) ^ (mx42out);
Register R42 (.CLK(CLK), .reset(reset), .EN(or3_14), .Din(xor42), .Dout(kout[42]));

mux3_1 m43 (.IN0(kout[39]), .IN1(kout[37]), .IN2(kout[35]), .S3(KL), .Dout(mx43out));
assign xor43 = (xor42) ^ (mx43out);
Register R43 (.CLK(CLK), .reset(reset), .EN(or3_14), .Din(xor43), .Dout(kout[43]));

HFunc h43 (.Hin(xor43), .Hout (h43out));
assign mux44_1out = (A) ? (h43out) : (xor43);
assign mux44out =  (A) ? (kout[36]) : (kout[38]);
assign xor44 = (mux44out) ^ (mux44_1out);
Register R44 (.CLK(CLK), .reset(reset), .EN(or2_0), .Din(xor44), .Dout(kout[44]));

assign mux45out = (A) ? (kout[37]) : (kout[39]);
assign xor45 = (mux45out) ^ (xor44);
Register R45 (.CLK(CLK), .reset(reset), .EN(or2_0), .Din(xor45), .Dout(kout[45]));

assign mux46out = (A) ? (kout[38]) : (kout[40]);
assign xor46 = (mux46out) ^ (xor45);
Register R46 (.CLK(CLK), .reset(reset), .EN(or2_0), .Din(xor46), .Dout(kout[46]));

assign mux47out = (A) ? (kout[39]) : (kout[41]);
assign xor47 = (mux47out) ^ (xor46);
Register R47 (.CLK(CLK), .reset(reset), .EN(or2_0), .Din(xor47), .Dout(kout[47]));

assign gmux47 = (A) ? 8'h20 : 8'h80;
GFunc g47 (.Gin(xor47), .RC(gmux47), .Gout(g47out));
assign mux48out = (A) ? (kout[40]) : (kout[42]);
assign xor48 = (mux48out) ^ (g47out);
Register R48 (.CLK(CLK), .reset(reset), .EN(or2_1), .Din(xor48), .Dout(kout[48]));

assign mux49out = (A) ? (kout[41]) : (kout[43]);
assign xor49 = (mux49out) ^ (xor48);
Register R49 (.CLK(CLK), .reset(reset), .EN(or2_1), .Din(xor49), .Dout(kout[49]));

assign mux50out = (A) ? (kout[42]) : (kout[44]);
assign xor50 = (mux50out) ^ (xor49);
Register R50 (.CLK(CLK), .reset(reset), .EN(or2_1), .Din(xor50), .Dout(kout[50]));

assign mux51out = (A) ? (kout[43]) : (kout[45]);
assign xor51 = (mux51out) ^ (xor50);
Register R51 (.CLK(CLK), .reset(reset), .EN(or2_1), .Din(xor51), .Dout(kout[51]));

HFunc h51(.Hin(xor51), .Hout(h51out));
assign xor52 = (h51out) ^ (kout[44]);
Register R52 (.CLK(CLK), .reset(reset), .EN(demout8_6), .Din(xor52), .Dout(kout[52]));

assign xor53 = (xor52) ^ (kout[45]);
Register R53 (.CLK(CLK), .reset(reset), .EN(demout8_6), .Din(xor53), .Dout(kout[53]));

assign xor54 = (xor53) ^ (kout[46]);
Register R54 (.CLK(CLK), .reset(reset), .EN(demout8_6), .Din(xor54), .Dout(kout[54]));

assign xor55 = (xor54) ^ (kout[47]);
Register R55 (.CLK(CLK), .reset(reset), .EN(demout8_6), .Din(xor55), .Dout(kout[55]));

GFunc g55(.Gin(xor55), .RC(8'h40), .Gout(g55out));
assign xor56 = (g55out) ^ (kout[48]);
Register R56 (.CLK(CLK), .reset(reset), .EN(demout8_7), .Din(xor56), .Dout(kout[56]));

assign xor57 = (xor56) ^ (kout[49]);
Register R57 (.CLK(CLK), .reset(reset), .EN(demout8_7), .Din(xor57), .Dout(kout[57]));

assign xor58 = (xor57) ^ (kout[50]);
Register R58 (.CLK(CLK), .reset(reset), .EN(demout8_7), .Din(xor58), .Dout(kout[58]));

assign xor59 = (xor58) ^ (kout[51]);
Register R59 (.CLK(CLK), .reset(reset), .EN(demout8_7), .Din(xor59), .Dout(kout[59]));

//

//key expansion completion flag 

assign KF__ = (sel_nk4 & demout4_10) | (B & demout6_8) | (A & demout8_7);
always_ff@(posedge CLK) begin
KF_ <= KF__;
end
always_ff@(posedge KF_ or posedge CLR) begin
if(CLR) begin
KF <= 1'b0;
end else begin
KF <= 1'b1;
end
end 



mux15_1 mul0 (.IN0(kout[0]),.IN1(kout[4]),.IN2(kout[8]),.IN3(kout[12]),
.IN4(kout[16]),.IN5(kout[20]),.IN6(kout[24]),.IN7(kout[28]),
.IN8(kout[32]),.IN9(kout[36]),.IN10(kout[40]),.IN11(kout[44]),
.IN12(kout[48]),.IN13(kout[52]),.IN14(kout[56]),
.S15(R),.Dout(Rk[0]));

mux15_1 mul1 (.IN0(kout[1]),.IN1(kout[5]),.IN2(kout[9]),.IN3(kout[13]),
.IN4(kout[17]),.IN5(kout[21]),.IN6(kout[25]),.IN7(kout[29]),
.IN8(kout[33]),.IN9(kout[37]),.IN10(kout[41]),.IN11(kout[45]),
.IN12(kout[49]),.IN13(kout[53]),.IN14(kout[57]),
.S15(R),.Dout(Rk[1]));

mux15_1 mul2 (.IN0(kout[2]),.IN1(kout[6]),.IN2(kout[10]),.IN3(kout[14]),
.IN4(kout[18]),.IN5(kout[22]),.IN6(kout[26]),.IN7(kout[30]),
.IN8(kout[34]),.IN9(kout[38]),.IN10(kout[42]),.IN11(kout[46]),
.IN12(kout[50]),.IN13(kout[54]),.IN14(kout[58]),
.S15(R),.Dout(Rk[2]));


mux15_1 mul3 (.IN0(kout[3]),.IN1(kout[7]),.IN2(kout[11]),.IN3(kout[15]),
.IN4(kout[19]),.IN5(kout[23]),.IN6(kout[27]),.IN7(kout[31]),
.IN8(kout[35]),.IN9(kout[39]),.IN10(kout[43]),.IN11(kout[47]),
.IN12(kout[51]),.IN13(kout[55]),.IN14(kout[59]),
.S15(R),.Dout(Rk[3]));





endmodule