`ifndef AXI_SEQUENCES_SV
`define AXI_SEQUENCES_SV

// ===========================================================================
// Base sequence – helpers shared by all sequences
// ===========================================================================
class axi_base_seq extends uvm_sequence #(axi_seq_item);
    `uvm_object_utils(axi_base_seq)

    axi_scoreboard sb_h;

    function new(string name = "axi_base_seq"); super.new(name); endfunction

    task do_write(logic [63:0] addr, logic [63:0] data,
                  logic [7:0] strb = 8'hFF);
        axi_seq_item req = axi_seq_item::type_id::create("req");
        start_item(req);
        req.kind  = axi_seq_item::AXI_WRITE;
        req.addr  = addr;
        req.wdata = data;
        req.wstrb = strb;
        finish_item(req);
    endtask

    task do_read(logic [63:0] addr, output logic [63:0] rdata);
        axi_seq_item req = axi_seq_item::type_id::create("req");
        start_item(req);
        req.kind = axi_seq_item::AXI_READ;
        req.addr = addr;
        finish_item(req);
        rdata = req.rdata;
    endtask
endclass

// ===========================================================================
// Write Configuration Sequence  (no set_scenario – caller sets it)
// ===========================================================================
class axi_write_cfg_seq extends axi_base_seq;
    `uvm_object_utils(axi_write_cfg_seq)

    rand logic [2:0]   mode_select;
    rand logic [1:0]   key_select;
    rand logic         enc_dec;
    rand logic [127:0] key1, key2, iv, data_in;

    constraint c_valid_mode { mode_select inside {[0:4]}; }
    constraint c_valid_key  { key_select  inside {0,1,2}; }

    function new(string name = "axi_write_cfg_seq"); super.new(name); endfunction

    task body();
        logic [63:0] ctrl;
        // Control word: [2:0]=mode [4:3]=keysel [5]=enc_dec [6]=enable
        ctrl = {57'b0, 1'b1 /*enable*/, enc_dec, key_select, mode_select};
        do_write(0,  ctrl);
        do_write(1,  {key2[63:32],    key2[31:0]});
        do_write(3,  {key2[127:96],   key2[95:64]});
        do_write(5,  {key1[63:32],    key1[31:0]});
        do_write(7,  {key1[127:96],   key1[95:64]});
        do_write(9,  {iv[63:32],      iv[31:0]});
        do_write(11, {iv[127:96],     iv[95:64]});
        do_write(13, {data_in[63:32], data_in[31:0]});
        do_write(15, {data_in[127:96],data_in[95:64]});
        `uvm_info("CFG_SEQ", $sformatf("Config: mode=%0d keysel=%0d enc=%0b",
                  mode_select, key_select, enc_dec), UVM_MEDIUM)
    endtask
endclass

// ===========================================================================
// Read Output Sequence  (no set_scenario – caller sets it)
// ===========================================================================
class axi_read_output_seq extends axi_base_seq;
    `uvm_object_utils(axi_read_output_seq)
    int unsigned poll_limit = 50;
    function new(string name = "axi_read_output_seq"); super.new(name); endfunction

    task body();
        logic [63:0] status_rd, data_lo, data_hi;
        int i;
        for (i = 0; i < poll_limit; i++) begin
            do_read(0, status_rd);
            if (status_rd[3:0] == 4'd3) break;
        end
        if (i == poll_limit)
            `uvm_warning("RD_SEQ", "Timeout polling for output-pending status")
        do_read(1, data_lo);
        do_read(2, data_hi);
        `uvm_info("RD_SEQ", $sformatf("DataOut = 0x%0h_%0h", data_hi, data_lo), UVM_MEDIUM)
    endtask
endclass

// ===========================================================================
// Out-of-bounds address sequence  (no set_scenario – caller sets it)
// ===========================================================================
class axi_oob_addr_seq extends axi_base_seq;
    `uvm_object_utils(axi_oob_addr_seq)
    function new(string name = "axi_oob_addr_seq"); super.new(name); endfunction

    task body();
        logic [63:0] rd;
        do_write(17,     64'hDEAD_BEEF_DEAD_BEEF);
        do_write(64'hFF, 64'hCAFE_BABE_CAFE_BABE);
        do_read(3,      rd);
        do_read(64'hFF, rd);
        `uvm_info("OOB_SEQ", "OOB transactions complete", UVM_MEDIUM)
    endtask
endclass

// ===========================================================================
// WSTRB byte-lane masking sequence  (no set_scenario – caller sets it)
// Tests that only masked bytes are written to Mem_in
// ===========================================================================
class axi_wstrb_seq extends axi_base_seq;
    `uvm_object_utils(axi_wstrb_seq)
    function new(string name = "axi_wstrb_seq"); super.new(name); endfunction

    task body();
        logic [63:0] rd;
        // Lower 32 bits only (WSTRB=0x0F)
        do_write(1, 64'hFFFF_FFFF_AAAA_AAAA, 8'h0F);
        // Upper 32 bits only (WSTRB=0xF0)
        do_write(3, 64'hBBBB_BBBB_FFFF_FFFF, 8'hF0);
        // Full write to a third register
        do_write(5, 64'hCAFE_BABE_DEAD_BEEF, 8'hFF);
        // Read status to exercise read path
        do_read(0, rd);
        `uvm_info("WSTRB_SEQ", "WSTRB byte-lane test complete", UVM_MEDIUM)
    endtask
endclass

// ===========================================================================
// Random stress sequence  (no set_scenario – caller sets it)
// ===========================================================================
class axi_random_seq extends axi_base_seq;
    `uvm_object_utils(axi_random_seq)
    int unsigned num_txns = 50;
    function new(string name = "axi_random_seq"); super.new(name); endfunction

    task body();
        axi_seq_item req;
        repeat (num_txns) begin
            req = axi_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) `uvm_fatal("RAND", "Randomization failed")
            finish_item(req);
        end
    endtask
endclass

// ===========================================================================
// Mode sweep  (no set_scenario – caller sets it)
// ===========================================================================
class axi_mode_sweep_seq extends axi_base_seq;
    `uvm_object_utils(axi_mode_sweep_seq)
    function new(string name = "axi_mode_sweep_seq"); super.new(name); endfunction

    task body();
        axi_write_cfg_seq cfg;
        logic [63:0] dummy;
        for (int m = 0; m <= 4; m++) begin
            for (int k = 0; k <= 2; k++) begin
                for (int e = 0; e <= 1; e++) begin
                    cfg             = axi_write_cfg_seq::type_id::create("cfg");
                    cfg.sb_h        = sb_h;
                    cfg.mode_select = m[2:0];
                    cfg.key_select  = k[1:0];
                    cfg.enc_dec     = e[0];
                    cfg.key1        = {$urandom, $urandom, $urandom, $urandom};
                    cfg.key2        = {$urandom, $urandom, $urandom, $urandom};
                    cfg.iv          = {$urandom, $urandom, $urandom, $urandom};
                    cfg.data_in     = {$urandom, $urandom, $urandom, $urandom};
                    cfg.start(get_sequencer());
                    do_read(0, dummy);
                end
            end
        end
    endtask
endclass

// ===========================================================================
// Invalid control signal sequence  (no set_scenario – caller sets it)
// ===========================================================================
class axi_invalid_ctrl_seq extends axi_base_seq;
    `uvm_object_utils(axi_invalid_ctrl_seq)
    function new(string name = "axi_invalid_ctrl_seq"); super.new(name); endfunction

    task body();
        logic [63:0] ctrl, rd;
        // KeySelect = 3 (invalid)
        ctrl = {57'b0, 1'b1, 1'b1, 2'b11, 3'b001};
        do_write(0, ctrl);
        do_read(0, rd);
        `uvm_info("INV_SEQ", $sformatf("Status after invalid KeySel=3: 0x%0h", rd), UVM_MEDIUM)
        // ModeSelect = 5 (invalid)
        ctrl = {57'b0, 1'b1, 1'b1, 2'b00, 3'b101};
        do_write(0, ctrl);
        do_read(0, rd);
        `uvm_info("INV_SEQ", $sformatf("Status after invalid Mode=5  : 0x%0h", rd), UVM_MEDIUM)
    endtask
endclass

// ===========================================================================
// Full flow  (no set_scenario – caller sets it)
// ===========================================================================
class axi_full_flow_seq extends axi_base_seq;
    `uvm_object_utils(axi_full_flow_seq)
    function new(string name = "axi_full_flow_seq"); super.new(name); endfunction

    task body();
        axi_write_cfg_seq   cfg_seq;
        axi_read_output_seq rd_seq;
        cfg_seq             = axi_write_cfg_seq::type_id::create("cfg_seq");
        cfg_seq.sb_h        = sb_h;
        cfg_seq.mode_select = 3'b001;
        cfg_seq.key_select  = 2'b00;
        cfg_seq.enc_dec     = 1'b1;
        cfg_seq.key1        = 128'hDEAD_BEEF_DEAD_BEEF_DEAD_BEEF_DEAD_BEEF;
        cfg_seq.key2        = 128'hCAFE_BABE_CAFE_BABE_CAFE_BABE_CAFE_BABE;
        cfg_seq.iv          = 128'h01010101_01010101_01010101_01010101;
        cfg_seq.data_in     = 128'h12345678_9ABCDEF0_12345678_9ABCDEF0;
        cfg_seq.start(get_sequencer());
        rd_seq      = axi_read_output_seq::type_id::create("rd_seq");
        rd_seq.sb_h = sb_h;
        rd_seq.start(get_sequencer());
    endtask
endclass

`endif