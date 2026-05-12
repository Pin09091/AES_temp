// =============================================================================
// File        : cipher_agent.sv
// Description : UVM agent containing sequencer, driver and monitor.
// =============================================================================
`ifndef CIPHER_AGENT_SV
`define CIPHER_AGENT_SV

class cipher_agent extends uvm_agent;
  `uvm_component_utils(cipher_agent)

  uvm_sequencer #(cipher_transaction) sequencer;
  cipher_driver                       driver;
  cipher_monitor                      monitor;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = uvm_sequencer #(cipher_transaction)::type_id::create("sequencer", this);
    driver    = cipher_driver ::type_id::create("driver",    this);
    monitor   = cipher_monitor::type_id::create("monitor",   this);
  endfunction

  // Expose driver's identity broadcast port so env can connect it to scoreboard
  uvm_analysis_port #(cipher_transaction) ap_drv;

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    ap_drv = driver.ap_drv;  // re-export upward
  endfunction

endclass : cipher_agent

`endif // CIPHER_AGENT_SV