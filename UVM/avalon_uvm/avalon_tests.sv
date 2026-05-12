// =============================================================================
// File        : avalon_tests.sv
// Description : All UVM tests for AvalonMM_MSU.
//
//   avalon_base_test  — base: creates env, provides run_seq() helper
//   tc_001            — Reset & Idle
//   tc_002            — Write all registers
//   tc_003            — Read both readable registers (Status + DataOut)
//   tc_004            — Full ECB AES-128 Encrypt operation
//   tc_005            — Error state (simultaneous R+W)
//   tc_006            — Full ModeSelect × KeySelect sweep (15 combinations)
//   tc_007            — All modes × Encrypt + Decrypt (10 combinations)
//   tc_008            — Invalid address write
//   tc_009            — Back-to-back writes then read both registers
//   tc_010            — Randomised stress
//   all_tests         — Runs TC-001 through TC-010 in order (default)
//
// EDA Playground run options:
//   +UVM_TESTNAME=all_tests +UVM_VERBOSITY=UVM_MEDIUM
//   Individual: +UVM_TESTNAME=tc_001  … +UVM_TESTNAME=tc_010
// =============================================================================
`ifndef AVALON_TESTS_SV
`define AVALON_TESTS_SV

// =============================================================================
// Base test
// =============================================================================
class avalon_base_test extends uvm_test;
    `uvm_component_utils(avalon_base_test)

    avalon_env env;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = avalon_env::type_id::create("env", this);
    endfunction

    // Helper: label the scoreboard and run a sequence
    task run_seq(uvm_sequence #(avalon_transaction) seq, string label);
        env.scoreboard.set_test_label(label);
        seq.start(env.agent.sequencer);
    endtask

endclass : avalon_base_test


// =============================================================================
// TC-001 : Reset and idle
// =============================================================================
class tc_001 extends avalon_base_test;
    `uvm_component_utils(tc_001)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_reset s = seq_reset::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-001_RESET_IDLE");
        phase.drop_objection(this);
    endtask
endclass : tc_001


// =============================================================================
// TC-002 : Write all registers
// =============================================================================
class tc_002 extends avalon_base_test;
    `uvm_component_utils(tc_002)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_write_all s = seq_write_all::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-002_WRITE_ALL");
        phase.drop_objection(this);
    endtask
endclass : tc_002


// =============================================================================
// TC-003 : Read both readable registers
// =============================================================================
class tc_003 extends avalon_base_test;
    `uvm_component_utils(tc_003)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_read_both s = seq_read_both::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-003_READ_BOTH");
        phase.drop_objection(this);
    endtask
endclass : tc_003


// =============================================================================
// TC-004 : Full ECB AES-128 Encrypt
// =============================================================================
class tc_004 extends avalon_base_test;
    `uvm_component_utils(tc_004)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_full_op_ecb s = seq_full_op_ecb::type_id::create("s");
        phase.raise_objection(this);
        s.sb_ref = env.scoreboard;
        run_seq(s, "TC-004_FULL_ECB_ENC");
        phase.drop_objection(this);
    endtask
endclass : tc_004


// =============================================================================
// TC-005 : Error state
// =============================================================================
class tc_005 extends avalon_base_test;
    `uvm_component_utils(tc_005)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_error_state s = seq_error_state::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-005_ERROR_STATE");
        phase.drop_objection(this);
    endtask
endclass : tc_005


// =============================================================================
// TC-006 : Full ModeSelect × KeySelect sweep
// =============================================================================
class tc_006 extends avalon_base_test;
    `uvm_component_utils(tc_006)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_ctrl_modes s = seq_ctrl_modes::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-006_MODE_X_KEYSEL");
        phase.drop_objection(this);
    endtask
endclass : tc_006


// =============================================================================
// TC-007 : All modes × Encrypt + Decrypt
// =============================================================================
class tc_007 extends avalon_base_test;
    `uvm_component_utils(tc_007)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_ctrl_encdec s = seq_ctrl_encdec::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-007_MODE_X_ENCDEC");
        phase.drop_objection(this);
    endtask
endclass : tc_007


// =============================================================================
// TC-008 : Invalid address write
// =============================================================================
class tc_008 extends avalon_base_test;
    `uvm_component_utils(tc_008)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_invalid_addr s = seq_invalid_addr::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-008_INVALID_ADDR");
        phase.drop_objection(this);
    endtask
endclass : tc_008


// =============================================================================
// TC-009 : Back-to-back writes then read both registers
// =============================================================================
class tc_009 extends avalon_base_test;
    `uvm_component_utils(tc_009)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_back_to_back s = seq_back_to_back::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-009_BACK_TO_BACK");
        phase.drop_objection(this);
    endtask
