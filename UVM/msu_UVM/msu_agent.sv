// =============================================================================
// File        : msu_agent.sv
// Description : UVM agent — bundles sequencer, driver, and monitor.
// =============================================================================
`ifndef MSU_AGENT_SV
`define MSU_AGENT_SV

class msu_agent extends uvm_agent;
    `uvm_component_utils(msu_agent)

    uvm_sequencer #(msu_transaction) sequencer;
    msu_driver                       driver;
    msu_monitor                      monitor;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer = uvm_sequencer #(msu_transaction)::type_id::create("sequencer", this);
        driver    = msu_driver ::type_id::create("driver",  this);
        monitor   = msu_monitor::type_id::create("monitor", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass : msu_agent

`endif // MSU_AGENT_SV
