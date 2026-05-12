// =============================================================================
// File        : cipher_scoreboard.sv
// =============================================================================
`ifndef CIPHER_SCOREBOARD_SV
`define CIPHER_SCOREBOARD_SV

import "DPI-C" function void aes_reference(
  input  bit [127:0] data,
  input  bit [255:0] key,
  input  bit [1:0]   KL,
  input  bit         enc_dec,
  output bit [127:0] result
);

// Two imp-port suffixes so the scoreboard can receive from both driver and monitor
`uvm_analysis_imp_decl(_drv)
`uvm_analysis_imp_decl(_mon)

class cipher_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cipher_scoreboard)

  // Driver port — receives the original stamped sequence item (has test_name etc.)
  uvm_analysis_imp_drv #(cipher_transaction, cipher_scoreboard) ap_drv;
  // Monitor port — receives observed DUT outputs
  uvm_analysis_imp_mon #(cipher_transaction, cipher_scoreboard) ap;

  // Separate queues for each port
  cipher_transaction drv_q[$];   // stamped inputs from driver
  cipher_transaction mon_q[$];   // observed outputs from monitor

  // Per-test stats
  int unsigned pass_map[string];
  int unsigned fail_map[string];
  string       mode_map[string];

  int unsigned total_pass;
  int unsigned total_fail;

  string TC_ORDER[13];

  function new(string name = "cipher_scoreboard", uvm_component parent);
    super.new(name, parent);
    total_pass = 0; total_fail = 0;
    TC_ORDER[0]  = "TC_001_ENC_128";  TC_ORDER[1]  = "TC_002_ENC_192";
    TC_ORDER[2]  = "TC_003_ENC_256";  TC_ORDER[3]  = "TC_004_DEC_128";
    TC_ORDER[4]  = "TC_005_DEC_192";  TC_ORDER[5]  = "TC_006_DEC_256";
    TC_ORDER[6]  = "TC_007_KEY_RST";  TC_ORDER[7]  = "TC_008_SOFT_RST";
    TC_ORDER[8]  = "TC_009_HARD_RST"; TC_ORDER[9]  = "TC_010_STRESS";
    TC_ORDER[10] = "TC_011_RND_128";  TC_ORDER[11] = "TC_012_RND_192";
    TC_ORDER[12] = "TC_013_RND_256";
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_drv = new("ap_drv", this);
    ap     = new("ap",     this);
  endfunction

  function void init_entry(string tname, string mstr);
    if (!pass_map.exists(tname)) begin
      pass_map[tname] = 0;
      fail_map[tname] = 0;
      mode_map[tname] = mstr;
    end
  endfunction

  // Called by driver port — queue the stamped input item
  virtual function void write_drv(cipher_transaction tr);
    if (tr.KL <= 2)
      drv_q.push_back(tr);
  endfunction

  // Called by monitor port — queue observed outputs, then try to pair
  virtual function void write_mon(cipher_transaction tr);
    if (tr.is_output) begin
      mon_q.push_back(tr);
      try_pair();
    end
  endfunction

  // Pair one driver item with one monitor output and compare
  function void try_pair();
    cipher_transaction id_tr, out_tr;
    bit [127:0] ref_out;
    bit ok;

    if (drv_q.size() == 0 || mon_q.size() == 0) return;

    id_tr  = drv_q.pop_front();
    out_tr = mon_q.pop_front();

    aes_reference(id_tr.Data, id_tr.Key, id_tr.KL, id_tr.enc_dec, ref_out);
    ok = (out_tr.dut_result === ref_out);

    init_entry(id_tr.test_name, id_tr.mode_str);

    if (ok) begin pass_map[id_tr.test_name]++; total_pass++; end
    else    begin fail_map[id_tr.test_name]++; total_fail++; end

    if (ok)
      `uvm_info("SB",
        $sformatf("PASS | %-16s | KL=%0d %s | 0x%032h -> 0x%032h",
                  id_tr.test_name, id_tr.KL,
                  id_tr.enc_dec ? "ENC" : "DEC",
                  id_tr.Data, out_tr.dut_result), UVM_MEDIUM)
    else
      `uvm_error("SB",
        $sformatf("FAIL | %-16s | KL=%0d %s | 0x%032h | DUT=0x%032h REF=0x%032h",
                  id_tr.test_name, id_tr.KL,
                  id_tr.enc_dec ? "ENC" : "DEC",
                  id_tr.Data, out_tr.dut_result, ref_out))
  endfunction

  // report_phase
  virtual function void report_phase(uvm_phase phase);
    int tw = 66;
    int total = total_pass + total_fail;

    `uvm_info("SB", "", UVM_NONE)
    `uvm_info("SB", {"  ", {tw{"-"}}}, UVM_NONE)
    `uvm_info("SB", "  CIPHER UNIT VERIFICATION RESULT SUMMARY", UVM_NONE)
    `uvm_info("SB", {"  ", {tw{"-"}}}, UVM_NONE)
    `uvm_info("SB",
      $sformatf("  %-18s  %-8s  %5s  %5s  %5s",
                "Test", "Mode", "PASS", "FAIL", "TOTAL"), UVM_NONE)
    `uvm_info("SB", {"  ", {tw{"-"}}}, UVM_NONE)

    foreach (TC_ORDER[i]) begin
      string tname = TC_ORDER[i];
      if (pass_map.exists(tname)) begin
        int p = pass_map[tname];
        int f = fail_map[tname];
        `uvm_info("SB",
          $sformatf("  %-18s  %-8s  %5d  %5d  %5d  [ %s]",
                    tname, mode_map[tname], p, f, p+f,
                    (f == 0) ? "OK" : "!!FAIL!!"), UVM_NONE)
      end
    end

    `uvm_info("SB", {"  ", {tw{"-"}}}, UVM_NONE)
    `uvm_info("SB",
      $sformatf("  %-18s           %5d  %5d  %5d",
                "OVERALL", total_pass, total_fail, total), UVM_NONE)
    `uvm_info("SB",
      $sformatf("  %47s -> %s", "",
                (total_fail == 0) ? "ALL PASS" : "FAILURES DETECTED"), UVM_NONE)
    `uvm_info("SB", {"  ", {tw{"-"}}}, UVM_NONE)
    `uvm_info("SB", "", UVM_NONE)
  endfunction

endclass : cipher_scoreboard

`endif // CIPHER_SCOREBOARD_SV