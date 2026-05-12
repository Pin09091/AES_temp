// =============================================================================
// File        : msu_driver.sv
// Description : UVM driver for mode_selection_unit (updated FSM protocol).
//
//  Protocol (one transaction) — updated IOM_CU FSM:
//   1. Drive ALL stimulus signals (config + key + IV + DataIn) stable.
//   2. Notify monitor via input_taken BEFORE RST so it captures the stimulus.
//   3. Assert RST for 2 clock cycles:
//        - State 000 (RST=1): Data_WEN=1, DIn_WEN=1 latches config/key/IV/DataIn.
//   4. Deassert RST — FSM advances 001→010→011→100→101.
//        - State 101: OF=1 for one cycle, loops back to 001.
//   5. Poll OF and capture DataOut on the cycle it is high.
// =============================================================================
`ifndef MSU_DRIVER_SV
`define MSU_DRIVER_SV

class msu_driver extends uvm_driver #(msu_transaction);
    `uvm_component_utils(msu_driver)

    virtual msu_if vif;

    // Maximum cycles to wait for OF before declaring a timeout
    localparam int MAX_WAIT = 2000;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual msu_if)::get(this, "", "msu_if", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    endfunction

    // -------------------------------------------------------------------------
    // Reset helpers
    // -------------------------------------------------------------------------

    // Drive RST high for n cycles then release
    task do_reset(int unsigned n = 2);
        vif.RST <= 1'b1;
        repeat (n) @(posedge vif.CLK);
        vif.RST <= 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // Apply all stimulus fields from a transaction
    // -------------------------------------------------------------------------
    task apply_stimulus(msu_transaction tr);
        vif.DataIn     <= tr.DataIn;
        vif.KeyIn1     <= tr.KeyIn1;
        vif.KeyIn2     <= tr.KeyIn2;
        vif.IVIn       <= tr.IVIn;
        vif.ModeSelect <= tr.ModeSelect;
        vif.KeySelect  <= tr.KeySelect;
        vif.enc_dec    <= tr.enc_dec;
    endtask

    // -------------------------------------------------------------------------
    // Run phase
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        msu_transaction tr;
        super.run_phase(phase);

        // Safe defaults
        vif.driver_started <= 1'b0;
        vif.input_taken    <= 1'b0;
        vif.RST        <= 1'b1;
        vif.DataIn     <= '0;
        vif.KeyIn1     <= '0;
        vif.KeyIn2     <= '0;
        vif.IVIn       <= '0;
        vif.ModeSelect <= '0;
        vif.KeySelect  <= '0;
        vif.enc_dec    <= 1'b1;

        // Initial reset
        @(posedge vif.CLK);
        @(posedge vif.CLK);
        vif.RST <= 1'b0;
        @(posedge vif.CLK);

        forever begin
            seq_item_port.get_next_item(tr);

            vif.driver_started <= 1'b1;

            // 1. Put all signals on the bus BEFORE RST so state 000 latches
            //    config, key, IV and DataIn all in a single RST pulse.
            apply_stimulus(tr);
            @(posedge vif.CLK);  // let signals settle combinatorially

            // 2. Notify monitor NOW — stimulus is stable, about to be latched
            vif.input_taken <= 1'b1;
            @(posedge vif.CLK);
            vif.input_taken <= 1'b0;

            // 3. RST pulse — FSM state 000 loads everything, exits to 001
            do_reset(2);

            // 4. Poll for OF — FSM reaches state 101 after AES completes
            begin : wait_of
                int cyc = 0;
                bit timed_out = 0;
                while (vif.OF !== 1'b1) begin
                    @(posedge vif.CLK);
                    cyc++;
                    if (cyc >= MAX_WAIT) begin
                        `uvm_error("DRV", $sformatf(
                            "OF timeout after %0d cycles: %s", cyc, tr.convert2string()))
                        timed_out = 1;
                        break;
                    end
                end
                if (!timed_out) begin
                    tr.dut_result = vif.DataOut;
                    tr.of_seen    = 1'b1;
                end
            end

            // 5. Brief gap before next transaction
            @(posedge vif.CLK);
            vif.driver_started <= 1'b0;

            seq_item_port.item_done();
        end
    endtask

endclass : msu_driver

`endif // MSU_DRIVER_SV