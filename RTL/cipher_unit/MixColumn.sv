`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2025 02:44:07 PM
// Design Name: 
// Module Name: MixColumn
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


module MixColumn(
input logic [31:0] A,   // Input Column
input enc_dec,          // Encryption/Decryption Selector
output logic [31:0] B   // Output Column
    );
    logic [7:0] x [3:0];                    // x = inputs
    logic [7:0] x2 [3:0];                   // x2 = Xtime(x)
    logic [7:0] x4 [3:0];                   // x4 = Xtime(x4)
    logic [7:0] x8 [3:0];                   // x8 = Xtime(x8)
    logic [7:0] b_enc [3:0], b_dec [3:0];   // Outputs for Encryption/Decryption
    
    assign x[0] = A [31:24];
    assign x[1] = A [23:16];
    assign x[2] = A [15:8];
    assign x[3] = A [7:0];
    Xtime x2_0 (x[0],x2[0]);    // x2[0] = Xtime(x[0])
    Xtime x2_1 (x[1],x2[1]);    // x2[1] = Xtime(x[0])
    Xtime x2_2 (x[2],x2[2]);    // x2[2] = Xtime(x[0])
    Xtime x2_3 (x[3],x2[3]);    // x2[3] = Xtime(x[0])
    Xtime x4_0 (x2[0],x4[0]);   // x4[0] = Xtime(x2[0])
    Xtime x4_1 (x2[1],x4[1]);   // x4[1] = Xtime(x2[1])
    Xtime x4_2 (x2[2],x4[2]);   // x4[2] = Xtime(x2[2])
    Xtime x4_3 (x2[3],x4[3]);   // x4[3] = Xtime(x2[3])
    Xtime x8_0 (x4[0],x8[0]);   // x8[0] = Xtime(x4[0])
    Xtime x8_1 (x4[1],x8[1]);   // x8[1] = Xtime(x4[1])
    Xtime x8_2 (x4[2],x8[2]);   // x8[2] = Xtime(x4[2])
    Xtime x8_3 (x4[3],x8[3]);   // x8[3] = Xtime(x4[3])
    
    assign b_enc [0] = (x2[0]) ^ (x2[1] ^ x[1]) ^ (x[2]) ^ (x[3]) ; // b_enc[0] = 2.a0 ? 3.a1 ? 1.a2 ? 1.a3
    assign b_enc [1] = (x[0]) ^ (x2[1]) ^ (x2[2] ^ x[2]) ^ (x[3]) ; // b_enc[1] = 1.a0 ? 2.a1 ? 3.a2 ? 1.a3
    assign b_enc [2] = (x[0]) ^ (x[1]) ^ (x2[2]) ^ (x2[3] ^ x[3]) ; // b_enc[2] = 1.a0 ? 1.a1 ? 2.a2 ? 3.a3
    assign b_enc [3] = (x2[0] ^ x[0]) ^ (x[1]) ^ (x[2]) ^ (x2[3]) ; // b_enc[3] = 3.a0 ? 1.a1 ? 1.a2 ? 2.a3
    
    assign b_dec [0] = (x8[0] ^ x4[0] ^ x2[0]) ^ (x8[1] ^ x2[1] ^ x[1]) ^ (x8[2] ^ x4[2] ^ x[2]) ^ (x8[3] ^ x[3]) ; // b_dec[0] = E.a0 ? B.a1 ? D.a2 ? 9.a3
    assign b_dec [1] = (x8[0] ^ x[0]) ^ (x8[1] ^ x4[1] ^ x2[1]) ^ (x8[2] ^ x2[2] ^ x[2]) ^ (x8[3] ^ x4[3] ^ x[3]) ; // b_dec[1] = 9.a0 ? E.a1 ? B.a2 ? D.a3
    assign b_dec [2] = (x8[0] ^ x4[0] ^ x[0]) ^ (x8[1] ^ x[1]) ^ (x8[2] ^ x4[2] ^ x2[2]) ^ (x8[3] ^ x2[3] ^ x[3]) ; // b_dec[2] = D.a0 ? 9.a1 ? E.a2 ? B.a3
    assign b_dec [3] = (x8[0] ^ x2[0] ^ x[0]) ^ (x8[1] ^ x4[1] ^ x[1]) ^ (x8[2] ^ x[2]) ^ (x8[3] ^ x4[3] ^ x2[3]) ; // b_dec[3] = B.a0 ? D.a1 ? 9.a2 ? E.a3
    
    assign B = enc_dec ? {b_enc[0],b_enc[1],b_enc[2],b_enc[3]} : {b_dec[0],b_dec[1],b_dec[2],b_dec[3]} ;
    
    
endmodule