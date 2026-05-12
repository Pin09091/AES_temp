`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2025 11:35:56 AM
// Design Name: 
// Module Name: ByteSub
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


module ByteSub(
input logic [7:0] A,    //Input Byte
input enc_dec,          //Encryption/Decryption Selector
output logic [7:0] B    //Output Byte
    );
    logic [7:0] b_enc, b_dec;
    S_Box S1 (A,b_enc);     // Pass Byte through S-Box
    Inv_S_Box I1 (A,b_dec);    // Pass Byte through Inverse S-Box
    assign B = enc_dec ? b_enc : b_dec ; // Choose Output Byte based on Encrypt/Decrypt Select
    
   
endmodule