endclass : tc_009


// =============================================================================
// TC-010 : Randomised stress
// =============================================================================
class tc_010 extends avalon_base_test;
    `uvm_component_utils(tc_010)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_stress s = seq_stress::type_id::create("s");
        phase.raise_objection(this);
        s.n_iters = 20;
        run_seq(s, "TC-010_STRESS");
        phase.drop_objection(this);
    endtask
endclass : tc_010


// =============================================================================
// all_tests : Runs TC-001 through TC-010 in order
// =============================================================================
class all_tests extends avalon_base_test;
    `uvm_component_utils(all_tests)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        begin
            seq_reset        s1  = seq_reset       ::type_id::create("s1");
            seq_write_all    s2  = seq_write_all   ::type_id::create("s2");
            seq_read_both    s3  = seq_read_both   ::type_id::create("s3");
            seq_full_op_ecb  s4  = seq_full_op_ecb ::type_id::create("s4");
            seq_error_state  s5  = seq_error_state ::type_id::create("s5");
            seq_ctrl_modes   s6  = seq_ctrl_modes  ::type_id::create("s6");
            seq_ctrl_encdec  s7  = seq_ctrl_encdec ::type_id::create("s7");
            seq_invalid_addr s8  = seq_invalid_addr::type_id::create("s8");
            seq_back_to_back s9  = seq_back_to_back::type_id::create("s9");
            seq_stress       s10 = seq_stress      ::type_id::create("s10");

            s4.sb_ref = env.scoreboard;

            run_seq(s1,  "TC-001_RESET_IDLE");
            run_seq(s2,  "TC-002_WRITE_ALL");
            run_seq(s3,  "TC-003_READ_BOTH");
            run_seq(s4,  "TC-004_FULL_ECB_ENC");
            run_seq(s5,  "TC-005_ERROR_STATE");
            run_seq(s6,  "TC-006_MODE_X_KEYSEL");
            run_seq(s7,  "TC-007_MODE_X_ENCDEC");
            run_seq(s8,  "TC-008_INVALID_ADDR");
            run_seq(s9,  "TC-009_BACK_TO_BACK");
            run_seq(s10, "TC-010_STRESS");
        end

        phase.drop_objection(this);
    endtask

endclass : all_tests

