// =============================================================================
// File        : cipher_monitor.sv
// Description : UVM monitor for cipher_unit.
//               Observes the interface passively: captures the input when
//               input_taken is asserted and the output when Valid is high.
//               Sends both events as separate cipher_transaction objects via
//               the analysis port so the scoreboard and coverage collector can
//               independently consume them.
// =============================================================================
`ifndef CIPHER_MONITOR_SV
`define CIPHER_MONITOR_SV

class cipher_monitor extends uvm_monitor;
  `uvm_component_utils(cipher_monitor)

  virtual cipher_unit_interface vif;
  uvm_analysis_port #(cipher_transaction) ap;

  function new(string name = "cipher_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db #(virtual cipher_unit_interface)::get(
          this, "", "cipher_unit_interface", vif))
      `uvm_error(get_type_name(), "Virtual interface not found in config DB")
  endfunction

  // ---------------------------------------------------------------------------
  // Capture a snapshot of all interface signals into a transaction
  // ---------------------------------------------------------------------------
  function cipher_transaction capture_input();
    cipher_transaction tr = cipher_transaction::type_id::create("mon_input");
    tr.is_output = 1'b0;
    tr.Data    = {vif.state_i[3], vif.state_i[2], vif.state_i[1], vif.state_i[0]};
    tr.Key     = {vif.KEY[7], vif.KEY[6], vif.KEY[5], vif.KEY[4],
                  vif.KEY[3], vif.KEY[2], vif.KEY[1], vif.KEY[0]};
    tr.KL      = vif.KL;
    tr.enc_dec = vif.enc_dec;
    // test_name / mode_str / tc_id are not on the interface wires;
    // identity is carried via the driver's separate analysis port.
    return tr;
  endfunction

  function cipher_transaction capture_output(cipher_transaction in_tr);
    cipher_transaction tr = cipher_transaction::type_id::create("mon_output");
    tr.is_output  = 1'b1;
    // Carry ALL input fields forward — including identity fields stamped by
    // the sequence — so the scoreboard can index by test_name correctly.
    tr.Data      = in_tr.Data;
    tr.Key       = in_tr.Key;
    tr.KL        = in_tr.KL;
    tr.enc_dec   = in_tr.enc_dec;
    tr.test_name = in_tr.test_name;
    tr.mode_str  = in_tr.mode_str;
    tr.tc_id     = in_tr.tc_id;
    tr.dut_result = {vif.state_o[3], vif.state_o[2], vif.state_o[1], vif.state_o[0]};
    return tr;
  endfunction

  // ---------------------------------------------------------------------------
  // Run phase
  // ---------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    cipher_transaction in_tr;

    forever begin
      // 1. Wait for driver to signal it is presenting data
      @(posedge vif.input_taken);
      if (!vif.driver_started) continue;

      // Capture input at this edge
      // Note: test_name/mode_str/tc_id are NOT on the interface wires, so the
      // monitor's input transaction will have default values for those fields.
      // The scoreboard gets identity from the driver's ap_drv port instead.
      in_tr = capture_input();
      ap.write(in_tr);

      `uvm_info("MON",
        $sformatf("INPUT  | KL=%0d enc=%0d Data=0x%032h Key[127:0]=0x%032h",
                  in_tr.KL, in_tr.enc_dec, in_tr.Data, in_tr.Key[127:0]),
        UVM_MEDIUM)

      // 2. Wait for DUT to produce a valid result
      //    The spec says Valid goes high when output is ready; CF goes high
      //    simultaneously to ask for the next block.
      @(posedge vif.CLK iff (vif.Valid === 1'b1));

      // Capture output
      begin
        cipher_transaction out_tr = capture_output(in_tr);
        ap.write(out_tr);

        `uvm_info("MON",
          $sformatf("OUTPUT | KL=%0d enc=%0d DUT=0x%032h",
                    out_tr.KL, out_tr.enc_dec, out_tr.dut_result),
          UVM_MEDIUM)
      end
    end
  endtask

endclass : cipher_monitor

`endif // CIPHER_MONITOR_SV