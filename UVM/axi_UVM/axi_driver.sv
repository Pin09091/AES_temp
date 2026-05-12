`ifndef AXI_DRIVER_SV
`define AXI_DRIVER_SV

class axi_driver extends uvm_driver #(axi_seq_item);
    `uvm_component_utils(axi_driver)

    virtual axi_if.master_mp vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual axi_if.master_mp)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "axi_driver: virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        axi_seq_item req;
        // De-assert everything at start
        idle_signals();
        forever begin
            seq_item_port.get_next_item(req);
            if (req.kind == axi_seq_item::AXI_WRITE)
                drive_write(req);
            else
                drive_read(req);
            seq_item_port.item_done();
        end
    endtask

    // ------------------------------------------------------------------
    task idle_signals();
        vif.master_cb.AWVALID <= 0;
        vif.master_cb.AWADDR  <= '0;
        vif.master_cb.WVALID  <= 0;
        vif.master_cb.WDATA   <= '0;
        vif.master_cb.WSTRB   <= '0;
        vif.master_cb.BREADY  <= 1;  // always ready to accept response
        vif.master_cb.ARVALID <= 0;
        vif.master_cb.ARADDR  <= '0;
        vif.master_cb.RREADY  <= 1;
    endtask

    // ------------------------------------------------------------------
    // AXI write: launch AW and W channels concurrently, then collect B
    // ------------------------------------------------------------------
    task drive_write(axi_seq_item req);
        fork
            // Write Address
            begin
                @(vif.master_cb);
                vif.master_cb.AWVALID <= 1;
                vif.master_cb.AWADDR  <= req.addr;
                @(vif.master_cb iff vif.master_cb.AWREADY);
                vif.master_cb.AWVALID <= 0;
            end
            // Write Data
            begin
                @(vif.master_cb);
                vif.master_cb.WVALID <= 1;
                vif.master_cb.WDATA  <= req.wdata;
                vif.master_cb.WSTRB  <= req.wstrb;
                @(vif.master_cb iff vif.master_cb.WREADY);
                vif.master_cb.WVALID <= 0;
            end
        join

        // Collect Write Response
        vif.master_cb.BREADY <= 1;
        @(vif.master_cb iff vif.master_cb.BVALID);
        req.bresp = vif.master_cb.BRESP;
        @(vif.master_cb);
        vif.master_cb.BREADY <= 0;
        @(vif.master_cb);
        vif.master_cb.BREADY <= 1;
    endtask

    // ------------------------------------------------------------------
    // AXI read
    // ------------------------------------------------------------------
    task drive_read(axi_seq_item req);
        @(vif.master_cb);
        vif.master_cb.ARVALID <= 1;
        vif.master_cb.ARADDR  <= req.addr;
        @(vif.master_cb iff vif.master_cb.ARREADY);
        vif.master_cb.ARVALID <= 0;

        vif.master_cb.RREADY <= 1;
        @(vif.master_cb iff vif.master_cb.RVALID);
        req.rdata = vif.master_cb.RDATA;
        req.rresp = vif.master_cb.RRESP;
        @(vif.master_cb);
        vif.master_cb.RREADY <= 0;
        @(vif.master_cb);
        vif.master_cb.RREADY <= 1;
    endtask

endclass

`endif