`timescale 1ns / 1ps
// =============================================================================
// Module: ARK (AddRoundKey)
// Description:
//   Performs the AES AddRoundKey step. Each 32-bit word (row) of the 4x4 state
//   matrix is XOR'd with the corresponding word of the current round key.
//
//   This is the only AES step that directly uses the key material, and it is
//   applied both at the start (whitening) and at the end of every round.
//
// Parameters:
//   None
//
// Inputs:
//   state_i [3:0] - 4-element array of 32-bit words representing the AES state
//   Rk      [3:0] - 4-element array of 32-bit words representing the round key
//
// Outputs:
//   state_o [3:0] - 4-element array of 32-bit words after XOR with round key
//
// Dependencies: None
// =============================================================================

module ARK(
input logic [31:0] state_i [3:0], Rk [3:0], // State Input and Round Key
output logic [31:0] state_o [3:0]           // State Output
    );
    
    // Bitwise XOR between each row of Round Key and State
    assign state_o[0] = state_i[0] ^ Rk[0]; // Row1
    assign state_o[1] = state_i[1] ^ Rk[1]; // Row2
    assign state_o[2] = state_i[2] ^ Rk[2]; // Row3
    assign state_o[3] = state_i[3] ^ Rk[3]; // Row4
    
endmodule
