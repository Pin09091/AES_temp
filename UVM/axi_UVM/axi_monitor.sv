`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    virtual axi_if.monitor_mp vif;

    // Observed transactions forwarded to scoreboard
    uvm_analysis_port #(axi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual axi_if.monitor_mp)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "axi_monitor: virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            axi_seq_item obs;
            // Wait for a valid write or read beat
            @(vif.monitor_cb);
            if (vif.monitor_cb.AWVALID && vif.monitor_cb.AWREADY &&
                vif.monitor_cb.WVALID  && vif.monitor_cb.WREADY) begin
                obs = axi_seq_item::type_id::create("obs_wr");
                obs.kind  = axi_seq_item::AXI_WRITE;
                obs.addr  = vif.monitor_cb.AWADDR;
                obs.wdata = vif.monitor_cb.WDATA;
                obs.wstrb = vif.monitor_cb.WSTRB;
                // Capture response on next BVALID
                @(vif.monitor_cb iff vif.monitor_cb.BVALID);
                obs.bresp = vif.monitor_cb.BRESP;
                ap.write(obs);
            end
            else if (vif.monitor_cb.ARVALID && vif.monitor_cb.ARREADY) begin
                obs = axi_seq_item::type_id::create("obs_rd");
                obs.kind = axi_seq_item::AXI_READ;
                obs.addr = vif.monitor_cb.ARADDR;
                @(vif.monitor_cb iff vif.monitor_cb.RVALID);
                obs.rdata = vif.monitor_cb.RDATA;
                obs.rresp = vif.monitor_cb.RRESP;
                ap.write(obs);
            end
        end
    endtask
endclass

`endif