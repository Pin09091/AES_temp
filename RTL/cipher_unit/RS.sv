`timescale 1ns / 1ps
// =============================================================================
// Module: RS (RowShift / ShiftRows)
// Description:
//   Performs the AES ShiftRows (encryption) or InvShiftRows (decryption)
//   transformation on the 128-bit state.
//
//   The AES state is a 4×4 byte matrix.  Here it is stored as four 32-bit
//   words (columns), where each word's byte fields map to matrix rows:
//     bits [31:24] = row 0  (no shift in either direction)
//     bits [23:16] = row 1  (cyclic left-shift by 1 for encryption,
//                            cyclic right-shift by 1 for decryption)
//     bits [15: 8] = row 2  (cyclic left/right shift by 2 - same in both directions)
//     bits [ 7: 0] = row 3  (cyclic left-shift by 3 for encryption,
//                            cyclic right-shift by 3 for decryption)
//
//   enc_dec selects the shift direction:
//     enc_dec = 1 ? ShiftRows    (shift left:  rows 1,2,3 shift by 1,2,3)
//     enc_dec = 0 ? InvShiftRows (shift right: rows 1,2,3 shift by 3,2,1)
//
// Inputs:
//   state_i [3:0] - 4-element array of 32-bit words (columns of AES state)
//   enc_dec       - 1 = ShiftRows (encryption), 0 = InvShiftRows (decryption)
//
// Outputs:
//   state_o [3:0] - 4-element array of 32-bit words after row shifting
//
// Dependencies: None
// =============================================================================


module RS(
input logic [31:0] state_i [3:0],   // State Input
input enc_dec,                      // Encryption/Decryption Selector
output logic [31:0] state_o [3:0]  // Output State
    );

    // Shifting Rows for encryption and decryption
    // No Shift
    assign state_o [3][31:24] = state_i [3][31:24]; 
    assign state_o [2][31:24] = state_i [2][31:24];
    assign state_o [1][31:24] = state_i [1][31:24];
    assign state_o [0][31:24] = state_i [0][31:24];
    // Left or Right Shift once
    assign state_o [3][23:16] = enc_dec ? state_i [0][23:16] : state_i [2][23:16] ;
    assign state_o [2][23:16] = enc_dec ? state_i [3][23:16] : state_i [1][23:16] ;
    assign state_o [1][23:16] = enc_dec ? state_i [2][23:16] : state_i [0][23:16] ;
    assign state_o [0][23:16] = enc_dec ? state_i [1][23:16] : state_i [3][23:16] ;
    // Left or Right Shift twice
    assign state_o [3][15:8] = state_i [1][15:8];  
    assign state_o [2][15:8] = state_i [0][15:8];
    assign state_o [1][15:8] = state_i [3][15:8]; 
    assign state_o [0][15:8] = state_i [2][15:8];
    // Left or Right Shift thrice
    assign state_o [3][7:0] = enc_dec ? state_i [2][7:0] : state_i [0][7:0] ;
    assign state_o [2][7:0] = enc_dec ? state_i [1][7:0] : state_i [3][7:0] ;
    assign state_o [1][7:0] = enc_dec ? state_i [0][7:0] : state_i [2][7:0] ;
    assign state_o [0][7:0] = enc_dec ? state_i [3][7:0] : state_i [1][7:0] ;
endmodule