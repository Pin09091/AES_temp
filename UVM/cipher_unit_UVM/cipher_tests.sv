// =============================================================================
// File        : cipher_tests.sv
// Description : One UVM test class per test case (TC_001 – TC_013).
//               TC_001–TC_010 match the verification plan document.
//               TC_011–TC_013 are fully-random reference-model checks,
//               one per key length.
//               Select a test with +UVM_TESTNAME=tc_001 (or tc_002 .. tc_013).
// =============================================================================
`ifndef CIPHER_TESTS_SV
`define CIPHER_TESTS_SV

// ---------------------------------------------------------------------------
// Base test — shared boilerplate
// ---------------------------------------------------------------------------
class cipher_base_test extends uvm_test;
  `uvm_component_utils(cipher_base_test)

  cipher_env env;

  function new(string name = "cipher_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = cipher_env::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  // Helper: run a named sequence on the agent's sequencer
  task run_sequence(uvm_sequence #(cipher_transaction) seq);
    phase_raise();
    seq.start(env.agent.sequencer);
    phase_drop();
  endtask

  // These wrappers exist so sub-classes don't need to re-declare the phase
  local uvm_phase m_run_phase;
  task phase_raise(); m_run_phase.raise_objection(this); endtask
  task phase_drop();  m_run_phase.drop_objection(this);  endtask

  virtual task run_phase(uvm_phase phase);
    m_run_phase = phase;
  endtask

endclass : cipher_base_test

// ---------------------------------------------------------------------------
// TC_001  —  Encrypt AES-128
// ---------------------------------------------------------------------------
class tc_001 extends cipher_base_test;
  `uvm_component_utils(tc_001)
  function new(string name = "tc_001", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_001_enc_128 seq = tc_001_enc_128::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_002  —  Encrypt AES-192
// ---------------------------------------------------------------------------
class tc_002 extends cipher_base_test;
  `uvm_component_utils(tc_002)
  function new(string name = "tc_002", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_002_enc_192 seq = tc_002_enc_192::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_003  —  Encrypt AES-256
// ---------------------------------------------------------------------------
class tc_003 extends cipher_base_test;
  `uvm_component_utils(tc_003)
  function new(string name = "tc_003", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_003_enc_256 seq = tc_003_enc_256::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_004  —  Decrypt AES-128
// ---------------------------------------------------------------------------
class tc_004 extends cipher_base_test;
  `uvm_component_utils(tc_004)
  function new(string name = "tc_004", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_004_dec_128 seq = tc_004_dec_128::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_005  —  Decrypt AES-192
// ---------------------------------------------------------------------------
class tc_005 extends cipher_base_test;
  `uvm_component_utils(tc_005)
  function new(string name = "tc_005", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_005_dec_192 seq = tc_005_dec_192::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_006  —  Decrypt AES-256
// ---------------------------------------------------------------------------
class tc_006 extends cipher_base_test;
  `uvm_component_utils(tc_006)
  function new(string name = "tc_006", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_006_dec_256 seq = tc_006_dec_256::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_007  —  Key reset smoke test
// ---------------------------------------------------------------------------
class tc_007 extends cipher_base_test;
  `uvm_component_utils(tc_007)
  function new(string name = "tc_007", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_007_key_reset seq = tc_007_key_reset::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_008  —  Soft reset smoke test
// ---------------------------------------------------------------------------
class tc_008 extends cipher_base_test;
  `uvm_component_utils(tc_008)
  function new(string name = "tc_008", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_008_soft_reset seq = tc_008_soft_reset::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_009  —  Hard reset smoke test
// ---------------------------------------------------------------------------
class tc_009 extends cipher_base_test;
  `uvm_component_utils(tc_009)
  function new(string name = "tc_009", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_009_hard_reset seq = tc_009_hard_reset::type_id::create("seq");
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_010  —  Randomised stress test
// ---------------------------------------------------------------------------
class tc_010 extends cipher_base_test;
  `uvm_component_utils(tc_010)

  int unsigned n_stress = 50; // override via +n_stress=<N> if simulator supports

  function new(string name = "tc_010", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_010_random_stress seq = tc_010_random_stress::type_id::create("seq");
    seq.n_stress = n_stress;
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_011  —  Random Key+Data enc/dec AES-128
// ---------------------------------------------------------------------------
class tc_011 extends cipher_base_test;
  `uvm_component_utils(tc_011)
  int unsigned n_transactions = 50;
  function new(string name = "tc_011", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_011_random_kl0 seq = tc_011_random_kl0::type_id::create("seq");
    seq.n_transactions = n_transactions;
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_012  —  Random Key+Data enc/dec AES-192
// ---------------------------------------------------------------------------
class tc_012 extends cipher_base_test;
  `uvm_component_utils(tc_012)
  int unsigned n_transactions = 50;
  function new(string name = "tc_012", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_012_random_kl1 seq = tc_012_random_kl1::type_id::create("seq");
    seq.n_transactions = n_transactions;
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// TC_013  —  Random Key+Data enc/dec AES-256
// ---------------------------------------------------------------------------
class tc_013 extends cipher_base_test;
  `uvm_component_utils(tc_013)
  int unsigned n_transactions = 50;
  function new(string name = "tc_013", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_013_random_kl2 seq = tc_013_random_kl2::type_id::create("seq");
    seq.n_transactions = n_transactions;
    super.run_phase(phase);
    run_sequence(seq);
  endtask
endclass

// ---------------------------------------------------------------------------
// ALL_TESTS — convenience test that runs the full test plan in order
// ---------------------------------------------------------------------------
class all_tests extends cipher_base_test;
  `uvm_component_utils(all_tests)
  function new(string name = "all_tests", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  virtual task run_phase(uvm_phase phase);
    tc_001_enc_128       s1  = tc_001_enc_128      ::type_id::create("tc001");
    tc_002_enc_192       s2  = tc_002_enc_192      ::type_id::create("tc002");
    tc_003_enc_256       s3  = tc_003_enc_256      ::type_id::create("tc003");
    tc_004_dec_128       s4  = tc_004_dec_128      ::type_id::create("tc004");
    tc_005_dec_192       s5  = tc_005_dec_192      ::type_id::create("tc005");
    tc_006_dec_256       s6  = tc_006_dec_256      ::type_id::create("tc006");
    tc_007_key_reset     s7  = tc_007_key_reset    ::type_id::create("tc007");
    tc_008_soft_reset    s8  = tc_008_soft_reset   ::type_id::create("tc008");
    tc_009_hard_reset    s9  = tc_009_hard_reset   ::type_id::create("tc009");
    tc_010_random_stress s10 = tc_010_random_stress::type_id::create("tc010");
    tc_011_random_kl0    s11 = tc_011_random_kl0   ::type_id::create("tc011");
    tc_012_random_kl1    s12 = tc_012_random_kl1   ::type_id::create("tc012");
    tc_013_random_kl2    s13 = tc_013_random_kl2   ::type_id::create("tc013");
	
    //Reduced runtime to check for errors <------------------------------------------HERE
    //s1.n_random_blocks  = 10;
    //s2.n_random_blocks  = 10;
    //s3.n_random_blocks  = 10;
    //s4.n_random_blocks  = 10;
    //s5.n_random_blocks  = 10;
    //s6.n_random_blocks  = 10;
    //s10.n_stress        = 20;
    //s11.n_transactions  = 20;
    //s12.n_transactions  = 20;
    //s13.n_transactions  = 20;

    super.run_phase(phase);
    phase.raise_objection(this);

    `uvm_info("ALL_TESTS", "======== Starting full test plan ========", UVM_NONE)
    s1.start(env.agent.sequencer);
    s2.start(env.agent.sequencer);
    s3.start(env.agent.sequencer);
    s4.start(env.agent.sequencer);
    s5.start(env.agent.sequencer);
    s6.start(env.agent.sequencer);
    s7.start(env.agent.sequencer);
    s8.start(env.agent.sequencer);
    s9.start(env.agent.sequencer);
    s10.start(env.agent.sequencer);
    `uvm_info("ALL_TESTS", "---- Random reference-model checks ----", UVM_NONE)
    s11.start(env.agent.sequencer);
    s12.start(env.agent.sequencer);
    s13.start(env.agent.sequencer);
    `uvm_info("ALL_TESTS", "======== Test plan complete ========", UVM_NONE)

    phase.drop_objection(this);
  endtask
endclass

`endif // CIPHER_TESTS_SV
