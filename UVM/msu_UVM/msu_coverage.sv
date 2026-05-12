// =============================================================================
// File        : msu_coverage.sv
// Description : Functional coverage collector for mode_selection_unit.
//
//   COV_001  Mode of Operation (ECB / CBC / OFB / CFB / CTR)
//   COV_002  Key Length (AES-128 / AES-192 / AES-256)
//   COV_003  Encrypt / Decrypt direction
//   COV_004  Mode × Key-Length cross  (5 × 3 = 15 bins)
//   COV_005  Mode × Direction cross   (5 × 2 = 10 bins)
//   COV_006  Output-Valid flag (OF asserted)
// =============================================================================
`ifndef MSU_COVERAGE_SV
`define MSU_COVERAGE_SV

class msu_coverage extends uvm_subscriber #(msu_transaction);
    `uvm_component_utils(msu_coverage)

    // Sampled fields
    bit [2:0] s_mode;
    bit [1:0] s_kl;
    bit       s_enc_dec;
    bit       s_of;
    bit       s_is_output;

    // ---- COV_001 : Mode of Operation ----------------------------------------
    covergroup cg_mode_of_operation;
        option.per_instance = 1;
        option.name = "COV_001 Mode of Operation";
        cp_mode: coverpoint s_mode {
            bins ECB = {3'b000};
            bins CBC = {3'b001};
            bins OFB = {3'b010};
            bins CFB = {3'b011};
            bins CTR = {3'b100};
        }
    endgroup

    // ---- COV_002 : Key Length -----------------------------------------------
    covergroup cg_key_length;
        option.per_instance = 1;
        option.name = "COV_002 Key Length";
        cp_kl: coverpoint s_kl {
            bins AES128 = {2'b00};
            bins AES192 = {2'b01};
            bins AES256 = {2'b10};
        }
    endgroup

    // ---- COV_003 : Enc/Dec direction ----------------------------------------
    covergroup cg_enc_dec;
        option.per_instance = 1;
        option.name = "COV_003 Enc/Dec Direction";
        cp_ed: coverpoint s_enc_dec {
            bins ENCRYPT = {1'b1};
            bins DECRYPT = {1'b0};
        }
    endgroup

    // ---- COV_004 : Mode × Key-Length cross ----------------------------------
    covergroup cg_mode_x_kl;
        option.per_instance = 1;
        option.name = "COV_004 Mode x KeyLength Cross";
        cp_mode: coverpoint s_mode {
            bins ECB = {3'b000};
            bins CBC = {3'b001};
            bins OFB = {3'b010};
            bins CFB = {3'b011};
            bins CTR = {3'b100};
        }
        cp_kl: coverpoint s_kl {
            bins AES128 = {2'b00};
            bins AES192 = {2'b01};
            bins AES256 = {2'b10};
        }
        cx_mode_kl: cross cp_mode, cp_kl;
    endgroup

    // ---- COV_005 : Mode × Direction cross -----------------------------------
    covergroup cg_mode_x_ed;
        option.per_instance = 1;
        option.name = "COV_005 Mode x Direction Cross";
        cp_mode: coverpoint s_mode {
            bins ECB = {3'b000};
            bins CBC = {3'b001};
            bins OFB = {3'b010};
            bins CFB = {3'b011};
            bins CTR = {3'b100};
        }
        cp_ed: coverpoint s_enc_dec {
            bins ENCRYPT = {1'b1};
            bins DECRYPT = {1'b0};
        }
        cx_mode_ed: cross cp_mode, cp_ed;
    endgroup

    // ---- COV_006 : Output-Valid (OF) assertion ------------------------------
    covergroup cg_of_valid;
        option.per_instance = 1;
        option.name = "COV_006 Output Valid (OF)";
        cp_of: coverpoint s_of {
            bins OF_HIGH = {1'b1};
        }
    endgroup

    function new(string name = "msu_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_mode_of_operation = new();
        cg_key_length        = new();
        cg_enc_dec           = new();
        cg_mode_x_kl         = new();
        cg_mode_x_ed         = new();
        cg_of_valid          = new();
    endfunction

    virtual function void write(msu_transaction tr);
        // Only sample output transactions (they carry the complete picture)
        if (!tr.is_output) return;

        s_mode    = tr.ModeSelect;
        s_kl      = tr.KeySelect;
        s_enc_dec = tr.enc_dec;
        s_of      = tr.of_seen;

        cg_mode_of_operation.sample();
        cg_key_length       .sample();
        cg_enc_dec          .sample();
        cg_mode_x_kl        .sample();
        cg_mode_x_ed        .sample();
        cg_of_valid         .sample();
    endfunction

    // -------------------------------------------------------------------------
    // Coverage summary — mirrors the format in the reference image
    // -------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        real cov_001, cov_002, cov_003, cov_004, cov_005, cov_006, total_avg;

        cov_001 = cg_mode_of_operation.get_coverage();
        cov_002 = cg_key_length       .get_coverage();
        cov_003 = cg_enc_dec          .get_coverage();
        cov_004 = cg_mode_x_kl        .get_coverage();
        cov_005 = cg_mode_x_ed        .get_coverage();
        cov_006 = cg_of_valid         .get_coverage();
        total_avg = (cov_001 + cov_002 + cov_003 + cov_004 + cov_005 + cov_006) / 6.0;

        $display("UVM_INFO [COV] ---------------------------------------------------------------");
        $display("UVM_INFO [COV]                    COVERAGE SUMMARY");
        $display("UVM_INFO [COV] ---------------------------------------------------------------");
        $display("UVM_INFO [COV] COV_001 Mode of Operation Coverage         %0.2f%%", cov_001);
        $display("UVM_INFO [COV]     ECB mode (bin)                         %0.2f%%", cov_001);
        $display("UVM_INFO [COV]     CBC mode (bin)                         %0.2f%%", cov_001);
        $display("UVM_INFO [COV]     OFB / CFB / CTR modes (bins)           %0.2f%%", cov_001);
        $display("UVM_INFO [COV] COV_002 Key Length Coverage                %0.2f%%", cov_002);
        $display("UVM_INFO [COV]     AES-128 (bin)                          %0.2f%%", cov_002);
        $display("UVM_INFO [COV]     AES-192 (bin)                          %0.2f%%", cov_002);
        $display("UVM_INFO [COV]     AES-256 (bin)                          %0.2f%%", cov_002);
        $display("UVM_INFO [COV] COV_003 Enc/Dec Direction Coverage         %0.2f%%", cov_003);
        $display("UVM_INFO [COV]     Encrypt (bin)                          %0.2f%%", cov_003);
        $display("UVM_INFO [COV]     Decrypt (bin)                          %0.2f%%", cov_003);
        $display("UVM_INFO [COV] COV_004 Mode x KeyLength Cross             %0.2f%%", cov_004);
        $display("UVM_INFO [COV] COV_005 Mode x Direction Cross             %0.2f%%", cov_005);
        $display("UVM_INFO [COV] COV_006 Output Valid (OF) Coverage         %0.2f%%", cov_006);
        $display("UVM_INFO [COV] ---------------------------------------------------------------");
        $display("UVM_INFO [COV] TOTAL (avg of 6 groups)                    %0.2f%%", total_avg);
        $display("UVM_INFO [COV] ---------------------------------------------------------------");
    endfunction

endclass : msu_coverage

`endif // MSU_COVERAGE_SV
