// =============================================================================
// File        : testbench.sv  (top-level for EDA Playground / Synopsys VCS)
// Description : Top module for the AvalonMM_MSU UVM environment.
//
// ---- EDA Playground setup (Synopsys VCS) ------------------------------------
//
// Simulator  : Synopsys VCS
// UVM        : UVM 1.2
//
// Design box (design.sv):
//   Paste or upload Avalon-MM.sv as the design file.
//   No other RTL files are needed — AvalonMM_MSU is self-contained.
//
// Testbench box (testbench.sv):
//   Paste this file.  All UVM .sv files must be uploaded to the file panel:
//     avalon_if.sv
//     avalon_transaction.sv
//     avalon_driver.sv
//     avalon_monitor.sv
//     avalon_scoreboard.sv
//     avalon_coverage.sv
//     avalon_agent.sv
//     avalon_env.sv
//     avalon_sequences.sv
//     avalon_tests.sv
//
// Compile Options:
//   -timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog
//
// Run Options:
//   +UVM_TESTNAME=all_tests +UVM_VERBOSITY=UVM_MEDIUM
//
//   Individual tests:
//     +UVM_TESTNAME=tc_001   (Reset & Idle)
//     +UVM_TESTNAME=tc_002   (Write all registers)
//     +UVM_TESTNAME=tc_003   (Read Status register)
//     +UVM_TESTNAME=tc_004   (Full ECB AES-128 Encrypt)
//     +UVM_TESTNAME=tc_005   (Error state — simultaneous R+W)
//     +UVM_TESTNAME=tc_006   (All ModeSelect values)
//     +UVM_TESTNAME=tc_007   (All KeySelect values)
//     +UVM_TESTNAME=tc_008   (Invalid address write)
//     +UVM_TESTNAME=tc_009   (Back-to-back writes)
//     +UVM_TESTNAME=tc_010   (Randomised stress)
//
// Default test : all_tests (TC-001 through TC-010 in sequence)
// =============================================================================

`timescale 1ns/1ns

`include "uvm_macros.svh"
import uvm_pkg::*;

// ---- Include order: interface first, then item, then components, then tests --
`include "avalon_if.sv"
`include "avalon_transaction.sv"
`include "avalon_driver.sv"
`include "avalon_monitor.sv"
`include "avalon_scoreboard.sv"
`include "avalon_coverage.sv"
`include "avalon_agent.sv"
`include "avalon_env.sv"
`include "avalon_sequences.sv"
`include "avalon_tests.sv"

module top;

    // ---- Clock generation ---------------------------------------------------
    logic clk = 1'b0;
    always #5 clk = ~clk;    // 100 MHz (10 ns period)

    // ---- Interface instantiation --------------------------------------------
    avalon_if dut_if (clk);

    // ---- DUT instantiation --------------------------------------------------
    AvalonMM_MSU dut (
        .CLK             (clk),
        .RST             (dut_if.RST),

        // Avalon-MM host side
        .writedata_h     (dut_if.writedata_h),
        .address_h       (dut_if.address_h),
        .write_h         (dut_if.write_h),
        .read_h          (dut_if.read_h),
        .readdata_h      (dut_if.readdata_h),
        .waitrequest_h   (dut_if.waitrequest_h),
        .readdatavalid_h (dut_if.readdatavalid_h),
        .error           (dut_if.error),

        // MSU sideband outputs (observed)
        .DataIn          (dut_if.DataIn),
        .KeyIn1          (dut_if.KeyIn1),
        .KeyIn2          (dut_if.KeyIn2),
        .IVIn            (dut_if.IVIn),
        .ModeSelect      (dut_if.ModeSelect),
        .KeySelect       (dut_if.KeySelect),
        .Enable_MSU      (dut_if.Enable_MSU),
        .RST_MSU         (dut_if.RST_MSU),
        .enc_dec         (dut_if.enc_dec),

        // MSU sideband inputs (stub driven by driver)
        .OF              (dut_if.OF),
        .RF              (dut_if.RF),
        .DataOut         (dut_if.DataOut)
    );

    // ---- UVM startup --------------------------------------------------------
    initial begin
        uvm_config_db #(virtual avalon_if)::set(null, "*", "avalon_if", dut_if);
        run_test("all_tests");  // overridden by +UVM_TESTNAME= at runtime
    end

    // ---- Waveform dump ------------------------------------------------------
    initial begin
        $dumpfile("avalon_msu_tb.vcd");
        $dumpvars(0, top);
    end

    // ---- Simulation timeout -------------------------------------------------
    initial begin
        #5_000_000;  // 5 ms at 100 MHz — generous for all test cases
        `uvm_fatal("TIMEOUT", "Simulation exceeded 5 ms — check for hung FSM or sequence")
    end

endmodule : top