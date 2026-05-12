// =============================================================================
// File        : avalon_driver.sv
// Description : UVM driver for AvalonMM_MSU.
//
//   Implements Avalon-MM single-transfer protocol:
//     WRITE: Assert write_h + address + writedata on a clock edge.
//            Deassert after one cycle of waitrequest_h = 1 completes
//            (i.e. release when waitrequest goes low).
//     READ:  Assert read_h + address.  Hold until waitrequest deasserts.
//            Then wait for readdatavalid_h to capture readdata_h.
//
//   MSU stub: if the transaction carries of_pulse=1, the driver waits
//   of_delay_cycles after the write completes and then pulses OF for one
//   cycle with msu_dataout on DataOut, simulating the MSU completing.
// =============================================================================
`ifndef AVALON_DRIVER_SV
`define AVALON_DRIVER_SV

class avalon_driver extends uvm_driver #(avalon_transaction);
    `uvm_component_utils(avalon_driver)

    virtual avalon_if vif;

    // Max cycles to wait for waitrequest de-assertion
    localparam int MAX_WAIT = 20;
    // Max cycles to wait for readdatavalid
    localparam int MAX_RDV  = 20;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual avalon_if)::get(this, "", "avalon_if", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config_db")
    endfunction

    // -------------------------------------------------------------------------
    // Idle the bus
    // -------------------------------------------------------------------------
    task drive_idle();
        vif.master_cb.write_h     <= 1'b0;
        vif.master_cb.read_h      <= 1'b0;
        vif.master_cb.address_h   <= '0;
        vif.master_cb.writedata_h <= '0;
        vif.master_cb.OF          <= 1'b0;
        vif.master_cb.RF          <= 1'b0;
        vif.master_cb.DataOut     <= '0;
    endtask

    // -------------------------------------------------------------------------
    // Drive a write transaction
    // -------------------------------------------------------------------------
    task do_write(avalon_transaction tr);
        int unsigned cyc;
        // Present signals
        @(vif.master_cb);
        vif.master_cb.address_h   <= tr.address;
        vif.master_cb.writedata_h <= tr.wdata;
        vif.master_cb.write_h     <= 1'b1;
        vif.master_cb.read_h      <= 1'b0;

        // DUT will assert waitrequest on the next clock; hold until released
        cyc = 0;
        @(vif.master_cb);
        while (vif.master_cb.waitrequest_h === 1'b1) begin
            cyc++;
            if (cyc >= MAX_WAIT) begin
                `uvm_error("DRV", $sformatf(
                    "WRITE waitrequest stuck HIGH for %0d cycles (addr=0x%0h)",
                    cyc, tr.address))
                break;
            end
            @(vif.master_cb);
        end

        // De-assert
        vif.master_cb.write_h     <= 1'b0;
        vif.master_cb.address_h   <= '0;
        vif.master_cb.writedata_h <= '0;

        // Optionally pulse OF to simulate MSU output ready
        if (tr.of_pulse) begin
            repeat (tr.of_delay_cycles) @(vif.master_cb);
            vif.master_cb.DataOut <= tr.msu_dataout;
            vif.master_cb.OF      <= 1'b1;
            @(vif.master_cb);
            vif.master_cb.OF      <= 1'b0;
            vif.master_cb.DataOut <= '0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Drive a read transaction; capture readdata_h
    // -------------------------------------------------------------------------
    task do_read(avalon_transaction tr);
        int unsigned cyc;
        // Present signals
        @(vif.master_cb);
        vif.master_cb.address_h <= tr.address;
        vif.master_cb.read_h    <= 1'b1;
        vif.master_cb.write_h   <= 1'b0;

        // Hold while waitrequest is high
        cyc = 0;
        @(vif.master_cb);
        while (vif.master_cb.waitrequest_h === 1'b1) begin
            cyc++;
            if (cyc >= MAX_WAIT) begin
                `uvm_error("DRV", $sformatf(
                    "READ waitrequest stuck HIGH for %0d cycles (addr=0x%0h)",
                    cyc, tr.address))
                break;
            end
            @(vif.master_cb);
        end

        // De-assert read
        vif.master_cb.read_h    <= 1'b0;
        vif.master_cb.address_h <= '0;

        // Wait for readdatavalid
        cyc = 0;
        while (vif.monitor_cb.readdatavalid_h !== 1'b1) begin
            @(vif.master_cb);
            cyc++;
            if (cyc >= MAX_RDV) begin
                `uvm_error("DRV", $sformatf(
                    "READ readdatavalid stuck LOW for %0d cycles (addr=0x%0h)",
                    cyc, tr.address))
                tr.rd_valid = 1'b0;
                return;
            end
        end

        tr.rdata    = vif.monitor_cb.readdata_h;
        tr.av_error = vif.monitor_cb.error;
        tr.rd_valid = 1'b1;
    endtask

    // -------------------------------------------------------------------------
    // Run phase
    // -------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        avalon_transaction tr;
        super.run_phase(phase);

        // Safe defaults
        drive_idle();
        vif.master_cb.RST <= 1'b1;
        @(vif.master_cb);
        @(vif.master_cb);
        vif.master_cb.RST <= 1'b0;
        @(vif.master_cb);

        forever begin
            seq_item_port.get_next_item(tr);
            `uvm_info("DRV", $sformatf("Driving: %s", tr.convert2string()), UVM_HIGH)

            if (tr.kind == avalon_transaction::AVALON_WRITE)
                do_write(tr);
            else
                do_read(tr);

            @(vif.master_cb); // 1-cycle gap between transactions
            seq_item_port.item_done();
        end
    endtask

endclass : avalon_driver

`endif // AVALON_DRIVER_SV
