// =============================================================================
// File        : cipher_env.sv
// Description : UVM environment — wires agent, scoreboard, and coverage
//               together and distributes the virtual interface.
// =============================================================================
`ifndef CIPHER_ENV_SV
`define CIPHER_ENV_SV

class cipher_env extends uvm_env;
  `uvm_component_utils(cipher_env)

  cipher_agent      agent;
  cipher_scoreboard scoreboard;
  cipher_coverage   coverage;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = cipher_agent     ::type_id::create("agent",      this);
    scoreboard = cipher_scoreboard::type_id::create("scoreboard", this);
    coverage   = cipher_coverage  ::type_id::create("coverage",   this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Monitor output observations -> scoreboard (for DUT result)
    agent.monitor.ap.connect(scoreboard.ap);
    // Driver stamped items -> scoreboard (for test identity: name/mode/tc_id)
    agent.ap_drv.connect(scoreboard.ap_drv);
    // Monitor -> coverage collector
    agent.monitor.ap.connect(coverage.analysis_export);
  endfunction

endclass : cipher_env

`endif // CIPHER_ENV_SV