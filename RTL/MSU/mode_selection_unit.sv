`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2025 09:43:42 AM
// Design Name: 
// Module Name: IOM
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


module mode_selection_unit(
input logic [127:0] DataIn, KeyIn1,KeyIn2,IVIn,
input logic [2:0] ModeSelect,
input logic [1:0] KeySelect,
input logic RST, CLK, enc_dec,
output logic [127:0] DataOut,
output logic OF, RF                                                                                             //Output and Read Flag
    );
    logic [31:0] IV [3:0];                                                                                      // Initial Vector
    logic [31:0] DI0 [1:0], DI1 [1:0], DI2 [1:0], DI3 [1:0];                                                    // Input Data with 32 Byte File Size
    logic [31:0] DOut [3:0];                                                                                    // Output Data
    logic [31:0] BL [3:0];                                                                                      // Encryptor/Decryptor Block Output Data
    logic [31:0] Key [7:0];                                                                                     // Input Key
    logic [31:0] encmodein [3:0], decmodein [3:0];                                                              // Mux Inputs for encryptor/decryptor data inputs
    logic [31:0]  BlockIN [3:0], BlockOUT [3:0];                                                                // Data input/output for Encryptor/Decryptor Block
    logic enc_dec_in;                                                                                           // Encrption/Decryption Select Input for Block
    logic [31:0] xor1 [3:0], xor2 [3:0];                                                                        // Xor1 for CBC and Xor2 for Block Output XORing
    logic and1, or1, or2, or3;                                                                                  // Selects for muxes
    logic IVSel;
    logic [1:0] statebits;                                                                                                // Select Lines for Initial Vector Muxes
    logic DIn_WEN, Data_WEN, In1Reg_WEN, BlockReg_WEN, OutReg_WEN, Counter_WEN;   // Write Enables                                                                
    logic [127:0] CTR, CTRVal ;                                                                                 // Value from Counter and then its Sum with IV
    logic [31:0] mux1 [3:0], mux2 [3:0], mux3 [3:0], mux4 [3:0], mux5 [3:0], mux6 [3:0], mux7, mux8, mux9;
    logic AES_CF, AES_Valid, CLR, CK;
    logic [31:0] config_in, config_out;
    assign config_in = {{26'b0},KeySelect,ModeSelect,enc_dec};     

    assign BlockIN = config_out[0] ? encmodein : decmodein ;
    assign enc_dec_in = config_out[0] | config_out[3] | config_out[2] ;
    assign CTRVal = CTR + {IV[0],IV[1],IV[2],IV[3]};
    assign DataOut = {DOut[0], DOut[1], DOut[2], DOut[3]} ;
    
    assign xor1[0] = DI0[0] ^ (IVSel ? BL[0] : IV[0] );
    assign xor1[1] = DI1[0] ^ (IVSel ? BL[1] : IV[1] );
    assign xor1[2] = DI2[0] ^ (IVSel ? BL[2] : IV[2] );
    assign xor1[3] = DI3[0] ^ (IVSel ? BL[3] : IV[3] );
    assign xor2[0] = BL[0] ^ mux5[0];
    assign xor2[1] = BL[1] ^ mux5[1];
    assign xor2[2] = BL[2] ^ mux5[2];
    assign xor2[3] = BL[3] ^ mux5[3];
    
    assign mux1 = IVSel ? DOut : IV ;
    assign mux2 = IVSel ? BL : IV ;
    assign mux3[0] = IVSel ? DI0[0] : IV[0] ;
    assign mux3[1] = IVSel ? DI1[0] : IV[1] ;
    assign mux3[2] = IVSel ? DI2[0] : IV[2] ;
    assign mux3[3] = IVSel ? DI3[0] : IV[3] ;
    assign mux4[0] = IVSel ? DI0[1] : IV[0] ;
    assign mux4[1] = IVSel ? DI1[1] : IV[1] ;
    assign mux4[2] = IVSel ? DI2[1] : IV[2] ;
    assign mux4[3] = IVSel ? DI3[1] : IV[3] ;
    assign mux5[0] = or2 ? mux4[0] : DI0[0] ;
    assign mux5[1] = or2 ? mux4[1] : DI1[0] ;
    assign mux5[2] = or2 ? mux4[2] : DI2[0] ;
    assign mux5[3] = or2 ? mux4[3] : DI3[0] ;
    assign mux6 = or1 ? xor2 : BL ;
    
    assign and1 = (~config_out[0]) & config_out[1];
    assign or1 = and1 | config_out[2] | config_out[3] ;
    assign or2 = (~config_out[3]) & (~config_out[2]);
    assign or3 = config_out[5] | config_out[4] ;
    assign RF = AES_CF & statebits[1] & (~statebits[0]) ;
    
    mux5_1 m1_0 (.IN0(DI0[0]),.IN1(xor1[0]),.IN2(mux1[0]),.IN3(mux2[0]),.IN4(CTRVal[127:96]),.S5(config_out[3:1]),.Dout(encmodein[0]));
    mux5_1 m1_1 (.IN0(DI1[0]),.IN1(xor1[1]),.IN2(mux1[1]),.IN3(mux2[1]),.IN4(CTRVal[95:64]),.S5(config_out[3:1]),.Dout(encmodein[1]));
    mux5_1 m1_2 (.IN0(DI2[0]),.IN1(xor1[2]),.IN2(mux1[2]),.IN3(mux2[2]),.IN4(CTRVal[63:32]),.S5(config_out[3:1]),.Dout(encmodein[2]));
    mux5_1 m1_3 (.IN0(DI3[0]),.IN1(xor1[3]),.IN2(mux1[3]),.IN3(mux2[3]),.IN4(CTRVal[31:0]),.S5(config_out[3:1]),.Dout(encmodein[3]));
    
    mux5_1 m2_0 (.IN0(DI0[0]),.IN1(DI0[0]),.IN2(mux4[0]),.IN3(mux2[0]),.IN4(CTRVal[127:96]),.S5(config_out[3:1]),.Dout(decmodein[0]));
    mux5_1 m2_1 (.IN0(DI1[0]),.IN1(DI1[0]),.IN2(mux4[1]),.IN3(mux2[1]),.IN4(CTRVal[95:64]),.S5(config_out[3:1]),.Dout(decmodein[1]));
    mux5_1 m2_2 (.IN0(DI2[0]),.IN1(DI2[0]),.IN2(mux4[2]),.IN3(mux2[2]),.IN4(CTRVal[63:32]),.S5(config_out[3:1]),.Dout(decmodein[2]));
    mux5_1 m2_3 (.IN0(DI3[0]),.IN1(DI3[0]),.IN2(mux4[3]),.IN3(mux2[3]),.IN4(CTRVal[31:0]),.S5(config_out[3:1]),.Dout(decmodein[3]));
    
    Register iv0 (.Din(IVIn[127:96]),.reset(RST),.CLK(CLK),.Dout(IV[0]),.EN(Data_WEN));
    Register iv1 (.Din(IVIn[95:64]),.reset(RST),.CLK(CLK),.Dout(IV[1]),.EN(Data_WEN));
    Register iv2 (.Din(IVIn[63:32]),.reset(RST),.CLK(CLK),.Dout(IV[2]),.EN(Data_WEN));
    Register iv3 (.Din(IVIn[31:0]),.reset(RST),.CLK(CLK),.Dout(IV[3]),.EN(Data_WEN));
    
    Register di0_0 (.Din(DataIn[127:96]),.reset(RST),.CLK(CLK),.Dout(DI0[0]),.EN(DIn_WEN));
    Register di1_0 (.Din(DataIn[95:64]),.reset(RST),.CLK(CLK),.Dout(DI1[0]),.EN(DIn_WEN));
    Register di2_0 (.Din(DataIn[63:32]),.reset(RST),.CLK(CLK),.Dout(DI2[0]),.EN(DIn_WEN));
    Register di3_0 (.Din(DataIn[31:0]),.reset(RST),.CLK(CLK),.Dout(DI3[0]),.EN(DIn_WEN));
    Register di0_1 (.Din(DI0[0]),.reset(RST),.CLK(CLK),.Dout(DI0[1]),.EN(DIn1_WEN));
    Register di1_1 (.Din(DI1[0]),.reset(RST),.CLK(CLK),.Dout(DI1[1]),.EN(DIn1_WEN));
    Register di2_1 (.Din(DI2[0]),.reset(RST),.CLK(CLK),.Dout(DI2[1]),.EN(DIn1_WEN));
    Register di3_1 (.Din(DI3[0]),.reset(RST),.CLK(CLK),.Dout(DI3[1]),.EN(DIn1_WEN));
    
    Register do0 (.Din(mux6[0]),.reset(RST),.CLK(CLK),.Dout(DOut[0]),.EN(OutReg_WEN));
    Register do1 (.Din(mux6[1]),.reset(RST),.CLK(CLK),.Dout(DOut[1]),.EN(OutReg_WEN));
    Register do2 (.Din(mux6[2]),.reset(RST),.CLK(CLK),.Dout(DOut[2]),.EN(OutReg_WEN));
    Register do3 (.Din(mux6[3]),.reset(RST),.CLK(CLK),.Dout(DOut[3]),.EN(OutReg_WEN));
    
    Register bl0 (.Din(BlockOUT[0]),.reset(RST),.CLK(CLK),.Dout(BL[0]),.EN(BlockReg_WEN));
    Register bl1 (.Din(BlockOUT[1]),.reset(RST),.CLK(CLK),.Dout(BL[1]),.EN(BlockReg_WEN));
    Register bl2 (.Din(BlockOUT[2]),.reset(RST),.CLK(CLK),.Dout(BL[2]),.EN(BlockReg_WEN));
    Register bl3 (.Din(BlockOUT[3]),.reset(RST),.CLK(CLK),.Dout(BL[3]),.EN(BlockReg_WEN));
    
    Register key0 (.Din(KeyIn2[127:96]),.reset(RST),.CLK(CLK),.Dout(Key[0]),.EN(Data_WEN));
    Register key1 (.Din(KeyIn2[95:64]),.reset(RST),.CLK(CLK),.Dout(Key[1]),.EN(Data_WEN));
    Register key2 (.Din(KeyIn2[63:32]),.reset(RST),.CLK(CLK),.Dout(Key[2]),.EN(Data_WEN));
    Register key3 (.Din(KeyIn2[31:0]),.reset(RST),.CLK(CLK),.Dout(Key[3]),.EN(Data_WEN));
    Register key4 (.Din(KeyIn1[127:96]),.reset(RST),.CLK(CLK),.Dout(Key[4]),.EN(Data_WEN));
    Register key5 (.Din(KeyIn1[95:64]),.reset(RST),.CLK(CLK),.Dout(Key[5]),.EN(Data_WEN));
    Register key6 (.Din(KeyIn1[63:32]),.reset(RST),.CLK(CLK),.Dout(Key[6]),.EN(Data_WEN));
    Register key7 (.Din(KeyIn1[31:0]),.reset(RST),.CLK(CLK),.Dout(Key[7]),.EN(Data_WEN));

    Register config1 (.Din(config_in),.reset(RST),.CLK(CLK),.Dout(config_out),.EN(Data_WEN));

    
    Counter128 c1 (.RST(RST),.CLK(CLK),.EN(Counter_WEN),.CTR(CTR));
    IOM_CU cu1(.KeySelect(config_out[5:4]), .RST(RST), .CLK(CLK), .AES_CF(AES_CF), .AES_Valid(AES_Valid), .CLR(CLR), .CK(CK), .ModeSelect(config_out[3:1]), .OF(OF), .DIn1_WEN(DIn1_WEN),
    .IVSel(IVSel), .DIn_WEN(DIn_WEN), .In1Reg_WEN(In1Reg_WEN), .BlockReg_WEN(BlockReg_WEN), .OutReg_WEN(OutReg_WEN), .Counter_WEN(Counter_WEN), .Data_WEN(Data_WEN), .statebits(statebits));
    
    cipher_unit a1(.CLK(CLK), .state_i(BlockIN), .KL(config_out[5:4]), .KEY(Key),.CF(AES_CF), .Valid(AES_Valid),.state_o(BlockOUT), .enc_dec(enc_dec_in), .CLR(CLR) ,.CK(CK));
    
endmodule
