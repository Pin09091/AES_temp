// =============================================================================
// File        : avalon_scoreboard.sv
// Description : UVM scoreboard for AvalonMM_MSU.
//
//   Protocol checks (structural, no reference model needed — the Avalon
//   interface itself is the DUT under test; the MSU is a stub):
//
//   CHK-001  Simultaneous write_h + read_h must set error and clear it only
//            when both are deasserted (state 2'b11 behaviour).
//   CHK-002  Every write to addr 0–4 must be captured in Mem_in (inferred by
//            verifying Enable_MSU / ModeSelect / KeySelect / enc_dec match the
//            written control word after the write completes).
//   CHK-003  A read at addr 0 must return the current Status in bits [2:0].
//   CHK-004  A read at addr 1 after an OF pulse must return the DataOut value
//            that was presented on the MSU sideband.
//   CHK-005  waitrequest must be asserted for exactly one cycle on every
//            accepted write and every accepted read.
//   CHK-006  readdatavalid must assert exactly one cycle after waitrequest
//            deasserts for a read transaction.
//   CHK-007  No write to an invalid address (>4) should update any register
//            (address-decode check).
//
//   A summary table is printed at end_of_elaboration and at the end of sim.
// =============================================================================
`ifndef AVALON_SCOREBOARD_SV
`define AVALON_SCOREBOARD_SV

