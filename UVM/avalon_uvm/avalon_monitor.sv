// =============================================================================
// File        : avalon_monitor.sv
// Description : UVM monitor for AvalonMM_MSU.
//
//   Passively observes the Avalon-MM interface and the MSU sideband signals.
//   Emits two categories of avalon_transaction:
//     • A WRITE transaction when write_h is seen and waitrequest deasserts
//     • A READ  transaction when readdatavalid_h pulses (carries rdata)
//
//   Also logs sideband changes (Enable_MSU, RST_MSU, Status) for debug.
// =============================================================================
`ifndef AVALON_MONITOR_SV
`define AVALON_MONITOR_SV

class avalon_monitor extends uvm_monitor;
    `uvm_component_utils(avalon_monitor)

    virtual avalon_if vif;
    uvm_analysis_port #(avalon_transaction) ap;

    function new(string name = "avalon_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual avalon_if)::get(this, "", "avalon_if", vif))
            `uvm_error(get_type_name(), "Virtual interface not found in config_db")
    endfunction

    // -------------------------------------------------------------------------
    // Capture one Avalon write beat (after waitrequest deasserts)
    // -------------------------------------------------------------------------
    function avalon_transaction capture_write();
        avalon_transaction tr = avalon_transaction::type_id::create("mon_wr");
        tr.kind    = avalon_transaction::AVALON_WRITE;
        tr.address = vif.monitor_cb.address_h;
        tr.wdata   = vif.monitor_cb.writedata_h;
        tr.av_error = vif.monitor_cb.error;
        return tr;
    endfunction

    // -------------------------------------------------------------------------
    // Capture one Avalon read response
    // -------------------------------------------------------------------------
    function avalon_transaction capture_read();
        avalon_transaction tr = avalon_transaction::type_id::create("mon_rd");
        tr.kind     = avalon_transaction::AVALON_READ;
        tr.address  = vif.monitor_cb.address_h;
        tr.rdata    = vif.monitor_cb.readdata_h;
        tr.rd_valid = 1'b1;
        tr.av_error = vif.monitor_cb.error;
        return tr;
    endfunction

    // -------------------------------------------------------------------------
    // Run phase: two parallel threads
    //   Thread A: observe write beats
    //   Thread B: observe read completions
    // -------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        fork
            observe_writes();
            observe_reads();
            observe_sideband();
        join
    endtask

    // ---- Write observer -----------------------------------------------------
    task observe_writes();
        avalon_transaction tr;
        forever begin
            // Wait for write_h to be asserted
            @(vif.monitor_cb iff (vif.monitor_cb.write_h === 1'b1 &&
                                   vif.monitor_cb.read_h  === 1'b0));
            // Wait until waitrequest de-asserts (write accepted)
            while (vif.monitor_cb.waitrequest_h === 1'b1)
                @(vif.monitor_cb);

            tr = capture_write();
            `uvm_info("MON", $sformatf("WRITE addr=0x%0h data=0x%032h",
                      tr.address, tr.wdata), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

    // ---- Read observer ------------------------------------------------------
    task observe_reads();
        avalon_transaction tr;
        forever begin
            // Capture when readdatavalid pulses
            @(vif.monitor_cb iff (vif.monitor_cb.readdatavalid_h === 1'b1));
            tr = capture_read();
            `uvm_info("MON", $sformatf("READ  addr=0x%0h rdata=0x%032h err=%b",
                      tr.address, tr.rdata, tr.av_error), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

    // ---- Sideband observer (informational only) ------------------------------
    task observe_sideband();
        logic prev_en  = 1'b0;
        logic prev_rst = 1'b1;
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.Enable_MSU !== prev_en) begin
                `uvm_info("MON", $sformatf("Enable_MSU -> %b", vif.monitor_cb.Enable_MSU),
                          UVM_LOW)
                prev_en = vif.monitor_cb.Enable_MSU;
            end
            if (vif.monitor_cb.RST_MSU !== prev_rst) begin
                `uvm_info("MON", $sformatf("RST_MSU    -> %b", vif.monitor_cb.RST_MSU),
                          UVM_LOW)
                prev_rst = vif.monitor_cb.RST_MSU;
            end
            if (vif.monitor_cb.OF === 1'b1) begin
                `uvm_info("MON", $sformatf("OF pulsed — DataOut=0x%032h",
                          vif.monitor_cb.DataOut), UVM_LOW)
            end
        end
    endtask

endclass : avalon_monitor

`endif // AVALON_MONITOR_SV
