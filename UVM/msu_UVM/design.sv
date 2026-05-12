// =============================================================================
// File        : design.sv
// Description : Top-level RTL include file for EDA Playground.
//               Upload all RTL files listed below into the file panel,
//               then paste this file into the "Design" box.
//
// Files to upload (RTL panel):
//   From cipher_unit.zip:
//     ARK.sv  BS.sv  ByteSub.sv  CU_S.sv  dem1_11.sv  dem1_8.sv  dem1_9.sv
//     demux1_11.sv  GFunc.sv  HFunc.sv  Inv_S_Box.sv  KEXP.sv  MC.sv
//     MixColumn.sv  mux15_1.sv  mux3_1.sv  RS.sv  S_Box.sv  State.sv
//     Xtime.sv  aes.sv
//     NOTE: cipher_unit/Register.sv — rename to cipher_Register.sv to
//           avoid conflict with the top-level Register.sv
//
//   From the MSU source files:
//     Register.sv  Counter128.sv  mux5_1.sv  IOM_CU.sv  mode_selection_unit.sv
// =============================================================================

`timescale 1ns/1ns

// ---- cipher_unit sub-modules -----------------------------------------------
`include "Xtime.sv"
`include "S_Box.sv"
`include "Inv_S_Box.sv"
`include "ByteSub.sv"
`include "GFunc.sv"
`include "HFunc.sv"
`include "KEXP.sv"
`include "ARK.sv"
`include "RS.sv"
`include "MC.sv"
`include "MixColumn.sv"
`include "BS.sv"
`include "mux3_1.sv"
`include "mux15_1.sv"
`include "dem1_8.sv"
`include "dem1_9.sv"
`include "dem1_11.sv"
`include "demux1_11.sv"
`include "State.sv"
`include "CU_S.sv"
`include "aes.sv"           // cipher_unit top (module name: cipher_unit)

// ---- mode_selection_unit sub-modules ----------------------------------------
// IMPORTANT: cipher_unit already defines a Register module.
//            The MSU-level Register is identical — VCS will use the first
//            definition encountered, so no rename is needed as long as
//            cipher_Register.sv is included BEFORE Register.sv.
//            If VCS complains about duplicate module names, rename one of them.
`include "Register.sv"      // MSU-level 32-bit register
`include "Counter128.sv"
`include "mux5_1.sv"
`include "IOM_CU.sv"
`include "mode_selection_unit.sv"
