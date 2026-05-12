`timescale 1ns / 1ps
// =============================================================================
// Module: State
// Description:
//   A 128-bit state register that holds the intermediate AES cipher state
//   across rounds. It consists of four 32-bit word registers updated together.
//
//   Behaviour:
//     - On CLR (synchronous): all four output words are cleared to zero
//       on the next rising clock edge.
//     - When enable is asserted (without CLR): all four output words are
//       updated to the corresponding input words on the next rising clock edge.
//     - When neither CLR nor enable is asserted: the register retains its
//       current value.
//
//   Note: CLR and enable are both evaluated at the positive clock edge.
//   If both are simultaneously asserted, CLR takes effect first (see code).
//
// Inputs:
//   CLK     - System clock (positive-edge triggered)
//   enable  - Write enable: 1 = capture state_i into state_o on next CLK edge
//   CLR     - Synchronous clear: 1 = set all outputs to zero on next CLK edge
//   state_i - 4-element array of 32-bit words representing the new AES state
//
// Outputs:
//   state_o - 4-element array of 32-bit words representing the stored AES state
//
// Dependencies: None
// =============================================================================



module State(
input logic CLK,enable,CLR,             // Clock and Write Enable
input logic [31:0] state_i [3:0],   // State Input
output logic [31:0] state_o [3:0]   // State Output
    );
    
    always_ff@(posedge CLK)
    begin
        if(CLR)
            begin    // Only write when Enable is High
                state_o [0]= 0;
                state_o [1]= 0;
                state_o [2]= 0;
                state_o [3]= 0;
            end
        if(enable)
            begin    // Only write when Enable is High
                state_o <= state_i; // Write input to output
            end
                    
    end
endmodule
