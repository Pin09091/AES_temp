// =============================================================================
// File        : msu_monitor.sv
// Description : UVM monitor for mode_selection_unit.
//               Passively observes the interface.
//               - Captures the input stimulus when input_taken is asserted.
//               - Captures the output when OF pulses high.
//               Both events are broadcast as separate msu_transaction objects
//               so the scoreboard and coverage collector can consume them.
// =============================================================================
`ifndef MSU_MONITOR_SV
`define MSU_MONITOR_SV

class msu_monitor extends uvm_monitor;
    `uvm_component_utils(msu_monitor)

    virtual msu_if vif;
    uvm_analysis_port #(msu_transaction) ap;

    function new(string name = "msu_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual msu_if)::get(this, "", "msu_if", vif))
            `uvm_error(get_type_name(), "Virtual interface not found in config DB")
    endfunction

    // -------------------------------------------------------------------------
    // Capture input stimulus into a transaction object
    // -------------------------------------------------------------------------
    function msu_transaction capture_input();
        msu_transaction tr = msu_transaction::type_id::create("mon_in");
        tr.is_output  = 1'b0;
        tr.DataIn     = vif.DataIn;
        tr.KeyIn1     = vif.KeyIn1;
        tr.KeyIn2     = vif.KeyIn2;
        tr.IVIn       = vif.IVIn;
        tr.ModeSelect = vif.ModeSelect;
        tr.KeySelect  = vif.KeySelect;
        tr.enc_dec    = vif.enc_dec;
        return tr;
    endfunction

    // Carry input context forward and attach the DUT output
    function msu_transaction capture_output(msu_transaction in_tr);
        msu_transaction tr = msu_transaction::type_id::create("mon_out");
        tr.is_output  = 1'b1;
        tr.DataIn     = in_tr.DataIn;
        tr.KeyIn1     = in_tr.KeyIn1;
        tr.KeyIn2     = in_tr.KeyIn2;
        tr.IVIn       = in_tr.IVIn;
        tr.ModeSelect = in_tr.ModeSelect;
        tr.KeySelect  = in_tr.KeySelect;
        tr.enc_dec    = in_tr.enc_dec;
        tr.dut_result = vif.DataOut;
        tr.of_seen    = vif.OF;
        return tr;
    endfunction

    // -------------------------------------------------------------------------
    // Run phase
    // -------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        msu_transaction in_tr;

        forever begin
            // 1. Wait for driver to present new data
            @(posedge vif.input_taken);
            if (!vif.driver_started) continue;

            // Capture input at this moment
            in_tr = capture_input();
            ap.write(in_tr);
            `uvm_info("MON",
                $sformatf("INPUT  | %s", in_tr.convert2string()),
                UVM_MEDIUM)

            // 2. Wait for OF to pulse — DUT has produced its output
            @(posedge vif.CLK iff (vif.OF === 1'b1));

            begin
                msu_transaction out_tr = capture_output(in_tr);
                ap.write(out_tr);
                `uvm_info("MON",
                    $sformatf("OUTPUT | %s", out_tr.convert2string()),
                    UVM_MEDIUM)
            end
        end
    endtask

endclass : msu_monitor

`endif // MSU_MONITOR_SV
