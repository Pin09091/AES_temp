// =============================================================================
// File        : msu_tests.sv
// Description : All UVM tests for mode_selection_unit.
//
//   msu_base_test   — base class; all concrete tests extend this
//   tc_001          — ECB AES-128 Encrypt
//   tc_002          — ECB AES-192 Encrypt
//   tc_003          — ECB AES-256 Encrypt
//   tc_004          — ECB AES-128 Decrypt
//   tc_005          — ECB AES-192 Decrypt
//   tc_006          — ECB AES-256 Decrypt
//   tc_007          — CBC AES-128 Encrypt
//   tc_008          — CBC AES-192 Encrypt
//   tc_009          — CBC AES-256 Encrypt
//   tc_010          — CBC AES-128 Decrypt
//   tc_011          — OFB AES-256 Encrypt + Decrypt
//   tc_012          — CFB AES-128 Encrypt + Decrypt
//   tc_013          — CTR AES-256 Enc + AES-192 Dec
//   tc_014          — Random stress (all modes × all keys × both dirs)
//   all_tests       — runs TC_001 – TC_014 in order (default test)
//
// Compile Options (EDA Playground, Synopsys VCS):
//   -timescale=1ns/1ns +vcs+flush+all -sverilog -CFLAGS "-DVCS"
//
// Run Options:
//   +UVM_TESTNAME=all_tests +UVM_VERBOSITY=UVM_MEDIUM
// =============================================================================
`ifndef MSU_TESTS_SV
`define MSU_TESTS_SV

// =============================================================================
// Base test — creates the environment and provides a run_seq() helper
// =============================================================================
class msu_base_test extends uvm_test;
    `uvm_component_utils(msu_base_test)

    msu_env env;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = msu_env::type_id::create("env", this);
    endfunction

    // Run a sequence and update the scoreboard label for reporting
    task run_seq(uvm_sequence #(msu_transaction) seq,
                 string label,
                 string mode_str = "MIXED");
        env.scoreboard.set_test_label(label, mode_str);
        seq.start(env.agent.sequencer);
    endtask

endclass : msu_base_test


// =============================================================================
// Individual test wrappers (one sequence per test)
// =============================================================================

class tc_001 extends msu_base_test;
    `uvm_component_utils(tc_001)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_001_ecb_enc_128 s = tc_001_ecb_enc_128::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_001_ECB_ENC_128", "ECB");
        phase.drop_objection(this);
    endtask
endclass

class tc_002 extends msu_base_test;
    `uvm_component_utils(tc_002)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_002_ecb_enc_192 s = tc_002_ecb_enc_192::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_002_ECB_ENC_192", "ECB");
        phase.drop_objection(this);
    endtask
endclass

class tc_003 extends msu_base_test;
    `uvm_component_utils(tc_003)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_003_ecb_enc_256 s = tc_003_ecb_enc_256::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_003_ECB_ENC_256", "ECB");
        phase.drop_objection(this);
    endtask
endclass

class tc_004 extends msu_base_test;
    `uvm_component_utils(tc_004)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_004_ecb_dec_128 s = tc_004_ecb_dec_128::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_004_ECB_DEC_128", "ECB");
        phase.drop_objection(this);
    endtask
endclass

class tc_005 extends msu_base_test;
    `uvm_component_utils(tc_005)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_005_ecb_dec_192 s = tc_005_ecb_dec_192::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_005_ECB_DEC_192", "ECB");
        phase.drop_objection(this);
    endtask
endclass

class tc_006 extends msu_base_test;
    `uvm_component_utils(tc_006)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_006_ecb_dec_256 s = tc_006_ecb_dec_256::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_006_ECB_DEC_256", "ECB");
        phase.drop_objection(this);
    endtask
endclass

class tc_007 extends msu_base_test;
    `uvm_component_utils(tc_007)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_007_cbc_enc_128 s = tc_007_cbc_enc_128::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_007_CBC_ENC_128", "CBC");
        phase.drop_objection(this);
    endtask
endclass

class tc_008 extends msu_base_test;
    `uvm_component_utils(tc_008)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_008_cbc_enc_192 s = tc_008_cbc_enc_192::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_008_CBC_ENC_192", "CBC");
        phase.drop_objection(this);
    endtask
endclass

class tc_009 extends msu_base_test;
    `uvm_component_utils(tc_009)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_009_cbc_enc_256 s = tc_009_cbc_enc_256::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_009_CBC_ENC_256", "CBC");
        phase.drop_objection(this);
    endtask
endclass

class tc_010 extends msu_base_test;
    `uvm_component_utils(tc_010)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_010_cbc_dec_128 s = tc_010_cbc_dec_128::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_010_CBC_DEC_128", "CBC");
        phase.drop_objection(this);
    endtask
endclass

class tc_011 extends msu_base_test;
    `uvm_component_utils(tc_011)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_011_ofb_256 s = tc_011_ofb_256::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_011_OFB_256", "OFB");
        phase.drop_objection(this);
    endtask
endclass