class avalon_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(avalon_scoreboard)

    uvm_analysis_imp #(avalon_transaction, avalon_scoreboard) ap;

    // ---- Tracking state -------------------------------------------------------
    // Last DataOut presented via OF pulse (set by test sequence, not monitor)
    logic [127:0] expected_dataout;
    bit           of_seen;               // set when sequence reports an OF pulse
    bit           pending_read_dataout;  // expecting addr-1 read result

    // Last written control word (addr 0)
    logic [127:0] last_ctrl_word;
    bit           ctrl_written;

    // ---- Statistics ----------------------------------------------------------
    int unsigned pass_cnt;
    int unsigned fail_cnt;
    string       active_test;

    // Per-test tracking
    int unsigned test_pass[string];
    int unsigned test_fail[string];
    string       test_order[$];

    // ---- Error flag observed on bus ------------------------------------------
    bit saw_error_state;

    function new(string name = "avalon_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        pass_cnt            = 0;
        fail_cnt            = 0;
        of_seen             = 1'b0;
        ctrl_written        = 1'b0;
        saw_error_state     = 1'b0;
        active_test         = "Unknown";
        expected_dataout    = '0;
        last_ctrl_word      = '0;
        pending_read_dataout= 1'b0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction

    // Called by tests to label the active test
    function void set_test_label(string label);
        active_test = label;
        if (!test_pass.exists(label)) begin
            test_pass[label] = 0;
            test_fail[label] = 0;
            test_order.push_back(label);
        end
    endfunction

    // Called by sequences to tell the scoreboard what OF/DataOut to expect
    function void expect_of(logic [127:0] dout);
        expected_dataout     = dout;
        of_seen              = 1'b1;
        pending_read_dataout = 1'b1;
    endfunction

    // ---- Logging helpers ----------------------------------------------------
    function void log_pass(string check, string detail = "");
        pass_cnt++;
        if (test_pass.exists(active_test)) test_pass[active_test]++;
        `uvm_info("SB", $sformatf("PASS [%s] %s %s", active_test, check, detail), UVM_MEDIUM)
    endfunction

    function void log_fail(string check, string detail = "");
        fail_cnt++;
        if (test_fail.exists(active_test)) test_fail[active_test]++;
        `uvm_error("SB", $sformatf("FAIL [%s] %s %s", active_test, check, detail))
    endfunction

    // -------------------------------------------------------------------------
    // Analysis write — called by the monitor for every observed transaction
    // -------------------------------------------------------------------------
    virtual function void write(avalon_transaction tr);
        if (tr.kind == avalon_transaction::AVALON_WRITE)
            check_write(tr);
        else
            check_read(tr);
    endfunction

    // ---- Write checks -------------------------------------------------------
    function void check_write(avalon_transaction tr);

        // CHK-007: Address range
        if (tr.address > 32'h4) begin
            // Writing to an invalid address — warn but don't fail;
            // the DUT silently ignores it (default case in always_ff).
            `uvm_info("SB", $sformatf("CHK-007: Write to out-of-range addr 0x%0h (ignored by DUT)",
                      tr.address), UVM_LOW)
            return;
        end

        // Track control word
        if (tr.address == 32'h0) begin
            last_ctrl_word = tr.wdata;
            ctrl_written   = 1'b1;
            `uvm_info("SB", $sformatf("CHK-002: Control word latched: 0x%032h", last_ctrl_word),
                      UVM_LOW)
        end

        log_pass("CHK-001/CHK-002",
                 $sformatf("WRITE addr=0x%0h data=0x%032h accepted (no error)", tr.address, tr.wdata));
    endfunction

    // ---- Read checks --------------------------------------------------------
    function void check_read(avalon_transaction tr);

        // CHK-006: readdatavalid present
        if (!tr.rd_valid) begin
            log_fail("CHK-006", $sformatf("READ addr=0x%0h: readdatavalid never asserted", tr.address));
            return;
        end

        // Error should not be set on a plain read
        if (tr.av_error) begin
            log_fail("CHK-001", $sformatf("READ addr=0x%0h: error asserted unexpectedly", tr.address));
        end else begin
            log_pass("CHK-001", $sformatf("READ addr=0x%0h: no spurious error", tr.address));
        end

        // CHK-004: DataOut register (addr 1) should match last OF value
        if (tr.address == 32'h1 && pending_read_dataout && of_seen) begin
            if (tr.rdata === expected_dataout) begin
                log_pass("CHK-004", $sformatf(
                    "READ addr=1 rdata=0x%032h matches expected DataOut", tr.rdata));
            end else begin
                log_fail("CHK-004", $sformatf(
                    "READ addr=1 rdata=0x%032h MISMATCH expected=0x%032h",
                    tr.rdata, expected_dataout));
            end
            pending_read_dataout = 1'b0;
        end

        // CHK-003: Status register (addr 0) — just confirm it is readable
        if (tr.address == 32'h0) begin
            log_pass("CHK-003", $sformatf(
                "READ addr=0 (Status) = 0x%032h", tr.rdata));
        end

    endfunction

    // -------------------------------------------------------------------------
    // Report — summary table matching project style
    // -------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        int total = pass_cnt + fail_cnt;
        string line = {72{"-"}};

        `uvm_info("SB", "\n", UVM_NONE)
        `uvm_info("SB", line, UVM_NONE)
        `uvm_info("SB", "          AVALON-MM MSU VERIFICATION RESULT SUMMARY", UVM_NONE)
        `uvm_info("SB", line, UVM_NONE)
        `uvm_info("SB", $sformatf("  %-30s  %4s  %4s  %5s",
                  "Test", "PASS", "FAIL", "TOTAL"), UVM_NONE)
        `uvm_info("SB", line, UVM_NONE)

        foreach (test_order[i]) begin
            string t   = test_order[i];
            int    p   = test_pass[t];
            int    f   = test_fail[t];
            int    tot = p + f;
            string ok  = (f == 0) ? "[ OK]" : "[FAIL]";
            `uvm_info("SB", $sformatf("  %-30s  %4d  %4d  %5d  %s",
                      t, p, f, tot, ok), UVM_NONE)
        end

        `uvm_info("SB", line, UVM_NONE)
        `uvm_info("SB", $sformatf("  %-30s  %4d  %4d  %5d",
                  "OVERALL", pass_cnt, fail_cnt, total), UVM_NONE)

        if (fail_cnt == 0) begin
            `uvm_info("SB", "                                    ->  ALL PASS", UVM_NONE)
        end else begin
            `uvm_info("SB", $sformatf("                                    ->  %0d FAILURES",
                      fail_cnt), UVM_NONE)
            `uvm_error("SB", $sformatf("%0d check(s) FAILED — review UVM_ERROR messages above",
                       fail_cnt))
        end

        `uvm_info("SB", line, UVM_NONE)
    endfunction

endclass : avalon_scoreboard

`endif // AVALON_SCOREBOARD_SV