// =============================================================================
// File        : avalon_agent.sv
// Description : UVM agent — bundles sequencer, driver, and monitor for
//               the AvalonMM_MSU DUT.
// =============================================================================
`ifndef AVALON_AGENT_SV
`define AVALON_AGENT_SV

class avalon_agent extends uvm_agent;
    `uvm_component_utils(avalon_agent)

    uvm_sequencer #(avalon_transaction) sequencer;
    avalon_driver                       driver;
    avalon_monitor                      monitor;

    uvm_analysis_port #(avalon_transaction) ap; // forwarded from monitor

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer = uvm_sequencer #(avalon_transaction)::type_id::create("sequencer", this);
        driver    = avalon_driver ::type_id::create("driver",    this);
        monitor   = avalon_monitor::type_id::create("monitor",   this);
        ap        = new("ap", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(ap);
    endfunction

endclass : avalon_agent

`endif // AVALON_AGENT_SV