class tc_012 extends msu_base_test;
    `uvm_component_utils(tc_012)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_012_cfb_128 s = tc_012_cfb_128::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_012_CFB_128", "CFB");
        phase.drop_objection(this);
    endtask
endclass

class tc_013 extends msu_base_test;
    `uvm_component_utils(tc_013)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_013_ctr s = tc_013_ctr::type_id::create("s");
        phase.raise_objection(this);
        run_seq(s, "TC_013_CTR", "CTR");
        phase.drop_objection(this);
    endtask
endclass

class tc_014 extends msu_base_test;
    `uvm_component_utils(tc_014)
    function new(string name, uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        tc_014_random_stress s = tc_014_random_stress::type_id::create("s");
        s.n_stress = 30;
        phase.raise_objection(this);
        run_seq(s, "TC_014_RandomStress", "MIXED");
        phase.drop_objection(this);
    endtask
endclass


// =============================================================================
// all_tests — runs TC_001 through TC_014 in order
// Default test selected by +UVM_TESTNAME=all_tests
// =============================================================================
class all_tests extends msu_base_test;
    `uvm_component_utils(all_tests)

    function new(string name = "all_tests", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Create all sequences
        tc_001_ecb_enc_128   s1  = tc_001_ecb_enc_128  ::type_id::create("tc001");
        tc_002_ecb_enc_192   s2  = tc_002_ecb_enc_192  ::type_id::create("tc002");
        tc_003_ecb_enc_256   s3  = tc_003_ecb_enc_256  ::type_id::create("tc003");
        tc_004_ecb_dec_128   s4  = tc_004_ecb_dec_128  ::type_id::create("tc004");
        tc_005_ecb_dec_192   s5  = tc_005_ecb_dec_192  ::type_id::create("tc005");
        tc_006_ecb_dec_256   s6  = tc_006_ecb_dec_256  ::type_id::create("tc006");
        tc_007_cbc_enc_128   s7  = tc_007_cbc_enc_128  ::type_id::create("tc007");
        tc_008_cbc_enc_192   s8  = tc_008_cbc_enc_192  ::type_id::create("tc008");
        tc_009_cbc_enc_256   s9  = tc_009_cbc_enc_256  ::type_id::create("tc009");
        tc_010_cbc_dec_128   s10 = tc_010_cbc_dec_128  ::type_id::create("tc010");
        tc_011_ofb_256       s11 = tc_011_ofb_256      ::type_id::create("tc011");
        tc_012_cfb_128       s12 = tc_012_cfb_128      ::type_id::create("tc012");
        tc_013_ctr           s13 = tc_013_ctr          ::type_id::create("tc013");
        tc_014_random_stress s14 = tc_014_random_stress::type_id::create("tc014");

        // Configure transaction counts
       // s1.n_random  = 4;   s2.n_random  = 4;   s3.n_random  = 4;
        //s4.n_random  = 4;   s5.n_random  = 4;   s6.n_random  = 4;
        //s7.n_random  = 4;   s8.n_random  = 4;   s9.n_random  = 4;
        //s10.n_random = 4;   s11.n_random = 4;   s12.n_random = 4;
        //s13.n_random = 4;
        //s14.n_stress = 30;

        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("ALL_TESTS", "======== MSU Full Test Plan Starting ========", UVM_NONE)

        `uvm_info("ALL_TESTS", "---- ECB Mode ----", UVM_NONE)
        run_seq(s1,  "TC_001_ECB_ENC_128", "ECB");
        run_seq(s2,  "TC_002_ECB_ENC_192", "ECB");
        run_seq(s3,  "TC_003_ECB_ENC_256", "ECB");
        run_seq(s4,  "TC_004_ECB_DEC_128", "ECB");
        run_seq(s5,  "TC_005_ECB_DEC_192", "ECB");
        run_seq(s6,  "TC_006_ECB_DEC_256", "ECB");

        `uvm_info("ALL_TESTS", "---- CBC Mode ----", UVM_NONE)
        run_seq(s7,  "TC_007_CBC_ENC_128", "CBC");
        run_seq(s8,  "TC_008_CBC_ENC_192", "CBC");
        run_seq(s9,  "TC_009_CBC_ENC_256", "CBC");
        run_seq(s10, "TC_010_CBC_DEC_128", "CBC");

        `uvm_info("ALL_TESTS", "---- OFB / CFB / CTR Modes ----", UVM_NONE)
        run_seq(s11, "TC_011_OFB_256",     "OFB");
        run_seq(s12, "TC_012_CFB_128",     "CFB");
        run_seq(s13, "TC_013_CTR",         "CTR");

        `uvm_info("ALL_TESTS", "---- Random Stress ----", UVM_NONE)
        run_seq(s14, "TC_014_RandomStress","MIXED");

        `uvm_info("ALL_TESTS", "======== MSU Full Test Plan Complete ========", UVM_NONE)

        phase.drop_objection(this);
    endtask

endclass : all_tests

`endif // MSU_TESTS_SV
