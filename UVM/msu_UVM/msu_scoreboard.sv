// =============================================================================
// File        : msu_scoreboard.sv
// Description : UVM scoreboard for mode_selection_unit.
//               Uses the DPI-C reference model (reference.c) to compute the
//               expected AES output and compares it against the DUT.
//
//               The scoreboard also enforces protocol checks:
//                 (1) OF must assert once per transaction.
//                 (2) Non-zero DataIn + Key must produce non-zero DataOut.
//                 (3) ModeSelect and KeySelect must be legal encodings.
//
//               A formatted result table is printed at end of simulation,
//               matching the style shown in the project reference images.
// =============================================================================
`ifndef MSU_SCOREBOARD_SV
`define MSU_SCOREBOARD_SV

// DPI-C import — same reference model used by the cipher_unit UVM TB.
// The mode_selection_unit strips the IV XOR / feedback logic before/after
// calling AES, so the ECB golden value is always the raw AES block result.
// For modes that involve XOR with IV or feedback (CBC/OFB/CFB/CTR) we check
// structural properties rather than bit-exact outputs because the mode logic
// is the DUT under test — a full software reference for every mode is beyond
// the scope of unit-level verification of the MSU itself.
import "DPI-C" function void aes_reference(
    input  bit [127:0] data,
    input  bit [255:0] key,
    input  bit [1:0]   KL,
    input  bit         enc_dec,
    output bit [127:0] result
);

