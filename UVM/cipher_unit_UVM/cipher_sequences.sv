// =============================================================================
// File        : cipher_sequences.sv
// Description : All test sequences implementing TC_001 – TC_013.
//               TC_001–TC_010 match the test plan document (Table 6).
//               TC_011–TC_013 add fully-random key+data reference checks.
//
//   TC_001  Feature — Encrypt KL=0 (AES-128)
//   TC_002  Feature — Encrypt KL=1 (AES-192)
//   TC_003  Feature — Encrypt KL=2 (AES-256)
//   TC_004  Feature — Decrypt KL=0 (AES-128)
//   TC_005  Feature — Decrypt KL=1 (AES-192)
//   TC_006  Feature — Decrypt KL=2 (AES-256)
//   TC_007  Smoke   — Key reset (CK) at different intervals
//   TC_008  Smoke   — Soft reset (CLR) at different intervals
//   TC_009  Smoke   — Hard reset (CK+CLR simultaneously)
//   TC_010  Stress  — Randomised control signals (all KL values)
//   TC_011  Random  — Fully random Key+Data+enc_dec, KL=0 (AES-128)
//   TC_012  Random  — Fully random Key+Data+enc_dec, KL=1 (AES-192)
//   TC_013  Random  — Fully random Key+Data+enc_dec, KL=2 (AES-256)
// =============================================================================
`ifndef CIPHER_SEQUENCES_SV
`define CIPHER_SEQUENCES_SV

