// =============================================================================
// File        : avalon_sequences.sv
// Description : All test sequences for AvalonMM_MSU.
//
//   av_base_seq        — helpers: av_write(), av_read(), av_write_ctrl()
//   seq_reset          — TC-001  Reset & idle: read Status (addr 0) after reset
//   seq_write_all      — TC-002  Write all 5 registers (DataIn/Key1/Key2/IV/Ctrl)
//   seq_read_both      — TC-003  Read both readable registers (Status + DataOut)
//   seq_full_op_ecb    — TC-004  Full ECB AES-128 encrypt: write→enable→OF→read
//   seq_error_state    — TC-005  Simultaneous R+W via raw wiggle → error state
//   seq_ctrl_modes     — TC-006  All 5 ModeSelect values × all 3 KeySelect values
//   seq_ctrl_encdec    — TC-007  All modes in both encrypt AND decrypt direction
//   seq_invalid_addr   — TC-008  Write to out-of-range address (addr=5, no effect)
//   seq_back_to_back   — TC-009  Back-to-back writes to all regs, then read both
//   seq_stress         — TC-010  Randomised write/read stress (20 iterations)
// =============================================================================
`ifndef AVALON_SEQUENCES_SV
`define AVALON_SEQUENCES_SV

// =============================================================================
// Base sequence — shared write/read helpers
// =============================================================================
class av_base_seq extends uvm_sequence #(avalon_transaction);
    `uvm_object_utils(av_base_seq)
    `uvm_declare_p_sequencer(uvm_sequencer #(avalon_transaction))

    function new(string name = "av_base_seq");
        super.new(name);
    endfunction

    // ---- Issue one Avalon write ---------------------------------------------
    task av_write(input [31:0] addr, input [127:0] data,
                  input bit of_p = 1'b0,
                  input [127:0] of_data = '0,
                  input int unsigned of_dly = 0);
        avalon_transaction tr = avalon_transaction::type_id::create("wr");
        tr.kind             = avalon_transaction::AVALON_WRITE;
        tr.address          = addr;
        tr.wdata            = data;
        tr.of_pulse         = of_p;
        tr.msu_dataout      = of_data;
        tr.of_delay_cycles  = of_dly;
        start_item(tr);
        finish_item(tr);
    endtask

    // ---- Issue one Avalon read; return captured data ------------------------
    task av_read(input [31:0] addr, output [127:0] rdata);
        avalon_transaction tr = avalon_transaction::type_id::create("rd");
        tr.kind    = avalon_transaction::AVALON_READ;
        tr.address = addr;
        start_item(tr);
        finish_item(tr);
        rdata = tr.rdata;
    endtask

    // ---- Write the control register (addr 0) --------------------------------
    // Packs the sub-fields into a 128-bit word matching Mem_in[0] decode.
    //   bits [2:0]  = ModeSelect
    //   bits [4:3]  = KeySelect
    //   bit  [5]    = enc_dec
    //   bit  [6]    = Enable_MSU
    task av_write_ctrl(input [2:0] mode, input [1:0] ksel,
                       input logic enc, input logic en,
                       input bit of_p = 1'b0,
                       input [127:0] of_data = '0,
                       input int unsigned of_dly = 2);
        logic [127:0] ctrl;
        ctrl        = '0;
        ctrl[2:0]   = mode;
        ctrl[4:3]   = ksel;
        ctrl[5]     = enc;
        ctrl[6]     = en;
        av_write(32'h0, ctrl, of_p, of_data, of_dly);
    endtask

endclass : av_base_seq


// =============================================================================
// TC-001 : Reset and idle
//   Reads the Status register (addr 0) immediately after reset to confirm
//   the DUT initialises to idle state (Status = 0, all outputs cleared).
// =============================================================================
class seq_reset extends av_base_seq;
    `uvm_object_utils(seq_reset)

    function new(string name = "seq_reset"); super.new(name); endfunction

    virtual task body();
        logic [127:0] rdata;
        `uvm_info("SEQ", "TC-001: Reset & Idle", UVM_MEDIUM)
        av_read(32'h0, rdata);
        `uvm_info("SEQ", $sformatf("TC-001: Status after reset = 0x%032h", rdata), UVM_MEDIUM)
    endtask

endclass : seq_reset


// =============================================================================
// TC-002 : Write all five input registers sequentially
//   Writes a NIST AES-128 plaintext to DataIn (addr 1), zeroed KeyIn1 (addr 2),
//   a real AES-128 key to KeyIn2 (addr 3), zeroed IV (addr 4), and finally a
//   control word with Enable_MSU=0 to addr 0, confirming all write addresses
//   are reachable via the Avalon interface.
// =============================================================================
class seq_write_all extends av_base_seq;
    `uvm_object_utils(seq_write_all)

    static const logic [127:0] DATAIN = 128'h6bc1bee22e409f96e93d7e117393172a;
    static const logic [127:0] KEY2   = 128'h2b7e151628aed2a6abf7158809cf4f3c;

    function new(string name = "seq_write_all"); super.new(name); endfunction

    virtual task body();
        `uvm_info("SEQ", "TC-002: Write all 5 registers", UVM_MEDIUM)
        av_write(32'h1, DATAIN);
        av_write(32'h2, 128'h0);
        av_write(32'h3, KEY2);
        av_write(32'h4, 128'h0);
        av_write_ctrl(.mode(3'b000), .ksel(2'b00), .enc(1'b1), .en(1'b0));
    endtask

endclass : seq_write_all


// =============================================================================
// TC-003 : Read both readable registers
//   Reads addr 0 (Status register) and addr 1 (DataOut register) to exercise
//   both read-address bins in COV_003.  The DataOut register returns whatever
//   was last latched on an OF pulse; at this point it will be zero.
// =============================================================================
class seq_read_both extends av_base_seq;
    `uvm_object_utils(seq_read_both)

    function new(string name = "seq_read_both"); super.new(name); endfunction

    virtual task body();
        logic [127:0] status, dataout;
        `uvm_info("SEQ", "TC-003: Read Status (addr 0) and DataOut (addr 1)", UVM_MEDIUM)
        av_read(32'h0, status);
        `uvm_info("SEQ", $sformatf("TC-003: Status  = 0x%032h", status),  UVM_MEDIUM)
        av_read(32'h1, dataout);
        `uvm_info("SEQ", $sformatf("TC-003: DataOut = 0x%032h", dataout), UVM_MEDIUM)
    endtask

endclass : seq_read_both


// =============================================================================
// TC-004 : Full ECB AES-128 encrypt operation
//   Performs a complete host transaction cycle:
//     1. Writes plaintext to DataIn (addr 1)
//     2. Writes AES-128 key to KeyIn2 (addr 3)
//     3. Writes control word to addr 0 with Enable_MSU=1, ECB mode, AES-128
//     4. Driver stubs an OF pulse with the expected NIST ciphertext on DataOut
//     5. Reads Status register (addr 0) to observe the FSM state
//     6. Reads DataOut register (addr 1) and scoreboard checks it matches the
//        expected NIST AES-128-ECB ciphertext (3ad77bb4...)
// =============================================================================
class seq_full_op_ecb extends av_base_seq;
    `uvm_object_utils(seq_full_op_ecb)

    static const logic [127:0] DATAIN      = 128'h6bc1bee22e409f96e93d7e117393172a;
    static const logic [127:0] KEY2        = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    static const logic [127:0] EXPECTED_CT = 128'h3ad77bb40d7a3660a89ecaf32466ef97;

    avalon_scoreboard sb_ref;

    function new(string name = "seq_full_op_ecb"); super.new(name); endfunction

    virtual task body();
        logic [127:0] rdata;
        `uvm_info("SEQ", "TC-004: Full ECB AES-128 Encrypt operation", UVM_MEDIUM)

        av_write(32'h1, DATAIN);
        av_write(32'h2, 128'h0);
        av_write(32'h3, KEY2);
        av_write(32'h4, 128'h0);

        if (sb_ref != null) sb_ref.expect_of(EXPECTED_CT);
        av_write_ctrl(.mode(3'b000), .ksel(2'b00), .enc(1'b1), .en(1'b1),
                      .of_p(1'b1), .of_data(EXPECTED_CT), .of_dly(2));

        av_read(32'h0, rdata);
        `uvm_info("SEQ", $sformatf("TC-004: Status  = 0x%032h", rdata), UVM_MEDIUM)
        av_read(32'h1, rdata);
        `uvm_info("SEQ", $sformatf("TC-004: DataOut = 0x%032h", rdata), UVM_MEDIUM)
    endtask

endclass : seq_full_op_ecb


// =============================================================================
// TC-005 : Error state — simultaneous read and write
//   The Avalon FSM enters state 2'b11 when write_h and read_h are both
//   asserted in the same clock cycle, which sets error=1 and holds it until
//   both signals are deasserted.  Because the UVM sequencer is single-threaded,
//   the two signals are driven directly on the virtual interface to achieve a
//   true simultaneous assertion.  After recovery a normal Status read confirms
//   the DUT has returned to idle.  This is the only test that hits the ERROR
//   bin of COV_007.
// =============================================================================
class seq_error_state extends av_base_seq;
    `uvm_object_utils(seq_error_state)

    virtual avalon_if vif;

    function new(string name = "seq_error_state"); super.new(name); endfunction

    virtual task body();
        logic [127:0] rdata;
        `uvm_info("SEQ", "TC-005: Simultaneous R+W — driving raw interface to reach error state",
                  UVM_MEDIUM)

        if (!uvm_config_db #(virtual avalon_if)::get(null, "uvm_test_top.*",
                                                      "avalon_if", vif))
            `uvm_fatal("SEQ", "TC-005: Could not get virtual avalon_if from config_db")

        // Assert both write_h and read_h simultaneously → DUT enters state 2'b11
        @(vif.master_cb);
        vif.master_cb.write_h     <= 1'b1;
        vif.master_cb.read_h      <= 1'b1;
        vif.master_cb.address_h   <= 32'h0;
        vif.master_cb.writedata_h <= 128'h0;

        // Hold two cycles so monitor captures error=1
        @(vif.master_cb);
        @(vif.master_cb);

        // De-assert both → DUT returns to idle
        vif.master_cb.write_h <= 1'b0;
        vif.master_cb.read_h  <= 1'b0;
        @(vif.master_cb);
        @(vif.master_cb);

        `uvm_info("SEQ", "TC-005: Error released — verifying recovery", UVM_MEDIUM)
        av_read(32'h0, rdata);
        `uvm_info("SEQ", $sformatf("TC-005: Status after recovery = 0x%032h (expect 0)",
                  rdata), UVM_MEDIUM)
    endtask

endclass : seq_error_state


// =============================================================================
// TC-006 : Full ModeSelect × KeySelect sweep
//   Writes the control register for every combination of the 5 AES modes
//   (ECB/CBC/OFB/CFB/CTR) and all 3 key lengths (AES-128/192/256), giving
//   15 unique control words.  This directly targets COV_005 (mode×keysel
//   cross) and COV_004 (individual mode and keysel bins).  Enable_MSU is kept
//   low so the MSU is not actually started.
// =============================================================================
class seq_ctrl_modes extends av_base_seq;
    `uvm_object_utils(seq_ctrl_modes)

    function new(string name = "seq_ctrl_modes"); super.new(name); endfunction

    virtual task body();
        logic [2:0] modes[5]  = '{3'b000, 3'b001, 3'b010, 3'b011, 3'b100};
        logic [1:0] ksel_v[3] = '{2'b00,  2'b01,  2'b10};
        string mode_names[5]  = '{"ECB", "CBC", "OFB", "CFB", "CTR"};
        string ksel_names[3]  = '{"AES-128", "AES-192", "AES-256"};

        `uvm_info("SEQ", "TC-006: Full ModeSelect x KeySelect sweep (15 combinations)", UVM_MEDIUM)

        foreach (modes[i]) begin
            foreach (ksel_v[j]) begin
                `uvm_info("SEQ", $sformatf("TC-006: mode=%-3s ksel=%s",
                          mode_names[i], ksel_names[j]), UVM_MEDIUM)
                av_write_ctrl(.mode(modes[i]), .ksel(ksel_v[j]), .enc(1'b1), .en(1'b0));
            end
        end
    endtask

endclass : seq_ctrl_modes


// =============================================================================
// TC-007 : All modes in both encrypt and decrypt directions
//   Writes the control register for all 5 AES modes with enc_dec=1 (encrypt)
//   and then all 5 again with enc_dec=0 (decrypt), using AES-256 throughout
//   to add KeySelect diversity.  This directly targets COV_006 (mode×enc_dec
//   cross) ensuring all 10 bins are hit.
// =============================================================================
class seq_ctrl_encdec extends av_base_seq;
    `uvm_object_utils(seq_ctrl_encdec)

    function new(string name = "seq_ctrl_encdec"); super.new(name); endfunction

    virtual task body();
        logic [2:0] modes[5] = '{3'b000, 3'b001, 3'b010, 3'b011, 3'b100};
        string mode_names[5] = '{"ECB", "CBC", "OFB", "CFB", "CTR"};

        `uvm_info("SEQ", "TC-007: All modes × Encrypt + Decrypt (10 combinations)", UVM_MEDIUM)

        // Encrypt pass — all 5 modes
        foreach (modes[i]) begin
            `uvm_info("SEQ", $sformatf("TC-007: mode=%-3s ENCRYPT", mode_names[i]), UVM_MEDIUM)
            av_write_ctrl(.mode(modes[i]), .ksel(2'b10), .enc(1'b1), .en(1'b0));
        end

        // Decrypt pass — all 5 modes
        foreach (modes[i]) begin
            `uvm_info("SEQ", $sformatf("TC-007: mode=%-3s DECRYPT", mode_names[i]), UVM_MEDIUM)
            av_write_ctrl(.mode(modes[i]), .ksel(2'b10), .enc(1'b0), .en(1'b0));
        end
    endtask

endclass : seq_ctrl_encdec


// =============================================================================
// TC-008 : Write to out-of-range address
//   Writes a non-zero pattern to addr 5, which is outside the valid register
//   map (0–4).  The DUT's default case silently ignores it.  A subsequent
//   Status read at addr 0 confirms the DUT is unaffected.
// =============================================================================
class seq_invalid_addr extends av_base_seq;
    `uvm_object_utils(seq_invalid_addr)

    function new(string name = "seq_invalid_addr"); super.new(name); endfunction

    virtual task body();
        logic [127:0] rdata;
        `uvm_info("SEQ", "TC-008: Write to invalid address (addr=5)", UVM_MEDIUM)
        av_write(32'h5, 128'hDEADBEEF_CAFEBABE_DEADBEEF_CAFEBABE);
        av_read(32'h0, rdata);
        `uvm_info("SEQ", $sformatf("TC-008: Status unchanged = 0x%032h", rdata), UVM_MEDIUM)
    endtask

endclass : seq_invalid_addr


// =============================================================================
// TC-009 : Back-to-back writes then read both registers
//   Writes all 5 registers in immediate succession (no idle cycles between
//   them) to stress the write-path timing, then reads both addr 0 (Status)
//   and addr 1 (DataOut) to exercise the write-then-read sequence coverage
//   (COV_008) and confirm both readable addresses are still accessible.
// =============================================================================
class seq_back_to_back extends av_base_seq;
    `uvm_object_utils(seq_back_to_back)

    function new(string name = "seq_back_to_back"); super.new(name); endfunction

    virtual task body();
        logic [127:0] rdata;
        `uvm_info("SEQ", "TC-009: Back-to-back writes then read both regs", UVM_MEDIUM)
        av_write(32'h4, 128'hAAAAAAAA_BBBBBBBB_CCCCCCCC_DDDDDDDD);
        av_write(32'h3, 128'h11111111_22222222_33333333_44444444);
        av_write(32'h2, 128'h55555555_66666666_77777777_88888888);
        av_write(32'h1, 128'h99999999_AAAAAAAA_BBBBBBBB_CCCCCCCC);
        av_write_ctrl(.mode(3'b001), .ksel(2'b10), .enc(1'b0), .en(1'b0));
        av_read(32'h0, rdata);
        `uvm_info("SEQ", $sformatf("TC-009: Status  = 0x%032h", rdata), UVM_MEDIUM)
        av_read(32'h1, rdata);
        `uvm_info("SEQ", $sformatf("TC-009: DataOut = 0x%032h", rdata), UVM_MEDIUM)
    endtask

endclass : seq_back_to_back


// =============================================================================
// TC-010 : Randomised write/read stress
//   Runs 20 randomised Avalon transactions.  Each transaction is randomly
//   either a WRITE (constrained to valid addresses 0–4) or a READ (constrained
//   to addresses 0–1).  Data and address are fully randomised within those
//   constraints.  This exercises corner cases in the Avalon FSM and adds
//   additional samples to all functional coverage groups.
// =============================================================================
class seq_stress extends av_base_seq;
    `uvm_object_utils(seq_stress)

    int unsigned n_iters = 20;

    function new(string name = "seq_stress"); super.new(name); endfunction

    virtual task body();
        `uvm_info("SEQ", $sformatf("TC-010: Randomised stress (%0d iterations)", n_iters),
                  UVM_MEDIUM)

        repeat (n_iters) begin
            avalon_transaction tr = avalon_transaction::type_id::create("stress");
            if (!tr.randomize() with {
                    kind == avalon_transaction::AVALON_WRITE -> address inside {[0:4]};
                    kind == avalon_transaction::AVALON_READ  -> address inside {0, 1};
                    of_pulse == 1'b0;
                }) begin
                `uvm_error("SEQ", "Randomization failed")
            end
            start_item(tr);
            finish_item(tr);
        end
    endtask

endclass : seq_stress

`endif // AVALON_SEQUENCES_SV

// Description : All test sequences for AvalonMM_MSU.
//
//   av_base_seq       — helpers: av_write(), av_read(), av_write_ctrl()
//   seq_reset         — TC-001  Reset & idle check
//   seq_write_all     — TC-002  Write all 5 registers sequentially
//   seq_read_status   — TC-003  Read Status register (addr 0)
//   seq_full_op_ecb   — TC-004  Full operation: write data+keys, enable,
//                                wait for OF stub, read DataOut
//   seq_error_state   — TC-005  Simultaneous read+write → error state
//   seq_ctrl_modes    — TC-006  All ModeSelect values written to ctrl reg
//   seq_ctrl_keysel   — TC-007  All KeySelect values written to ctrl reg
//   seq_invalid_addr  — TC-008  Write to out-of-range address (addr > 4)
//   seq_back_to_back  — TC-009  Back-to-back writes to all registers
//   seq_stress        — TC-010  Randomised write/read stress (20 iterations)
// =============================================================================
`ifndef AVALON_SEQUENCES_SV
`define AVALON_SEQUENCES_SV

// =============================================================================
// Base sequence — shared write/read helpers
// =============================================================================
class av_base_seq extends uvm_sequence #(avalon_transaction);
    `uvm_object_utils(av_base_seq)
    `uvm_declare_p_sequencer(uvm_sequencer #(avalon_transaction))

    function new(string name = "av_base_seq");
        super.new(name);
    endfunction

    // ---- Issue one Avalon write ---------------------------------------------
    task av_write(input [31:0] addr, input [127:0] data,
                  input bit of_p = 1'b0,
                  input [127:0] of_data = '0,
                  input int unsigned of_dly = 0);
        avalon_transaction tr = avalon_transaction::type_id::create("wr");
        tr.kind             = avalon_transaction::AVALON_WRITE;
        tr.address          = addr;
        tr.wdata            = data;
        tr.of_pulse         = of_p;
        tr.msu_dataout      = of_data;
        tr.of_delay_cycles  = of_dly;
        start_item(tr);
        finish_item(tr);
    endtask

    // ---- Issue one Avalon read; return captured data ------------------------
    task av_read(input [31:0] addr, output [127:0] rdata);
        avalon_transaction tr = avalon_transaction::type_id::create("rd");
        tr.kind    = avalon_transaction::AVALON_READ;
        tr.address = addr;
        start_item(tr);
        finish_item(tr);
        rdata = tr.rdata;
    endtask

    // ---- Write the control register (addr 0) --------------------------------
    // Packs the sub-fields into a 128-bit word matching Mem_in[0] decode.
    //   bits [2:0]  = ModeSelect
    //   bits [4:3]  = KeySelect
    //   bit  [5]    = enc_dec
    //   bit  [6]    = Enable_MSU
    task av_write_ctrl(input [2:0] mode, input [1:0] ksel,
                       input logic enc, input logic en,
                       input bit of_p = 1'b0,
                       input [127:0] of_data = '0,
                       input int unsigned of_dly = 2);
        logic [127:0] ctrl;
        ctrl        = '0;
        ctrl[2:0]   = mode;
        ctrl[4:3]   = ksel;
        ctrl[5]     = enc;
        ctrl[6]     = en;
        av_write(32'h0, ctrl, of_p, of_data, of_dly);
    endtask

endclass : av_base_seq


// =============================================================================
// TC-001 : Reset and idle — verify DUT comes up cleanly
// =============================================================================
class seq_reset extends av_base_seq;
    `uvm_object_utils(seq_reset)

    function new(string name = "seq_reset"); super.new(name); endfunction

    virtual task body();
        logic [127:0] rdata;
        `uvm_info("SEQ", "TC-001: Reset & Idle", UVM_MEDIUM)
        // Read Status immediately after reset — should be 0 (idle)
        av_read(32'h0, rdata);
        `uvm_info("SEQ", $sformatf("TC-001: Status after reset = 0x%032h", rdata), UVM_MEDIUM)
    endtask

endclass : seq_reset


// =============================================================================
// TC-002 : Write all five input registers sequentially
// =============================================================================
class seq_write_all extends av_base_seq;
    `uvm_object_utils(seq_write_all)

    // NIST AES-128-ECB vector
    static const logic [127:0] DATAIN = 128'h6bc1bee22e409f96e93d7e117393172a;
    static const logic [127:0] KEY1   = 128'h0;                                  // not used for AES-128
    static const logic [127:0] KEY2   = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    static const logic [127:0] IV     = 128'h0;

    function new(string name = "seq_write_all"); super.new(name); endfunction

    virtual task body();
        `uvm_info("SEQ", "TC-002: Write all 5 registers", UVM_MEDIUM)
        av_write(32'h1, DATAIN);
        av_write(32'h2, KEY1);
        av_write(32'h3, KEY2);
        av_write(32'h4, IV);
        // Write control last (Enable_MSU = 0 so MSU stays idle)
        av_write_ctrl(.mode(3'b000), .ksel(2'b00), .enc(1'b1), .en(1'b0));
    endtask

endclass : seq_write_all


// =============================================================================
// TC-003 : Read Status register
// =============================================================================
class seq_read_status extends av_base_seq;
    `uvm_object_utils(seq_read_status)

    function new(string name = "seq_read_status"); super.new(name); endfunction

    virtual task body();
        logic [127:0] status;
        `uvm_info("SEQ", "TC-003: Read Status register", UVM_MEDIUM)
        av_read(32'h0, status);
        `uvm_info("SEQ", $sformatf("TC-003: Status = 0x%032h (Status[2:0] = %0d)",
                  status, status[2:0]), UVM_MEDIUM)
    endtask

endclass : seq_read_status


// =============================================================================
// TC-004 : Full operation — ECB AES-128 Encrypt
//   Write data + keys → enable MSU → stub OF pulse → read DataOut
// =============================================================================
class seq_full_op_ecb extends av_base_seq;
    `uvm_object_utils(seq_full_op_ecb)

    static const logic [127:0] DATAIN      = 128'h6bc1bee22e409f96e93d7e117393172a;
    static const logic [127:0] KEY2        = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    // Expected ciphertext for this NIST vector
    static const logic [127:0] EXPECTED_CT = 128'h3ad77bb40d7a3660a89ecaf32466ef97;

    avalon_scoreboard sb_ref; // set by test before start

    function new(string name = "seq_full_op_ecb"); super.new(name); endfunction

    virtual task body();
        logic [127:0] rdata;
        `uvm_info("SEQ", "TC-004: Full ECB AES-128 Encrypt operation", UVM_MEDIUM)

        // 1. Write DataIn, KeyIn2 (AES-128 uses Key2 only)
        av_write(32'h1, DATAIN);
        av_write(32'h2, 128'h0);     // KeyIn1 not used
        av_write(32'h3, KEY2);
        av_write(32'h4, 128'h0);     // No IV for ECB

        // 2. Write control word with Enable_MSU=1; driver will pulse OF after 2 cycles
        if (sb_ref != null) sb_ref.expect_of(EXPECTED_CT);
        av_write_ctrl(.mode(3'b000), .ksel(2'b00), .enc(1'b1), .en(1'b1),
                      .of_p(1'b1), .of_data(EXPECTED_CT), .of_dly(2));

        // 3. Read Status
        av_read(32'h0, rdata);
        `uvm_info("SEQ", $sformatf("TC-004: Status after enable = 0x%032h", rdata), UVM_MEDIUM)

        // 4. Read DataOut register
        av_read(32'h1, rdata);
        `uvm_info("SEQ", $sformatf("TC-004: DataOut read = 0x%032h", rdata), UVM_MEDIUM)

    endtask

endclass : seq_full_op_ecb


// =============================================================================
// TC-005 : Error state — simultaneous read and write (raw interface wiggle)
//
//   The normal UVM sequencer can only issue one transaction at a time, so
//   we bypass it and drive write_h + read_h in the same clock cycle directly
//   on the virtual interface.  This is the only way to hit state 2'b11
//   (error) and get the ERROR bin of COV_007 to 100%.
// =============================================================================
class seq_error_state extends av_base_seq;
    `uvm_object_utils(seq_error_state)

    virtual avalon_if vif;

    function new(string name = "seq_error_state"); super.new(name); endfunction

    virtual task body();
        logic [127:0] rdata;
        `uvm_info("SEQ", "TC-005: Simultaneous R+W — driving raw interface to reach error state",
                  UVM_MEDIUM)

        // Grab the virtual interface directly from the config_db
        if (!uvm_config_db #(virtual avalon_if)::get(null, "uvm_test_top.*",
                                                      "avalon_if", vif))
            `uvm_fatal("SEQ", "TC-005: Could not get virtual avalon_if from config_db")

        // Assert both write_h and read_h in the same cycle → DUT enters state 2'b11
        @(vif.master_cb);
        vif.master_cb.write_h     <= 1'b1;
        vif.master_cb.read_h      <= 1'b1;
        vif.master_cb.address_h   <= 32'h0;
        vif.master_cb.writedata_h <= 128'h0;

        // Hold for two cycles so monitor captures error=1 on both edges
        @(vif.master_cb);
        @(vif.master_cb);

        // De-assert both — DUT returns to idle (state 2'b00) once both clear
        vif.master_cb.write_h <= 1'b0;
        vif.master_cb.read_h  <= 1'b0;
        @(vif.master_cb);
        @(vif.master_cb);

        `uvm_info("SEQ", "TC-005: Error state asserted and released — verifying recovery",
                  UVM_MEDIUM)

        // Confirm DUT has recovered — normal read must succeed
        av_read(32'h0, rdata);
        `uvm_info("SEQ", $sformatf("TC-005: Status after error recovery = 0x%032h (expect 0)",
                  rdata), UVM_MEDIUM)
    endtask

endclass : seq_error_state


// =============================================================================
// TC-006 : All ModeSelect values written to control register
// =============================================================================
class seq_ctrl_modes extends av_base_seq;
    `uvm_object_utils(seq_ctrl_modes)

    function new(string name = "seq_ctrl_modes"); super.new(name); endfunction

    virtual task body();
        logic [2:0] modes[5] = '{3'b000, 3'b001, 3'b010, 3'b011, 3'b100};
        string mode_names[5] = '{"ECB", "CBC", "OFB", "CFB", "CTR"};
        `uvm_info("SEQ", "TC-006: All ModeSelect values", UVM_MEDIUM)

        foreach (modes[i]) begin
            `uvm_info("SEQ", $sformatf("TC-006: Writing mode=%s (%3b)", mode_names[i], modes[i]),
                      UVM_MEDIUM)
            av_write_ctrl(.mode(modes[i]), .ksel(2'b00), .enc(1'b1), .en(1'b0));
        end
    endtask

endclass : seq_ctrl_modes


// =============================================================================
// TC-007 : All KeySelect values written to control register
// =============================================================================
class seq_ctrl_keysel extends av_base_seq;
    `uvm_object_utils(seq_ctrl_keysel)

    function new(string name = "seq_ctrl_keysel"); super.new(name); endfunction

    virtual task body();
        logic [1:0] keys[3] = '{2'b00, 2'b01, 2'b10};
        string knames[3]    = '{"AES-128", "AES-192", "AES-256"};
        `uvm_info("SEQ", "TC-007: All KeySelect values", UVM_MEDIUM)

        foreach (keys[i]) begin
            `uvm_info("SEQ", $sformatf("TC-007: Writing KeySelect=%s (%2b)", knames[i], keys[i]),
                      UVM_MEDIUM)
            av_write_ctrl(.mode(3'b000), .ksel(keys[i]), .enc(1'b1), .en(1'b0));
        end
    endtask

endclass : seq_ctrl_keysel


// =============================================================================
// TC-008 : Write to out-of-range address (addr = 5)
// =============================================================================
class seq_invalid_addr extends av_base_seq;
    `uvm_object_utils(seq_invalid_addr)

    function new(string name = "seq_invalid_addr"); super.new(name); endfunction

    virtual task body();
        `uvm_info("SEQ", "TC-008: Write to invalid address (addr=5)", UVM_MEDIUM)
        av_write(32'h5, 128'hDEADBEEF_CAFEBABE_DEADBEEF_CAFEBABE);
        // Read Status — DUT should be unaffected
        begin
            logic [127:0] rdata;
            av_read(32'h0, rdata);
            `uvm_info("SEQ", $sformatf("TC-008: Status unchanged = 0x%032h", rdata), UVM_MEDIUM)
        end
    endtask

endclass : seq_invalid_addr


// =============================================================================
// TC-009 : Back-to-back writes to all 5 registers
// =============================================================================
class seq_back_to_back extends av_base_seq;
    `uvm_object_utils(seq_back_to_back)

    function new(string name = "seq_back_to_back"); super.new(name); endfunction

    virtual task body();
        `uvm_info("SEQ", "TC-009: Back-to-back writes (all regs)", UVM_MEDIUM)
        // Write all 5 addresses in rapid succession
        av_write(32'h4, 128'hAAAAAAAA_BBBBBBBB_CCCCCCCC_DDDDDDDD);
        av_write(32'h3, 128'h11111111_22222222_33333333_44444444);
        av_write(32'h2, 128'h55555555_66666666_77777777_88888888);
        av_write(32'h1, 128'h99999999_AAAAAAAA_BBBBBBBB_CCCCCCCC);
        av_write_ctrl(.mode(3'b001), .ksel(2'b10), .enc(1'b0), .en(1'b0));
        begin
            logic [127:0] rdata;
            av_read(32'h0, rdata);
            `uvm_info("SEQ", $sformatf("TC-009: Status = 0x%032h", rdata), UVM_MEDIUM)
        end
    endtask

endclass : seq_back_to_back


// =============================================================================
// TC-010 : Randomised write/read stress
// =============================================================================
class seq_stress extends av_base_seq;
    `uvm_object_utils(seq_stress)

    int unsigned n_iters = 20;

    function new(string name = "seq_stress"); super.new(name); endfunction

    virtual task body();
        `uvm_info("SEQ", $sformatf("TC-010: Randomised stress (%0d iterations)", n_iters),
                  UVM_MEDIUM)

        repeat (n_iters) begin
            avalon_transaction tr = avalon_transaction::type_id::create("stress");
            if (!tr.randomize() with {
                    kind == avalon_transaction::AVALON_WRITE -> address inside {[0:4]};
                    kind == avalon_transaction::AVALON_READ  -> address inside {0, 1};
                    of_pulse == 1'b0;
                }) begin
                `uvm_error("SEQ", "Randomization failed")
            end
            start_item(tr);
            finish_item(tr);
        end
    endtask

endclass : seq_stress

`endif // AVALON_SEQUENCES_SV