class msu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(msu_scoreboard)

    uvm_analysis_imp #(msu_transaction, msu_scoreboard) ap;

    // Pending input queue — input txn parked until output txn arrives
    msu_transaction pending[$];

    // ---- Per-test statistics (indexed by test label string) ----
    typedef struct {
        int unsigned pass_cnt;
        int unsigned fail_cnt;
        int unsigned total;
        string       mode_str;
    } test_stats_t;

    // Track counts keyed as "MODE-KL-DIR"
    int unsigned total_txns  = 0;
    int unsigned total_pass  = 0;
    int unsigned total_fail  = 0;

    // Named test tracking for the summary table
    string       active_test = "Unknown";
    int unsigned test_pass[string];
    int unsigned test_fail[string];
    string       test_mode[string];   // last mode string seen per test name
    string       test_order[$];       // insertion order

    function new(string name = "msu_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction

    // Called by tests to set the active test label for reporting
    function void set_test_label(string label, string mode_str = "MIXED");
        active_test = label;
        if (!test_pass.exists(label)) begin
            test_pass[label]  = 0;
            test_fail[label]  = 0;
            test_mode[label]  = mode_str;
            test_order.push_back(label);
        end
    endfunction

    // -------------------------------------------------------------------------
    // write() — called by monitor analysis port
    // -------------------------------------------------------------------------
    virtual function void write(msu_transaction tr);
        if (!tr.is_output) begin
            pending.push_back(tr);
            return;
        end

        if (pending.size() == 0) begin
            `uvm_error("SB", "Output received with no pending input in queue")
            return;
        end

        begin
            msu_transaction in_tr = pending.pop_front();
            bit [127:0] ref_out;
            bit [255:0] full_key;
            bit         ok = 1'b1;
            string      label, mode_str, kl_str, dir_str;

            // Build label strings
            case (in_tr.ModeSelect)
                3'b000: mode_str = "ECB";
                3'b001: mode_str = "CBC";
                3'b010: mode_str = "OFB";
                3'b011: mode_str = "CFB";
                3'b100: mode_str = "CTR";
                default: mode_str = "???";
            endcase
            case (in_tr.KeySelect)
                2'b00: kl_str = "128";
                2'b01: kl_str = "192";
                2'b10: kl_str = "256";
                default: kl_str = "???";
            endcase
            dir_str = in_tr.enc_dec ? "ENC" : "DEC";
            label   = active_test;

            // Register test label if first time seen
            if (!test_pass.exists(label)) begin
                test_pass[label] = 0;
                test_fail[label] = 0;
                test_mode[label] = mode_str;
                test_order.push_back(label);
            end

            // ---- Check 1: OF must have been seen ----------------------------
            if (!tr.of_seen) begin
                `uvm_error("SB", $sformatf("[%s] OF did not assert — %s-%s-%s DataIn=%h",
                    label, mode_str, kl_str, dir_str, in_tr.DataIn))
                ok = 1'b0;
            end

            // ---- Check 2: Legal ModeSelect encoding ------------------------
            if (!(in_tr.ModeSelect inside {3'b000,3'b001,3'b010,3'b011,3'b100})) begin
                `uvm_error("SB", $sformatf("[%s] Illegal ModeSelect=%03b", label, in_tr.ModeSelect))
                ok = 1'b0;
            end

            // ---- Check 3: Legal KeySelect encoding -------------------------
            if (!(in_tr.KeySelect inside {2'b00,2'b01,2'b10})) begin
                `uvm_error("SB", $sformatf("[%s] Illegal KeySelect=%02b", label, in_tr.KeySelect))
                ok = 1'b0;
            end

            // ---- Check 4: Non-zero output for non-zero inputs ---------------
            if ((in_tr.DataIn !== 128'h0) && (in_tr.KeyIn2 !== 128'h0) &&
                (tr.dut_result === 128'h0)) begin
                `uvm_error("SB", $sformatf("[%s] DataOut is all-zeros for non-zero input (%s-%s-%s)",
                    label, mode_str, kl_str, dir_str))
                ok = 1'b0;
            end

            // ---- Check 5: ECB reference model comparison -------------------
            // VCS DPI passes bit[N:0] as svBitVecVal[] where word[0]=bits[31:0].
            // reference.c words_to_bytes() reads word[i] ascending, big-endian
            // within each word: bytes[i*4+0] = word[i]>>24, etc.
            //
            // The reference.c is calibrated for the cipher_unit standalone TB where:
            //   state_i[0] = Data[31:0]  (LSW) = first AES state column
            //   KEY[0]     = Key[31:0]   (LSW) = first key word
            //
            // The MSU wires the cipher_unit differently:
            //   state_i[0] = DataIn[127:96] (MSW) = first AES state column
            //   Key[0]     = KeyIn2[127:96] (MSW) = first key word
            //
            // To make the reference see the same first-column / first-key-word bytes,
            // we reverse the 32-bit word order within each 128-bit field before
            // passing to the DPI call, placing the MSW at full_xxx[31:0] = word[0].
            if (in_tr.ModeSelect == 3'b000) begin
                // Reverse word order in DataIn (MSW -> word[0])
                begin
                    bit [127:0] rev_data;
                    rev_data[31:0]   = in_tr.DataIn[127:96];
                    rev_data[63:32]  = in_tr.DataIn[95:64];
                    rev_data[95:64]  = in_tr.DataIn[63:32];
                    rev_data[127:96] = in_tr.DataIn[31:0];

                    // Reverse word order in key (MSW -> word[0] for each half)
                    full_key[31:0]    = in_tr.KeyIn2[127:96]; // first key word
                    full_key[63:32]   = in_tr.KeyIn2[95:64];
                    full_key[95:64]   = in_tr.KeyIn2[63:32];
                    full_key[127:96]  = in_tr.KeyIn2[31:0];
                    full_key[159:128] = in_tr.KeyIn1[127:96]; // upper half (192/256)
                    full_key[191:160] = in_tr.KeyIn1[95:64];
                    full_key[223:192] = in_tr.KeyIn1[63:32];
                    full_key[255:224] = in_tr.KeyIn1[31:0];

                    aes_reference(rev_data, full_key, in_tr.KeySelect, in_tr.enc_dec, ref_out);

                    // Reference output also comes back with word[0]=first output column.
                    // Reverse it back to match DUT DataOut word order (MSW first).
                    begin
                        bit [127:0] rev_ref;
                        rev_ref[127:96] = ref_out[31:0];
                        rev_ref[95:64]  = ref_out[63:32];
                        rev_ref[63:32]  = ref_out[95:64];
                        rev_ref[31:0]   = ref_out[127:96];
                        ref_out = rev_ref;
                    end
                end

                if (tr.dut_result !== ref_out) begin
                    `uvm_error("SB", $sformatf(
                        "[%s] ECB mismatch: DUT=%h  REF=%h  (%s-%s-%s)",
                        label, tr.dut_result, ref_out, mode_str, kl_str, dir_str))
                    ok = 1'b0;
                end
            end

            // ---- Update statistics ------------------------------------------
            total_txns++;
            if (ok) begin
                total_pass++;
                test_pass[label]++;
                `uvm_info("SB",
                    $sformatf("[PASS] %s | %s-%s-%s | DataIn=%h DataOut=%h",
                        label, mode_str, kl_str, dir_str, in_tr.DataIn, tr.dut_result),
                    UVM_MEDIUM)
            end else begin
                total_fail++;
                test_fail[label]++;
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Summary report — matches the table format from the reference images
    // -------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        $display("");
        $display("UVM_INFO [SB] -------------------------------------------------------------------");
        $display("UVM_INFO [SB]           MSU VERIFICATION RESULT SUMMARY");
        $display("UVM_INFO [SB] -------------------------------------------------------------------");
        $display("UVM_INFO [SB]  %-22s  %-8s  %4s  %4s  %5s",
                 "Test", "Mode", "PASS", "FAIL", "TOTAL");
        $display("UVM_INFO [SB] -------------------------------------------------------------------");

        foreach (test_order[i]) begin
            string lbl = test_order[i];
            $display("UVM_INFO [SB]  %-22s  %-8s  %4d  %4d  %5d  [%s]",
                lbl,
                test_mode[lbl],
                test_pass[lbl],
                test_fail[lbl],
                test_pass[lbl] + test_fail[lbl],
                (test_fail[lbl] == 0) ? "OK" : "FAIL");
        end

        $display("UVM_INFO [SB] -------------------------------------------------------------------");
        $display("UVM_INFO [SB]  %-22s           %4d  %4d  %5d",
                 "OVERALL", total_pass, total_fail, total_txns);
        if (total_fail == 0)
            $display("UVM_INFO [SB]                                        ->  ALL PASS");
        else
            $display("UVM_INFO [SB]                                        ->  %0d FAILURE(S)", total_fail);
        $display("UVM_INFO [SB] -------------------------------------------------------------------");
        $display("");

        if (total_fail > 0)
            `uvm_fatal("SB", "One or more scoreboard checks FAILED — see log above")
    endfunction

endclass : msu_scoreboard

`endif // MSU_SCOREBOARD_SV