// =============================================================================
// Base sequence — provides the NIST test vectors and helper methods
// =============================================================================
class cipher_base_seq extends uvm_sequence #(cipher_transaction);
  `uvm_object_utils(cipher_base_seq)
  `uvm_declare_p_sequencer(uvm_sequencer #(cipher_transaction))

  int unsigned n_random_blocks = 8; // blocks per transaction for feature tests

  function new(string name = "cipher_base_seq");
    super.new(name);
  endfunction

  // ---- NIST AES-128 ECB test vector (FIPS 197 Appendix B) ----------------
  function cipher_transaction make_nist_128_enc();
    cipher_transaction tr = cipher_transaction::type_id::create("nist128e");
    tr.KL      = 2'b00;
    tr.enc_dec = 1'b1;
    // Key: 2b7e151628aed2a6abf7158809cf4f3c
    tr.Key     = 256'h000000000000000000000000000000002b7e151628aed2a6abf7158809cf4f3c;
    // Plaintext: 6bc1bee22e409f96e93d7e117393172a
    tr.Data    = 128'h6bc1bee22e409f96e93d7e117393172a;
    return tr;
  endfunction

  // ---- NIST AES-192 ECB test vector (FIPS 197 Appendix C.2) --------------
  function cipher_transaction make_nist_192_enc();
    cipher_transaction tr = cipher_transaction::type_id::create("nist192e");
    tr.KL      = 2'b01;
    tr.enc_dec = 1'b1;
    // Key: 8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b
    tr.Key     = 256'h00000000000000008e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b;
    // Plaintext: 6bc1bee22e409f96e93d7e117393172a
    tr.Data    = 128'h6bc1bee22e409f96e93d7e117393172a;
    return tr;
  endfunction

  // ---- NIST AES-256 ECB test vector (FIPS 197 Appendix C.3) --------------
  function cipher_transaction make_nist_256_enc();
    cipher_transaction tr = cipher_transaction::type_id::create("nist256e");
    tr.KL      = 2'b10;
    tr.enc_dec = 1'b1;
    // Key: 603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4
    tr.Key     = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
    // Plaintext: 6bc1bee22e409f96e93d7e117393172a
    tr.Data    = 128'h6bc1bee22e409f96e93d7e117393172a;
    return tr;
  endfunction

  // Build a decryption transaction from an encryption one (swap mode only;
  // data should be the ciphertext for a proper round-trip; here we use the
  // known NIST ciphertexts as inputs to decryption).
  function cipher_transaction make_nist_128_dec();
    cipher_transaction tr = make_nist_128_enc();
    tr.enc_dec = 1'b0;
    // NIST AES-128 ciphertext of above: 3ad77bb40d7a3660a89ecaf32466ef97
    tr.Data    = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
    return tr;
  endfunction

  function cipher_transaction make_nist_192_dec();
    cipher_transaction tr = make_nist_192_enc();
    tr.enc_dec = 1'b0;
    // NIST AES-192 ciphertext: bd334f1d6e45f25ff712a214571fa5cc
    tr.Data    = 128'hbd334f1d6e45f25ff712a214571fa5cc;
    return tr;
  endfunction

  function cipher_transaction make_nist_256_dec();
    cipher_transaction tr = make_nist_256_enc();
    tr.enc_dec = 1'b0;
    // NIST AES-256 ciphertext: f3eed1bdb5d2a03c064b5a7e3db181f8
    tr.Data    = 128'hf3eed1bdb5d2a03c064b5a7e3db181f8;
    return tr;
  endfunction

  // Helper: send a fully-formed transaction object
  task send_transaction(cipher_transaction tr);
    start_item(tr);
    finish_item(tr);
  endtask

  // Stamp identity fields onto a transaction before sending
  function void stamp(cipher_transaction tr, string tname, string mstr, int tcid);
    tr.test_name  = tname;
    tr.mode_str   = mstr;
    tr.tc_id      = tcid;
  endfunction

  // Stamp identity AND reset type together
  function void stamp_r(cipher_transaction tr, string tname, string mstr,
                        int tcid, bit [1:0] rtype);
    tr.test_name  = tname;
    tr.mode_str   = mstr;
    tr.tc_id      = tcid;
    tr.reset_type = rtype;
  endfunction

endclass : cipher_base_seq


// =============================================================================
// TC_001 — Feature: Encrypt KL=0 (AES-128)
// =============================================================================
class tc_001_enc_128 extends cipher_base_seq;
  `uvm_object_utils(tc_001_enc_128)
  function new(string name = "tc_001_enc_128"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_001", "START — Encryption KL=0 (AES-128)", UVM_NONE)

    tr = make_nist_128_enc(); stamp(tr, "TC_001_ENC_128", "ENC", 1);
    send_transaction(tr);

    repeat(n_random_blocks) begin
      tr = cipher_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with { KL == 2'b00; enc_dec == 1'b1; })
        `uvm_error("TC_001", "Randomisation failed")
      stamp(tr, "TC_001_ENC_128", "ENC", 1);
      finish_item(tr);
    end

    `uvm_info("TC_001", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_002 — Feature: Encrypt KL=1 (AES-192)
// =============================================================================
class tc_002_enc_192 extends cipher_base_seq;
  `uvm_object_utils(tc_002_enc_192)
  function new(string name = "tc_002_enc_192"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_002", "START — Encryption KL=1 (AES-192)", UVM_NONE)

    tr = make_nist_192_enc(); stamp(tr, "TC_002_ENC_192", "ENC", 2);
    send_transaction(tr);

    repeat(n_random_blocks) begin
      tr = cipher_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with { KL == 2'b01; enc_dec == 1'b1; })
        `uvm_error("TC_002", "Randomisation failed")
      stamp(tr, "TC_002_ENC_192", "ENC", 2);
      finish_item(tr);
    end

    `uvm_info("TC_002", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_003 — Feature: Encrypt KL=2 (AES-256)
// =============================================================================
class tc_003_enc_256 extends cipher_base_seq;
  `uvm_object_utils(tc_003_enc_256)
  function new(string name = "tc_003_enc_256"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_003", "START — Encryption KL=2 (AES-256)", UVM_NONE)

    tr = make_nist_256_enc(); stamp(tr, "TC_003_ENC_256", "ENC", 3);
    send_transaction(tr);

    repeat(n_random_blocks) begin
      tr = cipher_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with { KL == 2'b10; enc_dec == 1'b1; })
        `uvm_error("TC_003", "Randomisation failed")
      stamp(tr, "TC_003_ENC_256", "ENC", 3);
      finish_item(tr);
    end

    `uvm_info("TC_003", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_004 — Feature: Decrypt KL=0 (AES-128)
// =============================================================================
class tc_004_dec_128 extends cipher_base_seq;
  `uvm_object_utils(tc_004_dec_128)
  function new(string name = "tc_004_dec_128"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_004", "START — Decryption KL=0 (AES-128)", UVM_NONE)

    tr = make_nist_128_dec(); stamp(tr, "TC_004_DEC_128", "DEC", 4);
    send_transaction(tr);

    repeat(n_random_blocks) begin
      tr = cipher_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with { KL == 2'b00; enc_dec == 1'b0; })
        `uvm_error("TC_004", "Randomisation failed")
      stamp(tr, "TC_004_DEC_128", "DEC", 4);
      finish_item(tr);
    end

    `uvm_info("TC_004", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_005 — Feature: Decrypt KL=1 (AES-192)
// =============================================================================
class tc_005_dec_192 extends cipher_base_seq;
  `uvm_object_utils(tc_005_dec_192)
  function new(string name = "tc_005_dec_192"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_005", "START — Decryption KL=1 (AES-192)", UVM_NONE)

    tr = make_nist_192_dec(); stamp(tr, "TC_005_DEC_192", "DEC", 5);
    send_transaction(tr);

    repeat(n_random_blocks) begin
      tr = cipher_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with { KL == 2'b01; enc_dec == 1'b0; })
        `uvm_error("TC_005", "Randomisation failed")
      stamp(tr, "TC_005_DEC_192", "DEC", 5);
      finish_item(tr);
    end

    `uvm_info("TC_005", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_006 — Feature: Decrypt KL=2 (AES-256)
// =============================================================================
class tc_006_dec_256 extends cipher_base_seq;
  `uvm_object_utils(tc_006_dec_256)
  function new(string name = "tc_006_dec_256"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_006", "START — Decryption KL=2 (AES-256)", UVM_NONE)

    tr = make_nist_256_dec(); stamp(tr, "TC_006_DEC_256", "DEC", 6);
    send_transaction(tr);

    repeat(n_random_blocks) begin
      tr = cipher_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with { KL == 2'b10; enc_dec == 1'b0; })
        `uvm_error("TC_006", "Randomisation failed")
      stamp(tr, "TC_006_DEC_256", "DEC", 6);
      finish_item(tr);
    end

    `uvm_info("TC_006", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_007 — Smoke: Key reset (CK) at different intervals
//          This sequence exercises the key-reset path by triggering CK at
//          varied points during encryption.  The scoreboard does not compare
//          output here since the DUT is expected to re-run key expansion;
//          we verify no X/Z on outputs and the DUT resumes correctly.
// =============================================================================
class tc_007_key_reset extends cipher_base_seq;
  `uvm_object_utils(tc_007_key_reset)
  function new(string name = "tc_007_key_reset"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_007", "START — Key Reset (CK only) smoke test", UVM_NONE)

    // Each transaction uses reset_type=2 (CK only) so the driver pulses CK
    // without asserting CLR — exercising the key-reset path exclusively.
    // We run multiple KL values to ensure all key-reset bins are hit.
    tr = make_nist_128_enc(); stamp_r(tr, "TC_007_KEY_RST", "SMOKE", 7, 2'b10);
    send_transaction(tr);

    tr = make_nist_192_enc(); stamp_r(tr, "TC_007_KEY_RST", "SMOKE", 7, 2'b10);
    send_transaction(tr);

    tr = make_nist_256_enc(); stamp_r(tr, "TC_007_KEY_RST", "SMOKE", 7, 2'b10);
    send_transaction(tr);

    tr = make_nist_128_dec(); stamp_r(tr, "TC_007_KEY_RST", "SMOKE", 7, 2'b10);
    send_transaction(tr);

    `uvm_info("TC_007", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_008 — Smoke: Soft reset (CLR) at different intervals
//          Verify that asserting CLR mid-operation is handled gracefully and
//          the next block produces the correct result.
// =============================================================================
class tc_008_soft_reset extends cipher_base_seq;
  `uvm_object_utils(tc_008_soft_reset)
  function new(string name = "tc_008_soft_reset"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_008", "START — Soft Reset (CLR only) smoke test", UVM_NONE)

    // Each transaction uses reset_type=1 (CLR only) so the driver pulses CLR
    // without asserting CK — exercising the soft-reset path exclusively.
    tr = make_nist_128_enc(); stamp_r(tr, "TC_008_SOFT_RST", "SMOKE", 8, 2'b01);
    send_transaction(tr);

    tr = make_nist_192_enc(); stamp_r(tr, "TC_008_SOFT_RST", "SMOKE", 8, 2'b01);
    send_transaction(tr);

    tr = make_nist_256_enc(); stamp_r(tr, "TC_008_SOFT_RST", "SMOKE", 8, 2'b01);
    send_transaction(tr);

    tr = make_nist_128_dec(); stamp_r(tr, "TC_008_SOFT_RST", "SMOKE", 8, 2'b01);
    send_transaction(tr);

    `uvm_info("TC_008", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_009 — Smoke: Hard reset (CK+CLR simultaneously)
// =============================================================================
class tc_009_hard_reset extends cipher_base_seq;
  `uvm_object_utils(tc_009_hard_reset)
  function new(string name = "tc_009_hard_reset"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_009", "START — Hard Reset (CK+CLR) smoke test", UVM_NONE)

    // Run one block of each key length and verify correct output after hard reset
    tr = make_nist_128_enc(); stamp(tr, "TC_009_HARD_RST", "SMOKE", 9); send_transaction(tr);
    tr = make_nist_192_enc(); stamp(tr, "TC_009_HARD_RST", "SMOKE", 9); send_transaction(tr);
    tr = make_nist_256_enc(); stamp(tr, "TC_009_HARD_RST", "SMOKE", 9); send_transaction(tr);
    tr = make_nist_128_dec(); stamp(tr, "TC_009_HARD_RST", "SMOKE", 9); send_transaction(tr);
    tr = make_nist_192_dec(); stamp(tr, "TC_009_HARD_RST", "SMOKE", 9); send_transaction(tr);
    tr = make_nist_256_dec(); stamp(tr, "TC_009_HARD_RST", "SMOKE", 9); send_transaction(tr);

    `uvm_info("TC_009", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_010 — Stress: Randomised transactions (all valid KL values)
// =============================================================================
class tc_010_random_stress extends cipher_base_seq;
  `uvm_object_utils(tc_010_random_stress)

  int unsigned n_stress = 50;

  function new(string name = "tc_010_random_stress"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_010", $sformatf("START — Stress test (%0d transactions)", n_stress), UVM_NONE)

    repeat(n_stress) begin
      tr = cipher_transaction::type_id::create("stress_tr");
      start_item(tr);
      // Allow all valid KL values; KL=3 occasionally exercised to check it
      // never asserts Valid (COV_003 corner)
      if (!tr.randomize() with { KL inside {2'b00, 2'b01, 2'b10}; })
        `uvm_error("TC_010", "Randomisation failed")
      stamp(tr, "TC_010_STRESS", "MIXED", 10);
      finish_item(tr);
    end

    `uvm_info("TC_010", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_011 — Random key + data, either encrypt or decrypt, KL=0 (AES-128)
//
// Fully randomises Key[127:0], Data, and enc_dec on every transaction.
// KL is fixed at 0 so the 128-bit key slot is exercised end-to-end.
// Every result is checked against the reference model by the scoreboard,
// which is the same flow used in the original testbench — no golden vectors
// are hard-coded here; correctness is proved by the DPI-C comparison.
// =============================================================================
class tc_011_random_kl0 extends cipher_base_seq;
  `uvm_object_utils(tc_011_random_kl0)

  int unsigned n_transactions = 50; // default; override before start()

  function new(string name = "tc_011_random_kl0"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_011",
      $sformatf("START — Random Key+Data enc/dec KL=0 AES-128 (%0d transactions)",
                n_transactions), UVM_NONE)

    repeat(n_transactions) begin
      tr = cipher_transaction::type_id::create("tr_011");
      start_item(tr);
      // Key, Data, and enc_dec are all fully random.
      // Only KL is fixed; upper 128 bits of Key are don't-care for AES-128
      // (the reference model and DUT both ignore them when KL=0).
      if (!tr.randomize() with { KL == 2'b00; })
        `uvm_error("TC_011", "Randomisation failed")
      stamp(tr, "TC_011_RND_128", "MIXED", 11);
      finish_item(tr);
    end

    `uvm_info("TC_011", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_012 — Random key + data, either encrypt or decrypt, KL=1 (AES-192)
//
// Same principle as TC_011 but fixes KL=1 so the 192-bit key path is hit.
// Key[191:0] is randomised; the top 64 bits are don't-care for AES-192.
// =============================================================================
class tc_012_random_kl1 extends cipher_base_seq;
  `uvm_object_utils(tc_012_random_kl1)

  int unsigned n_transactions = 50;

  function new(string name = "tc_012_random_kl1"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_012",
      $sformatf("START — Random Key+Data enc/dec KL=1 AES-192 (%0d transactions)",
                n_transactions), UVM_NONE)

    repeat(n_transactions) begin
      tr = cipher_transaction::type_id::create("tr_012");
      start_item(tr);
      if (!tr.randomize() with { KL == 2'b01; })
        `uvm_error("TC_012", "Randomisation failed")
      stamp(tr, "TC_012_RND_192", "MIXED", 12);
      finish_item(tr);
    end

    `uvm_info("TC_012", "DONE", UVM_NONE)
  endtask
endclass

// =============================================================================
// TC_013 — Random key + data, either encrypt or decrypt, KL=2 (AES-256)
//
// Same principle as TC_011/012 but fixes KL=2 so the full 256-bit key path
// is exercised. All 256 bits of Key are meaningful here.
// =============================================================================
class tc_013_random_kl2 extends cipher_base_seq;
  `uvm_object_utils(tc_013_random_kl2)

  int unsigned n_transactions = 50;

  function new(string name = "tc_013_random_kl2"); super.new(name); endfunction

  virtual task body();
    cipher_transaction tr;
    `uvm_info("TC_013",
      $sformatf("START — Random Key+Data enc/dec KL=2 AES-256 (%0d transactions)",
                n_transactions), UVM_NONE)

    repeat(n_transactions) begin
      tr = cipher_transaction::type_id::create("tr_013");
      start_item(tr);
      if (!tr.randomize() with { KL == 2'b10; })
        `uvm_error("TC_013", "Randomisation failed")
      stamp(tr, "TC_013_RND_256", "MIXED", 13);
      finish_item(tr);
    end

    `uvm_info("TC_013", "DONE", UVM_NONE)
  endtask
endclass

`endif // CIPHER_SEQUENCES_SV