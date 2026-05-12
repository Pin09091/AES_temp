// =============================================================================
// File        : msu_env.sv
// Description : UVM environment — wires agent, scoreboard, and coverage.
// =============================================================================
`ifndef MSU_ENV_SV
`define MSU_ENV_SV

class msu_env extends uvm_env;
    `uvm_component_utils(msu_env)

    msu_agent      agent;
    msu_scoreboard scoreboard;
    msu_coverage   coverage;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = msu_agent     ::type_id::create("agent",      this);
        scoreboard = msu_scoreboard::type_id::create("scoreboard", this);
        coverage   = msu_coverage  ::type_id::create("coverage",   this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.ap);
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction

endclass : msu_env

`endif // MSU_ENV_SV