`endif // AVALON_TESTS_SV

// Description : All UVM tests for AvalonMM_MSU.
//
//   avalon_base_test  — base: creates env, provides run_seq() helper
//   tc_001            — Reset & Idle
//   tc_002            — Write all registers
//   tc_003            — Read Status register
//   tc_004            — Full ECB AES-128 Encrypt operation
//   tc_005            — Error state (simultaneous R+W)
//   tc_006            — All ModeSelect values
//   tc_007            — All KeySelect values
//   tc_008            — Invalid address write
//   tc_009            — Back-to-back writes
//   tc_010            — Randomised stress
//   all_tests         — Runs TC-001 through TC-010 in order (default)
//
// EDA Playground run options:
//   +UVM_TESTNAME=all_tests +UVM_VERBOSITY=UVM_MEDIUM
//   Individual: +UVM_TESTNAME=tc_001  … +UVM_TESTNAME=tc_010
// =============================================================================
`ifndef AVALON_TESTS_SV
`define AVALON_TESTS_SV

// =============================================================================
// Base test
// =============================================================================
class avalon_base_test extends uvm_test;
    `uvm_component_utils(avalon_base_test)

    avalon_env env;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = avalon_env::type_id::create("env", this);
    endfunction

    // Helper: label the scoreboard and run a sequence
    task run_seq(uvm_sequence #(avalon_transaction) seq, string label);
        env.scoreboard.set_test_label(label);
        seq.start(env.agent.sequencer);
    endtask

endclass : avalon_base_test


// =============================================================================
// TC-001 : Reset and idle
// =============================================================================
class tc_001 extends avalon_base_test;
    `uvm_component_utils(tc_001)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_reset s = seq_reset::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-001_RESET_IDLE");
        phase.drop_objection(this);
    endtask
endclass : tc_001


// =============================================================================
// TC-002 : Write all registers
// =============================================================================
class tc_002 extends avalon_base_test;
    `uvm_component_utils(tc_002)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_write_all s = seq_write_all::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-002_WRITE_ALL");
        phase.drop_objection(this);
    endtask
endclass : tc_002


// =============================================================================
// TC-003 : Read Status register
// =============================================================================
class tc_003 extends avalon_base_test;
    `uvm_component_utils(tc_003)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_read_status s = seq_read_status::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-003_READ_STATUS");
        phase.drop_objection(this);
    endtask
endclass : tc_003


// =============================================================================
// TC-004 : Full ECB AES-128 Encrypt
// =============================================================================
class tc_004 extends avalon_base_test;
    `uvm_component_utils(tc_004)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_full_op_ecb s = seq_full_op_ecb::type_id::create("s");
        phase.raise_objection(this);
        // Pass scoreboard reference so sequence can call expect_of()
        s.sb_ref = env.scoreboard;
        run_seq(s, "TC-004_FULL_ECB_ENC");
        phase.drop_objection(this);
    endtask
endclass : tc_004


// =============================================================================
// TC-005 : Error state
// =============================================================================
class tc_005 extends avalon_base_test;
    `uvm_component_utils(tc_005)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_error_state s = seq_error_state::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-005_ERROR_STATE");
        phase.drop_objection(this);
    endtask
endclass : tc_005


// =============================================================================
// TC-006 : All ModeSelect values
// =============================================================================
class tc_006 extends avalon_base_test;
    `uvm_component_utils(tc_006)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_ctrl_modes s = seq_ctrl_modes::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-006_MODESELECT_ALL");
        phase.drop_objection(this);
    endtask
endclass : tc_006


// =============================================================================
// TC-007 : All KeySelect values
// =============================================================================
class tc_007 extends avalon_base_test;
    `uvm_component_utils(tc_007)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_ctrl_keysel s = seq_ctrl_keysel::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-007_KEYSELECT_ALL");
        phase.drop_objection(this);
    endtask
endclass : tc_007


// =============================================================================
// TC-008 : Invalid address write
// =============================================================================
class tc_008 extends avalon_base_test;
    `uvm_component_utils(tc_008)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_invalid_addr s = seq_invalid_addr::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-008_INVALID_ADDR");
        phase.drop_objection(this);
    endtask
endclass : tc_008


// =============================================================================
// TC-009 : Back-to-back writes
// =============================================================================
class tc_009 extends avalon_base_test;
    `uvm_component_utils(tc_009)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_back_to_back s = seq_back_to_back::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC-009_BACK_TO_BACK");
        phase.drop_objection(this);
    endtask
endclass : tc_009


// =============================================================================
// TC-010 : Randomised stress
// =============================================================================
class tc_010 extends avalon_base_test;
    `uvm_component_utils(tc_010)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        seq_stress s = seq_stress::type_id::create("s");
        phase.raise_objection(this);
        s.n_iters = 20;
        run_seq(s, "TC-010_STRESS");
        phase.drop_objection(this);
    endtask
endclass : tc_010


// =============================================================================
// all_tests : Runs TC-001 through TC-010 in order
// =============================================================================
class all_tests extends avalon_base_test;
    `uvm_component_utils(all_tests)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        begin
            seq_reset       s1  = seq_reset      ::type_id::create("s1");
            seq_write_all   s2  = seq_write_all  ::type_id::create("s2");
            seq_read_status s3  = seq_read_status::type_id::create("s3");
            seq_full_op_ecb s4  = seq_full_op_ecb::type_id::create("s4");
            seq_error_state s5  = seq_error_state::type_id::create("s5");
            seq_ctrl_modes  s6  = seq_ctrl_modes ::type_id::create("s6");
            seq_ctrl_keysel s7  = seq_ctrl_keysel::type_id::create("s7");
            seq_invalid_addr s8 = seq_invalid_addr::type_id::create("s8");
            seq_back_to_back s9 = seq_back_to_back::type_id::create("s9");
            seq_stress       s10= seq_stress     ::type_id::create("s10");

            s4.sb_ref = env.scoreboard;

            run_seq(s1,  "TC-001_RESET_IDLE");
            run_seq(s2,  "TC-002_WRITE_ALL");
            run_seq(s3,  "TC-003_READ_STATUS");
            run_seq(s4,  "TC-004_FULL_ECB_ENC");
            run_seq(s5,  "TC-005_ERROR_STATE");
            run_seq(s6,  "TC-006_MODESELECT_ALL");
            run_seq(s7,  "TC-007_KEYSELECT_ALL");
            run_seq(s8,  "TC-008_INVALID_ADDR");
            run_seq(s9,  "TC-009_BACK_TO_BACK");
            run_seq(s10, "TC-010_STRESS");
        end

        phase.drop_objection(this);
    endtask

endclass : all_tests

`endif // AVALON_TESTS_SV