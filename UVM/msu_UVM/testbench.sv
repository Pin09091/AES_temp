// =============================================================================
// File        : testbench.sv  (top-level for EDA Playground / Synopsys VCS)
// Description : Top module that instantiates the DUT, interface, and
//               kicks off the UVM test selected by +UVM_TESTNAME=<name>.
//
// ---- EDA Playground setup (Synopsys VCS) ------------------------------------
//
// Simulator  : Synopsys VCS (select "Synopsys VCS" in the simulator drop-down)
// UVM        : UVM 1.2
//
// Design box (design.sv):
//   Paste design.sv — it `include-s all RTL files.
//   Upload all RTL .sv files in the file panel:
//     aes.sv, ARK.sv, BS.sv, ByteSub.sv, CU_S.sv, dem1_11.sv, dem1_8.sv,
//     dem1_9.sv, demux1_11.sv, GFunc.sv, HFunc.sv, Inv_S_Box.sv, KEXP.sv,
//     MC.sv, MixColumn.sv, mux15_1.sv, mux3_1.sv, RS.sv, S_Box.sv, State.sv,
//     Xtime.sv, Register.sv, Counter128.sv, mux5_1.sv, IOM_CU.sv,
//     mode_selection_unit.sv
//
// Testbench box (testbench.sv):
//   Paste this file — all UVM .sv files are `include-d below.
//   Upload all UVM .sv files in the file panel:
//     msu_if.sv, msu_transaction.sv, msu_monitor.sv, msu_driver.sv,
//     msu_agent.sv, msu_scoreboard.sv, msu_coverage.sv, msu_sequences.sv,
//     msu_env.sv, msu_tests.sv
//
// C file box:
//   Paste reference.c — VCS compiles and links it automatically when a
//   C file is present in EDA Playground.
//
// Compile Options:
//   -timescale=1ns/1ns +vcs+flush+all -sverilog -CFLAGS "-DVCS"
//
// Run Options:
//   +UVM_TESTNAME=all_tests +UVM_VERBOSITY=UVM_MEDIUM
//
//   Individual tests:
//     +UVM_TESTNAME=tc_001   (ECB AES-128 Encrypt)
//     +UVM_TESTNAME=tc_002   (ECB AES-192 Encrypt)
//     +UVM_TESTNAME=tc_003   (ECB AES-256 Encrypt)
//     +UVM_TESTNAME=tc_004   (ECB AES-128 Decrypt)
//     +UVM_TESTNAME=tc_005   (ECB AES-192 Decrypt)
//     +UVM_TESTNAME=tc_006   (ECB AES-256 Decrypt)
//     +UVM_TESTNAME=tc_007   (CBC AES-128 Encrypt)
//     +UVM_TESTNAME=tc_008   (CBC AES-192 Encrypt)
//     +UVM_TESTNAME=tc_009   (CBC AES-256 Encrypt)
//     +UVM_TESTNAME=tc_010   (CBC AES-128 Decrypt)
//     +UVM_TESTNAME=tc_011   (OFB AES-256 Enc+Dec)
//     +UVM_TESTNAME=tc_012   (CFB AES-128 Enc+Dec)
//     +UVM_TESTNAME=tc_013   (CTR AES-256/192)
//     +UVM_TESTNAME=tc_014   (Random stress)
//
// Default test : all_tests  (runs TC_001–TC_014 in order)
// =============================================================================

`timescale 1ns/1ns

`include "uvm_macros.svh"
import uvm_pkg::*;

// ---- Include order: interface first, then item, then components, then tests --
`include "msu_if.sv"
`include "msu_transaction.sv"
`include "msu_monitor.sv"
`include "msu_driver.sv"
`include "msu_agent.sv"
`include "msu_scoreboard.sv"
`include "msu_coverage.sv"
`include "msu_sequences.sv"
`include "msu_env.sv"
`include "msu_tests.sv"

module top;

    // ---- Clock generation ---------------------------------------------------
    logic clk = 1'b0;
    always #10 clk = ~clk;    // 50 MHz  (change period here if needed)

    // ---- Interface instantiation --------------------------------------------
    msu_if dut_if (clk);

    // ---- DUT instantiation --------------------------------------------------
    mode_selection_unit dut (
        .DataIn     (dut_if.DataIn),
        .KeyIn1     (dut_if.KeyIn1),
        .KeyIn2     (dut_if.KeyIn2),
        .IVIn       (dut_if.IVIn),
        .ModeSelect (dut_if.ModeSelect),
        .KeySelect  (dut_if.KeySelect),
        .RST        (dut_if.RST),
        .CLK        (clk),
        .enc_dec    (dut_if.enc_dec),
        .DataOut    (dut_if.DataOut),
        .OF         (dut_if.OF),
        .RF         (dut_if.RF)
    );

    // ---- UVM startup --------------------------------------------------------
    initial begin
        // Make virtual interface available to every component in the hierarchy
        uvm_config_db #(virtual msu_if)::set(null, "*", "msu_if", dut_if);

        // Initialise handshake bits to safe defaults
        dut_if.driver_started = 1'b0;
        dut_if.input_taken    = 1'b0;

        // Run — test name selected via +UVM_TESTNAME= on the command line
        // If not supplied, default is "all_tests"
        run_test("all_tests");
    end

    // ---- Waveform dump ------------------------------------------------------
    initial begin
        $dumpfile("msu_tb.vcd");
        $dumpvars(0, top);
    end

    // ---- Simulation timeout -------------------------------------------------
    initial begin
        #10_000_000;   // 10 ms at 50 MHz — generous for AES multi-round
        `uvm_fatal("TIMEOUT", "Simulation exceeded 10 ms — check for hung FSM")
    end

endmodule : top
