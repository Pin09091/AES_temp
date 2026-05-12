`ifndef AXI_COVERAGE_SV
`define AXI_COVERAGE_SV

class axi_coverage extends uvm_subscriber #(axi_seq_item);
    `uvm_component_utils(axi_coverage)

    axi_seq_item tr;

    // -----------------------------------------------------------------------
    // COV_001: Write address + strobe coverage
    // -----------------------------------------------------------------------
    covergroup cg_write_addr;
        cp_addr: coverpoint tr.addr {
            bins ctrl_reg    = {0};
            bins key2_regs   = {[1:4]};
            bins key1_regs   = {[5:8]};
            bins iv_regs     = {[9:12]};
            bins data_regs   = {[13:16]};
            bins oob         = {[17:$]};
        }
        cp_strb: coverpoint tr.wstrb {
            bins full   = {8'hFF};
            bins lo32   = {8'h0F};
            bins hi32   = {8'hF0};
            bins others = default;
        }
        cx_addr_strb: cross cp_addr, cp_strb;
    endgroup

    // -----------------------------------------------------------------------
    // COV_002: Read address + response coverage
    // -----------------------------------------------------------------------
    covergroup cg_read_addr;
        cp_addr: coverpoint tr.addr {
            bins status  = {0};
            bins data_lo = {1};
            bins data_hi = {2};
            bins oob     = {[3:$]};
        }
        cp_rresp: coverpoint tr.rresp {
            bins okay   = {2'b00};
            bins slverr = {2'b10};
        }
        cx_addr_rresp: cross cp_addr, cp_rresp;
    endgroup

    // -----------------------------------------------------------------------
    // COV_003: Control register field coverage
    // -----------------------------------------------------------------------
    covergroup cg_ctrl_reg;
        cp_mode: coverpoint tr.wdata[2:0] {
            bins mode_0 = {3'd0};
            bins mode_1 = {3'd1};
            bins mode_2 = {3'd2};
            bins mode_3 = {3'd3};
            bins mode_4 = {3'd4};
            bins rsvd   = {[3'd5:3'd7]};
        }
        cp_key_sel: coverpoint tr.wdata[4:3] {
            bins ks_128     = {2'd0};
            bins ks_192     = {2'd1};
            bins ks_256     = {2'd2};
            bins ks_invalid = {2'd3};
        }
        cp_enc_dec: coverpoint tr.wdata[5] {
            bins decrypt = {1'b0};
            bins encrypt = {1'b1};
        }
        cp_enable: coverpoint tr.wdata[6] {
            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }
        cx_mode_key:    cross cp_mode, cp_key_sel;
        cx_mode_encdec: cross cp_mode, cp_enc_dec;
    endgroup

    // -----------------------------------------------------------------------
    // COV_004: Write response (BRESP) coverage
    // -----------------------------------------------------------------------
    covergroup cg_write_resp;
        cp_bresp: coverpoint tr.bresp {
            bins okay   = {2'b00};
            bins slverr = {2'b10};
        }
    endgroup

    // -----------------------------------------------------------------------
    // COV_005: Out-of-bounds address stress coverage
    // -----------------------------------------------------------------------
    covergroup cg_oob;
        cp_wr_oob: coverpoint (tr.kind == axi_seq_item::AXI_WRITE && tr.addr > 16) {
            bins hit  = {1};
            bins miss = {0};
        }
        cp_rd_oob: coverpoint (tr.kind == axi_seq_item::AXI_READ && tr.addr > 2) {
            bins hit  = {1};
            bins miss = {0};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_write_addr = new();
        cg_read_addr  = new();
        cg_ctrl_reg   = new();
        cg_write_resp = new();
        cg_oob        = new();
    endfunction

    function void write(axi_seq_item t);
        tr = t;
        cg_oob.sample();
        if (t.kind == axi_seq_item::AXI_WRITE) begin
            cg_write_addr.sample();
            cg_write_resp.sample();
            if (t.addr == 0)
                cg_ctrl_reg.sample();
        end else begin
            cg_read_addr.sample();
        end
    endfunction

    // -----------------------------------------------------------------------
    // Formatted summary – called from report_phase in the test
    // -----------------------------------------------------------------------
    function void print_coverage_summary();
        real wr_cov   = cg_write_addr.get_coverage();
        real rd_cov   = cg_read_addr.get_coverage();
        real ctrl_cov = cg_ctrl_reg.get_coverage();
        real resp_cov = cg_write_resp.get_coverage();
        real oob_cov  = cg_oob.get_coverage();
        real mode_key_cov    = cg_ctrl_reg.cx_mode_key.get_coverage();
        real mode_encdec_cov = cg_ctrl_reg.cx_mode_encdec.get_coverage();
        real total    = (wr_cov + rd_cov + ctrl_cov + resp_cov + oob_cov +
                         mode_key_cov + mode_encdec_cov) / 7.0;

        `uvm_info("COV", "----------------------------------------------------------------", UVM_NONE)
        `uvm_info("COV", "                    COVERAGE SUMMARY                           ", UVM_NONE)
        `uvm_info("COV", "----------------------------------------------------------------", UVM_NONE)
        `uvm_info("COV", $sformatf("COV_001 Transaction Kind Coverage               %6.2f%%",
                  (cg_oob.cp_wr_oob.get_coverage() + cg_oob.cp_rd_oob.get_coverage()) / 2.0), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Write transactions          (bin)          %6.2f%%",
                  cg_oob.cp_wr_oob.get_coverage()),  UVM_NONE)
        `uvm_info("COV", $sformatf("|    Read  transactions          (bin)          %6.2f%%",
                  cg_oob.cp_rd_oob.get_coverage()),  UVM_NONE)
        `uvm_info("COV", $sformatf("COV_002 Write Address Coverage                  %6.2f%%", wr_cov), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Addr 0 - Control            (bin)          %6.2f%%",
                  cg_write_addr.cp_addr.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Addr 1..4 - Key2            (bin)          %6.2f%%",
                  cg_write_addr.cp_addr.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Addr 5..8 - Key1            (bin)          %6.2f%%",
                  cg_write_addr.cp_addr.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Addr 9..12 - IV             (bin)          %6.2f%%",
                  cg_write_addr.cp_addr.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Addr 13..16 - DataIn        (bin)          %6.2f%%",
                  cg_write_addr.cp_addr.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("COV_003 Read Address Coverage                   %6.2f%%", rd_cov), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Addr 0 - Status             (bin)          %6.2f%%",
                  cg_read_addr.cp_addr.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Addr 1 - DataOut            (bin)          %6.2f%%",
                  cg_read_addr.cp_addr.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("COV_004 Control Word Field Coverage              %6.2f%%", ctrl_cov), UVM_NONE)
        `uvm_info("COV", $sformatf("|    ModeSelect  coverage        (bins)         %6.2f%%",
                  cg_ctrl_reg.cp_mode.get_coverage()),    UVM_NONE)
        `uvm_info("COV", $sformatf("|    KeySelect   coverage        (bins)         %6.2f%%",
                  cg_ctrl_reg.cp_key_sel.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Enc/Dec     coverage        (bins)         %6.2f%%",
                  cg_ctrl_reg.cp_enc_dec.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("|    Enable_MSU  coverage        (bins)         %6.2f%%",
                  cg_ctrl_reg.cp_enable.get_coverage()),  UVM_NONE)
        `uvm_info("COV", $sformatf("COV_005 Mode x KeySelect Cross                  %6.2f%%", mode_key_cov),    UVM_NONE)
        `uvm_info("COV", $sformatf("COV_006 Mode x Enc/Dec Cross                    %6.2f%%", mode_encdec_cov), UVM_NONE)
        `uvm_info("COV", $sformatf("COV_007 Error State Coverage                    %6.2f%%", oob_cov),         UVM_NONE)
        `uvm_info("COV", $sformatf("COV_008 Write Response (BRESP) Coverage         %6.2f%%", resp_cov),        UVM_NONE)
        `uvm_info("COV", "----------------------------------------------------------------", UVM_NONE)
        `uvm_info("COV", $sformatf("TOTAL (avg of 7 groups)                          %6.2f%%", total), UVM_NONE)
        `uvm_info("COV", "----------------------------------------------------------------", UVM_NONE)
    endfunction

endclass

`endif