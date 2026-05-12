`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

// ---------------------------------------------------------------------------
// Result entry for one named test scenario
// ---------------------------------------------------------------------------
typedef struct {
    string test_name;
    string mode;
    int unsigned pass_cnt;
    int unsigned fail_cnt;
} sb_result_t;

// ---------------------------------------------------------------------------
// Scoreboard
//   - Mirrors Mem_in via observed AXI write transactions
//   - Mirrors Mem_out by watching OF pulse directly on the interface
//   - Checks BRESP / RRESP protocol correctness
//   - Checks RDATA against expected register content (only after OF seen)
//   - Prints a formatted per-test results table + pass/fail summary
// ---------------------------------------------------------------------------
class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_seq_item, axi_scoreboard) analysis_export;

    // Virtual interface so we can watch OF/DataOut directly
    virtual axi_if.monitor_mp vif;

    // Shadow register file
    logic [31:0] mem_in_shadow [17];
    logic [31:0] mem_out_shadow[5];

    // Guard: only check read data after at least one OF pulse has been seen
    bit of_seen = 0;

    // Per-scenario result tracking
    string        current_scenario = "DEFAULT";
    string        current_mode     = "MIXED";
    sb_result_t   results[$];
    int           result_idx[string];
    int unsigned  total_pass, total_fail;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        reset_shadow();
        if (!uvm_config_db #(virtual axi_if.monitor_mp)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "axi_scoreboard: monitor_mp vif not found")
    endfunction

    // Background thread: watch OF and latch DataOut into shadow when it pulses
    task run_phase(uvm_phase phase);
        forever begin
            @(vif.monitor_cb iff vif.monitor_cb.OF);
            mem_out_shadow[1] = vif.monitor_cb.DataOut[31:0];
            mem_out_shadow[2] = vif.monitor_cb.DataOut[63:32];
            mem_out_shadow[3] = vif.monitor_cb.DataOut[95:64];
            mem_out_shadow[4] = vif.monitor_cb.DataOut[127:96];
            of_seen = 1;
            `uvm_info("SB", $sformatf("OF pulsed – latched DataOut=0x%0h",
                      vif.monitor_cb.DataOut), UVM_MEDIUM)
        end
    endtask

    // Called by apply_reset() in the test at the start of every scenario.
    // Clears both memory shadows and the of_seen flag so the scoreboard
    // stays in sync with the freshly-reset DUT.
    function void reset_shadow();
        foreach (mem_in_shadow[i])  mem_in_shadow[i]  = '0;
        foreach (mem_out_shadow[i]) mem_out_shadow[i] = '0;
        of_seen = 0;
        `uvm_info("SB", "Shadow memory and of_seen cleared (DUT reset)", UVM_MEDIUM)
    endfunction

    function void set_scenario(string scenario, string mode);
        current_scenario = scenario;
        current_mode     = mode;
    endfunction

    // -----------------------------------------------------------------------
    function void write(axi_seq_item tr);
        if (tr.kind == axi_seq_item::AXI_WRITE)
            check_write(tr);
        else
            check_read(tr);
    endfunction

    // -----------------------------------------------------------------------
    function void check_write(axi_seq_item tr);
        logic [15:0] lo_idx, hi_idx;
        bit ok = 1;

        if (tr.addr > 16) begin
            if (tr.bresp !== 2'b10) begin
                `uvm_error("SB", $sformatf(
                    "[%s] WRITE addr=0x%0h >16: expected BRESP=SLVERR, got %0b",
                    current_scenario, tr.addr, tr.bresp))
                ok = 0;
            end
            record_result(ok);
            return;
        end

        if (tr.bresp !== 2'b00) begin
            `uvm_error("SB", $sformatf(
                "[%s] WRITE addr=0x%0h: unexpected BRESP=%0b",
                current_scenario, tr.addr, tr.bresp))
            ok = 0;
        end

        // Update shadow memory
        lo_idx = tr.addr[15:0];
        hi_idx = tr.addr[15:0] + 1;
        if (lo_idx < 17) begin
            if (tr.wstrb[0]) mem_in_shadow[lo_idx][ 7: 0] = tr.wdata[ 7: 0];
            if (tr.wstrb[1]) mem_in_shadow[lo_idx][15: 8] = tr.wdata[15: 8];
            if (tr.wstrb[2]) mem_in_shadow[lo_idx][23:16] = tr.wdata[23:16];
            if (tr.wstrb[3]) mem_in_shadow[lo_idx][31:24] = tr.wdata[31:24];
        end
        if (hi_idx < 17) begin
            if (tr.wstrb[4]) mem_in_shadow[hi_idx][ 7: 0] = tr.wdata[39:32];
            if (tr.wstrb[5]) mem_in_shadow[hi_idx][15: 8] = tr.wdata[47:40];
            if (tr.wstrb[6]) mem_in_shadow[hi_idx][23:16] = tr.wdata[55:48];
            if (tr.wstrb[7]) mem_in_shadow[hi_idx][31:24] = tr.wdata[63:56];
        end

        `uvm_info("SB", $sformatf("[%s] WRITE OK addr=0x%0h data=0x%0h strb=%0b",
                  current_scenario, tr.addr, tr.wdata, tr.wstrb), UVM_HIGH)
        record_result(ok);
    endfunction

    // -----------------------------------------------------------------------
    function void check_read(axi_seq_item tr);
        logic [63:0] exp_data;
        bit ok = 1;

        // OOB read: expect SLVERR
        if (tr.addr > 2) begin
            if (tr.rresp !== 2'b10) begin
                `uvm_error("SB", $sformatf(
                    "[%s] READ addr=0x%0h >2: expected RRESP=SLVERR, got %0b",
                    current_scenario, tr.addr, tr.rresp))
                ok = 0;
            end
            record_result(ok);
            return;
        end

        // RRESP must be OKAY for valid addresses
        if (tr.rresp !== 2'b00) begin
            `uvm_error("SB", $sformatf(
                "[%s] READ addr=0x%0h: unexpected RRESP=%0b",
                current_scenario, tr.addr, tr.rresp))
            ok = 0;
        end

        // Build expected data from shadow
        case (tr.addr)
            // DUT: addr1 → {Mem_out[1], Mem_out[2]}, addr2 → {Mem_out[3], Mem_out[4]}
            0: exp_data = {32'h0, mem_out_shadow[0]};
            1: exp_data = {mem_out_shadow[1], mem_out_shadow[2]};
            2: exp_data = {mem_out_shadow[3], mem_out_shadow[4]};
            default: exp_data = '0;
        endcase

        // Only check data registers after OF has been seen at least once;
        // before that the shadow is all-zero and the comparison is meaningless
        if (tr.addr inside {1, 2}) begin
            if (!of_seen) begin
                `uvm_info("SB", $sformatf(
                    "[%s] READ addr=%0d – skipping data check (OF not yet seen)",
                    current_scenario, tr.addr), UVM_MEDIUM)
            end else begin
                if (tr.rdata !== exp_data) begin
                    `uvm_error("SB", $sformatf(
                        "[%s] READ DATA MISMATCH addr=%0d exp=0x%0h got=0x%0h",
                        current_scenario, tr.addr, exp_data, tr.rdata))
                    ok = 0;
                end else
                    `uvm_info("SB", $sformatf("[%s] READ OK addr=%0d data=0x%0h",
                              current_scenario, tr.addr, tr.rdata), UVM_HIGH)
            end
        end

        record_result(ok);
    endfunction

    // -----------------------------------------------------------------------
    function void record_result(bit ok);
        string key = {current_scenario, "|", current_mode};
        if (!result_idx.exists(key)) begin
            sb_result_t r;
            r.test_name = current_scenario;
            r.mode      = current_mode;
            r.pass_cnt  = 0;
            r.fail_cnt  = 0;
            results.push_back(r);
            result_idx[key] = results.size() - 1;
        end
        if (ok) begin
            results[result_idx[key]].pass_cnt++;
            total_pass++;
        end else begin
            results[result_idx[key]].fail_cnt++;
            total_fail++;
        end
    endfunction

    // -----------------------------------------------------------------------
    function void print_results_table();
        string overall_verdict = (total_fail == 0) ? "ALL PASS" : "FAILED";

        `uvm_info("SB", "----------------------------------------------------------------", UVM_NONE)
        `uvm_info("SB", "         AXI_MAIN VERIFICATION RESULT SUMMARY                  ", UVM_NONE)
        `uvm_info("SB", "----------------------------------------------------------------", UVM_NONE)
        `uvm_info("SB", $sformatf("%-22s %-12s %6s %6s %8s",
                  "Test", "Mode", "PASS", "FAIL", "TOTAL"), UVM_NONE)
        `uvm_info("SB", "----------------------------------------------------------------", UVM_NONE)
        foreach (results[i]) begin
            int unsigned tot   = results[i].pass_cnt + results[i].fail_cnt;
            string verdict     = (results[i].fail_cnt == 0) ? "[OK]" : "[FAIL]";
            `uvm_info("SB", $sformatf("%-22s %-12s %6d %6d %8d   %s",
                      results[i].test_name, results[i].mode,
                      results[i].pass_cnt, results[i].fail_cnt,
                      tot, verdict), UVM_NONE)
        end
        `uvm_info("SB", "----------------------------------------------------------------", UVM_NONE)
        `uvm_info("SB", $sformatf("%-22s %-12s %6d %6d %8s ->  %s",
                  "OVERALL", "", total_pass, total_fail, "",
                  overall_verdict), UVM_NONE)
        `uvm_info("SB", "----------------------------------------------------------------", UVM_NONE)
    endfunction

    // -----------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        // print_results_table() is called from axi_base_test.report_phase
        // together with print_coverage_summary() — do NOT call it here too
        if (total_fail > 0)
            `uvm_error("SB", "TEST FAILED - scoreboard reported errors")
        else
            `uvm_info("SB", "TEST PASSED", UVM_NONE)
    endfunction

endclass

`endif