`timescale 1ns / 1ps
// =============================================================================
// Module: MC (MixColumns)
// Description:
//   Applies the AES MixColumns (or InvMixColumns for decryption) transformation
//   to all four columns of the 128-bit AES state.
//
//   The state is stored as four 32-bit words, where each word corresponds to
//   one column of the 4×4 byte matrix. Each column is independently processed
//   by a MixColumn instance, which performs GF(2^8) matrix multiplication as
//   defined in the AES specification (FIPS 197).
//
// Inputs:
//   state_i [3:0] - 4-element array of 32-bit words (one word = one column)
//   enc_dec       - 1 = encryption (MixColumns), 0 = decryption (InvMixColumns)
//
// Outputs:
//   state_o [3:0] - 4-element array of 32-bit words after column mixing
//
// Dependencies: MixColumn
// =============================================================================


module MC(
input logic [31:0] state_i [3:0],   // State Input
input enc_dec,                      // Encryption/Decryption Selector
output logic [31:0] state_o [3:0]   // Output State

);

MixColumn m1(.A(state_i[3]), .enc_dec(enc_dec), .B(state_o[3])); // Column 1
MixColumn m2(.A(state_i[2]), .enc_dec(enc_dec), .B(state_o[2])); // Column 2
MixColumn m3(.A(state_i[1]), .enc_dec(enc_dec), .B(state_o[1])); // Column 3
MixColumn m4(.A(state_i[0]), .enc_dec(enc_dec), .B(state_o[0])); // Column 4

endmodule