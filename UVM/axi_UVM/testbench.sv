`timescale 1ns/1ps

// ============================================================================
// UVM Top-level testbench for AXI_main
//
// The DUT is AXI_main, which is instantiated as a standalone module.
// interface_toggle is driven via the AXI interface (set to 1 = AXI mode)
// to match the AES top-level wrapper used in top_tb.sv.
//
// Clock: 25 MHz (40 ns period) matching top_tb's AXI clock.
// ============================================================================
`include "axi_if.sv"          // ← must be first so the type is defined

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // -----------------------------------------------------------------------
    // Include order: item -> driver/monitor/sb -> agent -> seq -> cov -> env -> tests
    // -----------------------------------------------------------------------
    `include "axi_seq_item.sv"
    `include "axi_driver.sv"
    `include "axi_monitor.sv"
    `include "axi_scoreboard.sv"
    `include "axi_agent.sv"
    `include "axi_sequences.sv"
    `include "axi_coverage.sv"
    `include "axi_env.sv"
    `include "axi_tests.sv"

    // -----------------------------------------------------------------------
    // Clock: 25 MHz (period = 40 ns) to match top_tb.sv `always #20`
    // -----------------------------------------------------------------------
    logic clk;
    initial clk = 0;
    always #20 clk = ~clk;

    // -----------------------------------------------------------------------
    // Interface
    // -----------------------------------------------------------------------
    axi_if dut_if(.clk(clk));

    // -----------------------------------------------------------------------
    // DUT: AXI_main (standalone, not wrapped in AES)
    // -----------------------------------------------------------------------
    AXI_main dut (
        .S_AXI_ACLK    (clk),
        .S_AXI_ARESETn (dut_if.ARESETn),

        .S_AXI_AWVALID (dut_if.AWVALID),
        .S_AXI_AWREADY (dut_if.AWREADY),
        .S_AXI_AWADDR  (dut_if.AWADDR),

        .S_AXI_WVALID  (dut_if.WVALID),
        .S_AXI_WREADY  (dut_if.WREADY),
        .S_AXI_WSTRB   (dut_if.WSTRB),
        .S_AXI_WDATA   (dut_if.WDATA),

        .S_AXI_BVALID  (dut_if.BVALID),
        .S_AXI_BREADY  (dut_if.BREADY),
        .S_AXI_BRESP   (dut_if.BRESP),

        .S_AXI_ARVALID (dut_if.ARVALID),
        .S_AXI_ARREADY (dut_if.ARREADY),
        .S_AXI_ARADDR  (dut_if.ARADDR),

        .S_AXI_RVALID  (dut_if.RVALID),
        .S_AXI_RREADY  (dut_if.RREADY),
        .S_AXI_RDATA   (dut_if.RDATA),
        .S_AXI_RRESP   (dut_if.RRESP),

        // MSU outputs (observed by monitor)
        .DataIn        (dut_if.DataIn),
        .KeyIn1        (dut_if.KeyIn1),
        .KeyIn2        (dut_if.KeyIn2),
        .IVIn          (dut_if.IVIn),
        .ModeSelect    (dut_if.ModeSelect),
        .KeySelect     (dut_if.KeySelect),
        .Enable_MSU    (dut_if.Enable_MSU),
        .RST_MSU       (dut_if.RST_MSU),
        .enc_dec       (dut_if.enc_dec),

        // MSU inputs (testbench stub)
        .OF            (dut_if.OF),
        .RF            (dut_if.RF),
        .DataOut       (dut_if.DataOut)
    );

    // -----------------------------------------------------------------------
    // UVM config_db
    // -----------------------------------------------------------------------
    initial begin
        uvm_config_db #(virtual axi_if.master_mp) ::set(null, "uvm_test_top.*",
                                                         "vif",       dut_if.master_mp);
        uvm_config_db #(virtual axi_if.monitor_mp)::set(null, "uvm_test_top.*",
                                                         "vif",       dut_if.monitor_mp);
        uvm_config_db #(virtual axi_if)           ::set(null, "uvm_test_top",
                                                         "vif_plain", dut_if);
        run_test(); // controlled via +UVM_TESTNAME=
    end

    // -----------------------------------------------------------------------
    // Waveform dump
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("axi_main_tb.vcd");
        $dumpvars(0, tb_top);
    end

    // -----------------------------------------------------------------------
    // Simulation timeout
    // -----------------------------------------------------------------------
    initial begin
        #2_000_000; // 2 ms at 25 MHz
        `uvm_fatal("TIMEOUT", "Simulation exceeded 2 ms")
    end

endmodule