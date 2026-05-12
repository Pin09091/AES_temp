// =============================================================================
// File        : msu_if.sv
// Description : SystemVerilog interface for the mode_selection_unit DUT.
//               Follows the same single-modport pattern used in the
//               cipher_unit UVM environment.
// =============================================================================
`ifndef MSU_IF_SV
`define MSU_IF_SV

interface msu_if (input logic CLK);

    // ---- DUT stimulus ports ----
    logic [127:0] DataIn;
    logic [127:0] KeyIn1;    // upper 128b — used for AES-192 / AES-256
    logic [127:0] KeyIn2;    // lower 128b — always used
    logic [127:0] IVIn;      // Initialisation Vector
    logic [2:0]   ModeSelect; // 000=ECB 001=CBC 010=OFB 011=CFB 100=CTR
    logic [1:0]   KeySelect;  // 00=AES-128  01=AES-192  10=AES-256
    logic         RST;
    logic         enc_dec;    // 1 = encrypt, 0 = decrypt

    // ---- DUT response ports ----
    logic [127:0] DataOut;
    logic         OF;         // Output Flag — pulses when result is ready
    logic         RF;         // Read Flag

    // ---- Handshake helpers (used by driver / monitor) ----
    bit driver_started;
    bit input_taken;

    modport tb (
        input  CLK,
        output DataIn, KeyIn1, KeyIn2, IVIn, ModeSelect, KeySelect, RST, enc_dec,
        input  DataOut, OF, RF
    );

    modport dut (
        input  CLK, DataIn, KeyIn1, KeyIn2, IVIn, ModeSelect, KeySelect, RST, enc_dec,
        output DataOut, OF, RF
    );

endinterface : msu_if

`endif // MSU_IF_SV
