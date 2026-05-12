// =============================================================================
// File        : testbench.sv  (top-level for EDA Playground / Synopsys VCS)
// Description : Top module that instantiates the DUT, interface, and
//               kicks off the UVM test selected by +UVM_TESTNAME=<name>.
//
// ---- EDA Playground setup (Synopsys VCS) -----------------------------------
//
// Simulator  : Synopsys VCS 2025.06  (or later)
// UVM        : UVM 1.2
//
// Design box (design.sv):
//   Paste design.sv — it includes all RTL files via `include.
//   Upload all cipher_unit RTL .sv files in the file panel.
//
// Testbench box (testbench.sv):
//   Paste this file — all UVM files are `include-d below.
//   Upload all UVM .sv files in the file panel.
//
// C file box:
//   Paste reference.c — VCS compiles and links it automatically
//   when a C file is present in EDA Playground.
//
// Compile Options:
//   -timescale=1ns/1ns +vcs+flush+all -sverilog -CFLAGS "-DVCS"
//
// Run Options:
//   +UVM_TESTNAME=all_tests +UVM_VERBOSITY=UVM_MEDIUM
//   (replace all_tests with tc_001 .. tc_013 for individual tests)
//
// Default test : all_tests  (runs TC_001..TC_013 in order)
// =============================================================================

`timescale 1ns/1ns

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "interface.sv"
`include "cipher_transaction.sv"
`include "cipher_monitor.sv"
`include "cipher_driver.sv"
`include "cipher_agent.sv"
`include "cipher_scoreboard.sv"
`include "cipher_coverage.sv"
`include "cipher_sequences.sv"
`include "cipher_env.sv"
`include "cipher_tests.sv"

module top;

  // ---- Clock generation --------------------------------------------------
  logic clk = 1'b0;
  always #20 clk = ~clk;   // 25 MHz — change period here if needed

  // ---- Interface instantiation -------------------------------------------
  cipher_unit_interface cui (clk);

  // ---- DUT instantiation -------------------------------------------------
  cipher_unit dut (cui.dut);

  // ---- UVM startup -------------------------------------------------------
  initial begin
    // Make the virtual interface available to every component in the hierarchy
    uvm_config_db #(virtual cipher_unit_interface)::set(
      null, "*", "cipher_unit_interface", cui);

    // Initialise the handshake bits to a safe default
    cui.driver_started = 1'b0;
    cui.input_taken    = 1'b0;

    // Run — test name is selected via +UVM_TESTNAME= on the command line
    // If not supplied, default is "all_tests"
    run_test("all_tests");
  end

endmodule : top
