`ifndef AXI_TESTS_SV
`define AXI_TESTS_SV

// ===========================================================================
// Base test
// ===========================================================================
class axi_base_test extends uvm_test;
    `uvm_component_utils(axi_base_test)
    axi_env env;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_env::type_id::create("env", this);
    endfunction

    // Apply reset, set interface_toggle=1 (AXI mode), and sync the
    // scoreboard shadow so it matches the freshly-reset DUT.
    task apply_reset(virtual axi_if vif, int unsigned cycles = 5);
        vif.interface_toggle = 1;
        vif.ARESETn  = 0;
        vif.AWVALID  = 0;  vif.WVALID  = 0;  vif.BREADY  = 1;
        vif.ARVALID  = 0;  vif.RREADY  = 1;
        vif.OF       = 0;  vif.RF      = 0;  vif.DataOut = '0;
        repeat (cycles) @(posedge vif.clk);
        vif.ARESETn = 1;
        @(posedge vif.clk);
        env.sb.reset_shadow();
    endtask

    // Called once after all run_phase children finish –
    // print results table then coverage summary (single call each)
    function void report_phase(uvm_phase phase);
        env.sb.print_results_table();
        env.cov.print_coverage_summary();
    endfunction
endclass

// ===========================================================================
// ALL_TESTS – 7 scenarios, each explicitly labelled on the scoreboard before
// the sequence starts so no sub-sequence can override the label.
// Use: +UVM_TESTNAME=all_tests
// ===========================================================================
class all_tests extends axi_base_test;
    `uvm_component_utils(all_tests)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        axi_write_cfg_seq    cfg_seq;
        axi_read_output_seq  rd_seq;
        axi_oob_addr_seq     oob_seq;
        axi_invalid_ctrl_seq inv_seq;
        axi_mode_sweep_seq   ms_seq;
        axi_wstrb_seq        wstrb_seq;
        axi_random_seq       rnd_seq;
        virtual axi_if       vif;

        phase.raise_objection(this);

        if (!uvm_config_db #(virtual axi_if)::get(this, "", "vif_plain", vif))
            `uvm_fatal("NO_VIF", "all_tests: plain vif not found")

        // ---- TC_001  Write Configuration ---------------------------------
        apply_reset(vif);
        env.sb.set_scenario("TC_001_WRITE_CFG", "WRITE");
        cfg_seq             = axi_write_cfg_seq::type_id::create("cfg1");
        cfg_seq.sb_h        = env.sb;
        cfg_seq.mode_select = 3'b001;
        cfg_seq.key_select  = 2'b00;
        cfg_seq.enc_dec     = 1'b1;
        cfg_seq.key1        = 128'h5468617473206D79204B756E67204675;
        cfg_seq.key2        = 128'h0;
        cfg_seq.iv          = 128'h0;
        cfg_seq.data_in     = 128'h54776F204F6E65204E696E652054776F;
        cfg_seq.start(env.agent.seqr);

        // ---- TC_002  Full Flow (write config + OF stub + read output) ----
        // Set scenario before AND after the write so the read transactions
        // are also attributed to TC_002 not TC_001.
        apply_reset(vif);
        env.sb.set_scenario("TC_002_FULL_FLOW", "FLOW");
        fork
            begin
                repeat(200) @(posedge vif.clk);
                vif.OF      = 1;
                vif.DataOut = 128'hAABB_CCDD_EEFF_0011_2233_4455_6677_8899;
                @(posedge vif.clk);
                vif.OF = 0;
            end
        join_none
        cfg_seq             = axi_write_cfg_seq::type_id::create("cfg2");
        cfg_seq.sb_h        = env.sb;
        cfg_seq.mode_select = 3'b001;
        cfg_seq.key_select  = 2'b00;
        cfg_seq.enc_dec     = 1'b1;
        cfg_seq.key1        = 128'hDEAD_BEEF_DEAD_BEEF_DEAD_BEEF_DEAD_BEEF;
        cfg_seq.key2        = 128'hCAFE_BABE_CAFE_BABE_CAFE_BABE_CAFE_BABE;
        cfg_seq.iv          = 128'h01010101_01010101_01010101_01010101;
        cfg_seq.data_in     = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        cfg_seq.start(env.agent.seqr);
        env.sb.set_scenario("TC_002_FULL_FLOW", "FLOW"); // re-label after cfg writes
        rd_seq      = axi_read_output_seq::type_id::create("rd1");
        rd_seq.sb_h = env.sb;
        rd_seq.start(env.agent.seqr);

        // ---- TC_003  Mode Sweep (30 combinations) ------------------------
        // Re-set scenario after sequence returns in case inner writes changed it
        apply_reset(vif);
        env.sb.set_scenario("TC_003_MODE_SWEEP", "WRITE");
        ms_seq      = axi_mode_sweep_seq::type_id::create("ms1");
        ms_seq.sb_h = env.sb;
        ms_seq.start(env.agent.seqr);
        env.sb.set_scenario("TC_003_MODE_SWEEP", "WRITE");

        // ---- TC_004  Invalid Control Register ----------------------------
        apply_reset(vif);
        env.sb.set_scenario("TC_004_INV_CTRL", "WRITE");
        inv_seq      = axi_invalid_ctrl_seq::type_id::create("inv1");
        inv_seq.sb_h = env.sb;
        inv_seq.start(env.agent.seqr);

        // ---- TC_005  Out-of-bounds Addresses (SLVERR on both channels) ---
        apply_reset(vif);
        env.sb.set_scenario("TC_005_OOB_ADDR", "OOB");
        oob_seq      = axi_oob_addr_seq::type_id::create("oob1");
        oob_seq.sb_h = env.sb;
        oob_seq.start(env.agent.seqr);

        // ---- TC_006  WSTRB Byte-lane Masking -----------------------------
        apply_reset(vif);
        env.sb.set_scenario("TC_006_WSTRB", "WRITE");
        wstrb_seq      = axi_wstrb_seq::type_id::create("wstrb1");
        wstrb_seq.sb_h = env.sb;
        wstrb_seq.start(env.agent.seqr);

        // ---- TC_007  Random Stress ---------------------------------------
        apply_reset(vif);
        env.sb.set_scenario("TC_007_STRESS", "MIXED");
        rnd_seq          = axi_random_seq::type_id::create("rnd1");
        rnd_seq.sb_h     = env.sb;
        rnd_seq.num_txns = 100;
        rnd_seq.start(env.agent.seqr);

        `uvm_info("TOP", "======== Test plan complete ========", UVM_NONE)
        phase.drop_objection(this);
    endtask
endclass

// ===========================================================================
// Individual standalone tests (for debugging single scenarios)
// ===========================================================================
class axi_sanity_test extends axi_base_test;
    `uvm_component_utils(axi_sanity_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        axi_write_cfg_seq cfg_seq; virtual axi_if vif;
        phase.raise_objection(this);
        if (!uvm_config_db #(virtual axi_if)::get(this,"","vif_plain",vif))
            `uvm_fatal("NO_VIF","")
        apply_reset(vif);
        env.sb.set_scenario("TC_001_WRITE_CFG", "WRITE");
        cfg_seq = axi_write_cfg_seq::type_id::create("cfg");
        cfg_seq.sb_h = env.sb;
        cfg_seq.mode_select = 3'b001; cfg_seq.key_select = 2'b00; cfg_seq.enc_dec = 1;
        cfg_seq.key1 = 128'h0; cfg_seq.key2 = 128'h0;
        cfg_seq.iv   = 128'h0; cfg_seq.data_in = 128'h0;
        cfg_seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass

class axi_oob_test extends axi_base_test;
    `uvm_component_utils(axi_oob_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        axi_oob_addr_seq oob_seq; virtual axi_if vif;
        phase.raise_objection(this);
        if (!uvm_config_db #(virtual axi_if)::get(this,"","vif_plain",vif))
            `uvm_fatal("NO_VIF","")
        apply_reset(vif);
        env.sb.set_scenario("TC_005_OOB_ADDR", "OOB");
        oob_seq = axi_oob_addr_seq::type_id::create("oob");
        oob_seq.sb_h = env.sb;
        oob_seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass

class axi_random_test extends axi_base_test;
    `uvm_component_utils(axi_random_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        axi_random_seq rnd_seq; virtual axi_if vif;
        phase.raise_objection(this);
        if (!uvm_config_db #(virtual axi_if)::get(this,"","vif_plain",vif))
            `uvm_fatal("NO_VIF","")
        apply_reset(vif);
        env.sb.set_scenario("TC_007_STRESS", "MIXED");
        rnd_seq = axi_random_seq::type_id::create("rnd");
        rnd_seq.sb_h = env.sb;
        rnd_seq.num_txns = 100; rnd_seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass

`endif