`timescale 1ns/1ns
// =============================================================================
// File        : design.sv  (EDA Playground design box entry point)
// Description : Includes all RTL files and defines the cipher_unit module
//               using the cipher_unit_interface modport.
//
// IMPORTANT — EDA Playground / Xcelium setup:
//   1. Paste THIS file into the "design.sv" box.
//   2. All other .sv RTL files (ARK, BS, ByteSub, CU_S, etc.) must be
//      uploaded as additional files or included via the file manager.
//   3. reference.c must be compiled as a DPI-C shared library.
//      In Xcelium use:  -sv_lib reference  (after compiling reference.c)
//      EDA Playground: paste reference.c into the "C/C++ file" box.
// =============================================================================

// RTL submodule includes
`include "ARK.sv"
`include "BS.sv"
`include "ByteSub.sv"
`include "CU_S.sv"
`include "dem1_8.sv"
`include "dem1_9.sv"
`include "dem1_11.sv"
`include "demux1_11.sv"
`include "GFunc.sv"
`include "HFunc.sv"
`include "Inv_S_Box.sv"
`include "KEXP.sv"
`include "MC.sv"
`include "MixColumn.sv"
`include "mux3_1.sv"
`include "mux15_1.sv"
`include "Register.sv"
`include "RS.sv"
`include "S_Box.sv"
`include "State.sv"
`include "Xtime.sv"

// =============================================================================
// cipher_unit — top-level RTL module
// =============================================================================
module cipher_unit (
  cipher_unit_interface.dut cui
);

  // ---- Internal signals ---------------------------------------------------
  logic [31:0] Rk[3:0];
  logic [3:0]  R;
  logic        SCLR;
  logic        SE;
  logic        KF;

  logic        mux0, mux1, mux3, mux4, mux5, mux6;
  logic [1:0]  mux2;

  logic [31:0] state_i0[3:0];  // State register I/O
  logic [31:0] state_o0[3:0];
  logic [31:0] state_i1[3:0];  // ByteSub I/O
  logic [31:0] state_o1[3:0];
  logic [31:0] state_i2[3:0];  // RowShift I/O
  logic [31:0] state_o2[3:0];
  logic [31:0] state_i3[3:0];  // MixColumn I/O
  logic [31:0] state_o3[3:0];
  logic [31:0] state_i4[3:0];  // AddRoundKey I/O
  logic [31:0] state_o4[3:0];

  // ---- KL change detection — auto hard-reset if KL changes mid-operation --
  logic [1:0] PREV_KL;
  logic       CLR_S, CLR_H;

  always_ff @(negedge cui.CLK)
    PREV_KL <= cui.KL;

  always_comb begin
    if (cui.KL != PREV_KL) begin
      CLR_S = 1'b1;
      CLR_H = 1'b1;
    end else begin
      CLR_S = cui.CLR;
      CLR_H = cui.CK;
    end
  end

  // ---- Sub-module instantiations -----------------------------------------
  CU_S s (
    .CLK    (cui.CLK),
    .CLR    (CLR_S),
    .enc_dec(cui.enc_dec),
    .KL     (cui.KL),
    .KF     (KF),
    .mux0   (mux0),
    .mux1   (mux1),
    .mux2   (mux2),
    .mux3   (mux3),
    .mux4   (mux4),
    .mux5   (mux5),
    .mux6   (mux6),
    .SE     (SE),
    .SCLR   (SCLR),
    .Valid  (cui.Valid),
    .CF     (cui.CF),
    .R      (R)
  );

  KEXP kexp (
    .CLK (cui.CLK),
    .R   (R),
    .KL  (cui.KL),
    .KEY (cui.KEY),
    .Rk  (Rk),
    .CLR (CLR_H),
    .KF  (KF)
  );

  State Si (
    .CLK    (cui.CLK),
    .enable (SE),
    .CLR    (SCLR),
    .state_i(state_i0),
    .state_o(state_o0)
  );

  assign cui.state_o = state_o0;

  BS Bs (
    .state_i(state_i1),
    .enc_dec(cui.enc_dec),
    .state_o(state_o1)
  );

  RS Rs (
    .state_i(state_i2),
    .enc_dec(cui.enc_dec),
    .state_o(state_o2)
  );

  MC Mc (
    .state_i(state_i3),
    .enc_dec(cui.enc_dec),
    .state_o(state_o3)
  );

  ARK Ark (
    .state_i(state_i4),
    .Rk     (Rk),
    .state_o(state_o4)
  );

  // ---- Datapath mux network ----------------------------------------------
  always_comb begin
    // Into ByteSub
    state_i1 = mux1 ? state_o0 : state_o2;

    // Into RowShift (3-way mux)
    state_i2 = mux2[1] ? state_o3 : (mux2[0] ? state_o1 : state_o4);

    // Into MixColumn
    state_i3 = mux3 ? state_o2 : state_o4;

    // Into AddRoundKey
    case (mux4)
      1'b0: state_i4 = mux6 ? state_o2 : state_o3;
      1'b1: state_i4 = state_o0;
    endcase

    // Into State register
    case (mux5)
      1'b0: state_i0 = mux0 ? cui.state_i : state_o1;  // decryption path
      1'b1: state_i0 = mux0 ? cui.state_i : state_o4;  // encryption path
    endcase
  end

endmodule : cipher_unit
