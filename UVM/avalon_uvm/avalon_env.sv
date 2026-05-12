// =============================================================================
// File        : avalon_env.sv
// Description : UVM environment for AvalonMM_MSU.
//               Wires the agent, scoreboard, and coverage collector.
// =============================================================================
`ifndef AVALON_ENV_SV
`define AVALON_ENV_SV

class avalon_env extends uvm_env;
    `uvm_component_utils(avalon_env)

    avalon_agent      agent;
    avalon_scoreboard scoreboard;
    avalon_coverage   coverage;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = avalon_agent     ::type_id::create("agent",      this);
        scoreboard = avalon_scoreboard::type_id::create("scoreboard", this);
        coverage   = avalon_coverage  ::type_id::create("coverage",   this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(scoreboard.ap);
        agent.ap.connect(coverage.analysis_export);
    endfunction

endclass : avalon_env

`endif // AVALON_ENV_SV
