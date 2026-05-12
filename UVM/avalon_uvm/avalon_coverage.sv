// =============================================================================
// File        : avalon_coverage.sv
// Description : Functional coverage for AvalonMM_MSU.
//
//   COV_001  Functional — Transaction kind (WRITE / READ)
//   COV_002  Functional — Write address decode (addr 0..4)
//   COV_003  Functional — Read address decode  (addr 0..1)
//   COV_004  Functional — Control word fields written to addr 0
//              • ModeSelect (bits [2:0]) — ECB/CBC/OFB/CFB/CTR
//              • KeySelect  (bits [4:3]) — AES-128/192/256
//              • enc_dec    (bit  [5])   — encrypt / decrypt
//              • Enable_MSU (bit  [6])   — enable / disable
//   COV_005  Functional — Mode × KeySelect cross coverage
//   COV_006  Functional — Mode × Enc/Dec cross coverage
//   COV_007  Functional — Avalon error state (simultaneous write_h + read_h)
//   COV_008  Functional — Write-then-read host access sequence
// =============================================================================
`ifndef AVALON_COVERAGE_SV
`define AVALON_COVERAGE_SV

class avalon_coverage extends uvm_subscriber #(avalon_transaction);
    `uvm_component_utils(avalon_coverage)

    // Sampled fields
    avalon_transaction::av_kind_e s_kind;
    logic [31:0]  s_address;
    logic [127:0] s_wdata;
    logic         s_error;
    logic         s_rdv;

    // Derived fields from control word
    logic [2:0] s_mode;
    logic [1:0] s_ksel;
    logic       s_encdec;
    logic       s_enable;

    // State tracking for sequence coverage
    bit last_was_write;

    // ---- COV-001 : Transaction kind -----------------------------------------
    covergroup cg_kind;
        option.per_instance = 1;
        option.name = "COV-001 Transaction Kind";
        cp_kind: coverpoint s_kind {
            bins WRITE = {avalon_transaction::AVALON_WRITE};
            bins READ  = {avalon_transaction::AVALON_READ};
        }
    endgroup

    // ---- COV-002 : Write address --------------------------------------------
    covergroup cg_write_addr;
        option.per_instance = 1;
        option.name = "COV-002 Write Address";
        cp_waddr: coverpoint s_address {
            bins CTRL   = {32'h0};
            bins DATAIN = {32'h1};
            bins KEYIN1 = {32'h2};
            bins KEYIN2 = {32'h3};
            bins IVIN   = {32'h4};
        }
    endgroup

    // ---- COV-003 : Read address ---------------------------------------------
    covergroup cg_read_addr;
        option.per_instance = 1;
        option.name = "COV-003 Read Address";
        cp_raddr: coverpoint s_address {
            bins STATUS  = {32'h0};
            bins DATAOUT = {32'h1};
        }
    endgroup

    // ---- COV-005 : Control-word field coverage ------------------------------
    covergroup cg_ctrl_fields;
        option.per_instance = 1;
        option.name = "COV-005 Control Word Fields";
        cp_mode: coverpoint s_mode {
            bins ECB = {3'b000};
            bins CBC = {3'b001};
            bins OFB = {3'b010};
            bins CFB = {3'b011};
            bins CTR = {3'b100};
        }
        cp_ksel: coverpoint s_ksel {
            bins AES128 = {2'b00};
            bins AES192 = {2'b01};
            bins AES256 = {2'b10};
        }
        cp_encdec: coverpoint s_encdec {
            bins ENCRYPT = {1'b1};
            bins DECRYPT = {1'b0};
        }
        cp_enable: coverpoint s_enable {
            bins ENABLED  = {1'b1};
            bins DISABLED = {1'b0};
        }
        // Mode × KeySelect cross
        cx_mode_ksel: cross cp_mode, cp_ksel;
        // Mode × enc_dec cross
        cx_mode_encdec: cross cp_mode, cp_encdec;
    endgroup

    // ---- COV-008 : Error condition (simultaneous R+W) -----------------------
    covergroup cg_error;
        option.per_instance = 1;
        option.name = "COV-008 Error State";
        cp_err: coverpoint s_error {
            bins NORMAL = {1'b0};
            bins ERROR  = {1'b1};
        }
    endgroup

    // ---- COV-007 : Write-then-read sequence ---------------------------------
    covergroup cg_wr_rd_seq;
        option.per_instance = 1;
        option.name = "COV-007 Write-then-Read Sequence";
        cp_seq: coverpoint last_was_write {
            bins WRITE_THEN_READ = {1'b1}; // sampled when a READ follows a WRITE
        }
    endgroup

    function new(string name = "avalon_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_kind        = new();
        cg_write_addr  = new();
        cg_read_addr   = new();
        cg_ctrl_fields = new();
        cg_error       = new();
        cg_wr_rd_seq   = new();
        last_was_write = 1'b0;
    endfunction

    virtual function void write(avalon_transaction tr);
        // Sample common fields
        s_kind    = tr.kind;
        s_address = tr.address;
        s_wdata   = tr.wdata;
        s_error   = tr.av_error;
        s_rdv     = tr.rd_valid;

        cg_kind.sample();
        cg_error.sample();

        if (tr.kind == avalon_transaction::AVALON_WRITE) begin
            cg_write_addr.sample();

            // Sample control word fields only on addr-0 writes
            if (tr.address == 32'h0) begin
                s_mode   = tr.wdata[2:0];
                s_ksel   = tr.wdata[4:3];
                s_encdec = tr.wdata[5];
                s_enable = tr.wdata[6];
                cg_ctrl_fields.sample();
            end

            last_was_write = 1'b1;

        end else begin // READ
            cg_read_addr.sample();

            // COV-007: capture write-then-read sequence
            if (last_was_write)
                cg_wr_rd_seq.sample();

            last_was_write = 1'b0;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Helper: format a coverage percentage as "XX.XX%"
    // -------------------------------------------------------------------------
    function string fmt_pct(real pct);
        return $sformatf("%6.2f%%", pct);
    endfunction

    // -------------------------------------------------------------------------
    // Report phase — formatted coverage summary matching project style
    // -------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        string line = {72{"-"}};

        // ---- Collect per-group percentages ----------------------------------
        real pct_kind       = cg_kind.get_coverage();
        real pct_write_addr = cg_write_addr.get_coverage();
        real pct_read_addr  = cg_read_addr.get_coverage();
        real pct_ctrl       = cg_ctrl_fields.get_coverage();
        real pct_error      = cg_error.get_coverage();
        real pct_wr_rd      = cg_wr_rd_seq.get_coverage();

        // ---- Per-bin percentages (coverpoint level) -------------------------
        // COV-001 bins
        real pct_write_bin  = cg_kind.cp_kind.get_coverage();
        real pct_read_bin   = cg_kind.cp_kind.get_coverage();

        // COV-002 bins
        real pct_waddr_ctrl   = cg_write_addr.cp_waddr.get_coverage();
        real pct_waddr_data   = cg_write_addr.cp_waddr.get_coverage();
        real pct_waddr_key1   = cg_write_addr.cp_waddr.get_coverage();
        real pct_waddr_key2   = cg_write_addr.cp_waddr.get_coverage();
        real pct_waddr_iv     = cg_write_addr.cp_waddr.get_coverage();

        // COV-003 bins
        real pct_raddr_status = cg_read_addr.cp_raddr.get_coverage();
        real pct_raddr_dout   = cg_read_addr.cp_raddr.get_coverage();

        // COV-005 sub-coverpoints
        real pct_mode    = cg_ctrl_fields.cp_mode.get_coverage();
        real pct_ksel    = cg_ctrl_fields.cp_ksel.get_coverage();
        real pct_encdec  = cg_ctrl_fields.cp_encdec.get_coverage();
        real pct_enable  = cg_ctrl_fields.cp_enable.get_coverage();
        real pct_cx_mk   = cg_ctrl_fields.cx_mode_ksel.get_coverage();
        real pct_cx_med  = cg_ctrl_fields.cx_mode_encdec.get_coverage();

        // ---- Overall average (6 top-level groups) ---------------------------
        real pct_overall = (pct_kind + pct_write_addr + pct_read_addr +
                            pct_ctrl + pct_error + pct_wr_rd) / 6.0;

        // ---- Print ----------------------------------------------------------
        `uvm_info("COV", "\n", UVM_NONE)
        `uvm_info("COV", line, UVM_NONE)
        `uvm_info("COV", "                    COVERAGE SUMMARY", UVM_NONE)
        `uvm_info("COV", line, UVM_NONE)

        // COV-001
        `uvm_info("COV", $sformatf("COV_001 Transaction Kind Coverage            %s",
                  fmt_pct(pct_kind)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Write transactions (bin)                %s",
                  fmt_pct(pct_write_bin)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Read  transactions (bin)                %s",
                  fmt_pct(pct_read_bin)), UVM_NONE)

        // COV-002
        `uvm_info("COV", $sformatf("COV_002 Write Address Coverage               %s",
                  fmt_pct(pct_write_addr)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Addr 0 - Control  (bin)                 %s",
                  fmt_pct(pct_waddr_ctrl)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Addr 1 - DataIn   (bin)                 %s",
                  fmt_pct(pct_waddr_data)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Addr 2 - KeyIn1   (bin)                 %s",
                  fmt_pct(pct_waddr_key1)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Addr 3 - KeyIn2   (bin)                 %s",
                  fmt_pct(pct_waddr_key2)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Addr 4 - IVIn     (bin)                 %s",
                  fmt_pct(pct_waddr_iv)), UVM_NONE)

        // COV-003
        `uvm_info("COV", $sformatf("COV_003 Read Address Coverage                %s",
                  fmt_pct(pct_read_addr)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Addr 0 - Status   (bin)                 %s",
                  fmt_pct(pct_raddr_status)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Addr 1 - DataOut  (bin)                 %s",
                  fmt_pct(pct_raddr_dout)), UVM_NONE)

        // COV-004 (ctrl fields)
        `uvm_info("COV", $sformatf("COV_004 Control Word Field Coverage          %s",
                  fmt_pct(pct_ctrl)), UVM_NONE)
        `uvm_info("COV", $sformatf("     ModeSelect coverage (bins)              %s",
                  fmt_pct(pct_mode)), UVM_NONE)
        `uvm_info("COV", $sformatf("     KeySelect  coverage (bins)              %s",
                  fmt_pct(pct_ksel)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Enc/Dec    coverage (bins)              %s",
                  fmt_pct(pct_encdec)), UVM_NONE)
        `uvm_info("COV", $sformatf("     Enable_MSU coverage (bins)              %s",
                  fmt_pct(pct_enable)), UVM_NONE)

        // COV-005 crosses
        `uvm_info("COV", $sformatf("COV_005 Mode x KeySelect Cross               %s",
                  fmt_pct(pct_cx_mk)), UVM_NONE)
        `uvm_info("COV", $sformatf("COV_006 Mode x Enc/Dec Cross                 %s",
                  fmt_pct(pct_cx_med)), UVM_NONE)

        // COV-007 error
        `uvm_info("COV", $sformatf("COV_007 Error State Coverage                 %s",
                  fmt_pct(pct_error)), UVM_NONE)

        // COV-008 write-then-read
        `uvm_info("COV", $sformatf("COV_008 Write-then-Read Sequence Coverage    %s",
                  fmt_pct(pct_wr_rd)), UVM_NONE)

        // Overall
        `uvm_info("COV", line, UVM_NONE)
        `uvm_info("COV", $sformatf("TOTAL (avg of 6 groups)                      %s",
                  fmt_pct(pct_overall)), UVM_NONE)
        `uvm_info("COV", line, UVM_NONE)

    endfunction

endclass : avalon_coverage

`endif // AVALON_COVERAGE_SV