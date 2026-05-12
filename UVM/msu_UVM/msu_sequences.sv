// =============================================================================
// File        : msu_sequences.sv
// Description : All test sequences for mode_selection_unit.
//
//   TC_001  ECB, AES-128, Encrypt  (NIST vector + random blocks)
//   TC_002  ECB, AES-192, Encrypt  (NIST vector + random blocks)
//   TC_003  ECB, AES-256, Encrypt  (NIST vector + random blocks)
//   TC_004  ECB, AES-128, Decrypt  (NIST vector + random blocks)
//   TC_005  ECB, AES-192, Decrypt  (NIST vector + random blocks)
//   TC_006  ECB, AES-256, Decrypt  (NIST vector + random blocks)
//   TC_007  CBC, AES-128, Encrypt
//   TC_008  CBC, AES-192, Encrypt
//   TC_009  CBC, AES-256, Encrypt
//   TC_010  CBC, AES-128, Decrypt
//   TC_011  OFB, AES-256, Encrypt + Decrypt
//   TC_012  CFB, AES-128, Encrypt + Decrypt
//   TC_013  CTR, AES-256, Encrypt  +  AES-192, Decrypt
//   TC_014  Random stress — all modes, all key lengths, both directions
// =============================================================================
`ifndef MSU_SEQUENCES_SV
`define MSU_SEQUENCES_SV

// =============================================================================
// Base sequence — NIST helper vectors and send helper
// =============================================================================
class msu_base_seq extends uvm_sequence #(msu_transaction);
    `uvm_object_utils(msu_base_seq)
    `uvm_declare_p_sequencer(uvm_sequencer #(msu_transaction))

    int unsigned n_random = 4; // random blocks to append after directed ones

    function new(string name = "msu_base_seq");
        super.new(name);
    endfunction

    // ---- NIST FIPS-197 ECB vectors (Appendix B / C) ----------------------

    // AES-128 encrypt: key=2b7e...f3c  pt=6bc1...72a
    function msu_transaction nist_ecb_128_enc();
        msu_transaction tr = msu_transaction::type_id::create("n128e");
        tr.ModeSelect = 3'b000; tr.KeySelect = 2'b00; tr.enc_dec = 1'b1;
        tr.KeyIn2  = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        tr.KeyIn1  = 128'h0;
        tr.DataIn  = 128'h6bc1bee22e409f96e93d7e117393172a;
        tr.IVIn    = 128'h0;
        return tr;
    endfunction

    // AES-128 decrypt: same key, ct=3ad7...f97
    function msu_transaction nist_ecb_128_dec();
        msu_transaction tr = nist_ecb_128_enc();
        tr.enc_dec = 1'b0;
        tr.DataIn  = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
        return tr;
    endfunction

    // AES-192 encrypt: key=8e73...6b7b  pt=6bc1...72a
    function msu_transaction nist_ecb_192_enc();
        msu_transaction tr = msu_transaction::type_id::create("n192e");
        tr.ModeSelect = 3'b000; tr.KeySelect = 2'b01; tr.enc_dec = 1'b1;
        tr.KeyIn2  = 128'h8e73b0f7da0e6452c810f32b809079e5;
        tr.KeyIn1  = 128'h62f8ead2522c6b7b00000000000000000; // padded
        tr.DataIn  = 128'h6bc1bee22e409f96e93d7e117393172a;
        tr.IVIn    = 128'h0;
        return tr;
    endfunction

    // AES-192 decrypt: ct=bd33...5cc
    function msu_transaction nist_ecb_192_dec();
        msu_transaction tr = nist_ecb_192_enc();
        tr.enc_dec = 1'b0;
        tr.DataIn  = 128'hbd334f1d6e45f25ff712a214571fa5cc;
        return tr;
    endfunction

    // AES-256 encrypt: key=603d...ff4  pt=6bc1...72a
    function msu_transaction nist_ecb_256_enc();
        msu_transaction tr = msu_transaction::type_id::create("n256e");
        tr.ModeSelect = 3'b000; tr.KeySelect = 2'b10; tr.enc_dec = 1'b1;
        tr.KeyIn2  = 128'h603deb1015ca71be2b73aef0857d7781;
        tr.KeyIn1  = 128'h1f352c073b6108d72d9810a30914dff4;
        tr.DataIn  = 128'h6bc1bee22e409f96e93d7e117393172a;
        tr.IVIn    = 128'h0;
        return tr;
    endfunction

    // AES-256 decrypt: ct=f3ee...f8
    function msu_transaction nist_ecb_256_dec();
        msu_transaction tr = nist_ecb_256_enc();
        tr.enc_dec = 1'b0;
        tr.DataIn  = 128'hf3eed1bdb5d2a03c064b5a7e3db181f8;
        return tr;
    endfunction

    // Helper: send a pre-built transaction
    task send(msu_transaction tr);
        start_item(tr);
        finish_item(tr);
    endtask

    // Helper: send n random transactions with fixed mode/key/dir
    task send_random(int unsigned n,
                     bit [2:0] mode, bit [1:0] kl, bit ed);
        msu_transaction tr;
        repeat (n) begin
            tr = msu_transaction::type_id::create("rnd");
            start_item(tr);
            assert(tr.randomize() with {
                ModeSelect == mode;
                KeySelect  == kl;
                enc_dec    == ed;
            }) else `uvm_fatal("SEQ", "randomize() failed");
            finish_item(tr);
        end
    endtask

endclass : msu_base_seq


// =============================================================================
// TC_001  ECB AES-128 Encrypt
// =============================================================================
class tc_001_ecb_enc_128 extends msu_base_seq;
    `uvm_object_utils(tc_001_ecb_enc_128)
    function new(string name = "tc_001_ecb_enc_128"); super.new(name); endfunction
    virtual task body();
        send(nist_ecb_128_enc());
        send_random(n_random, 3'b000, 2'b00, 1'b1);
    endtask
endclass

// =============================================================================
// TC_002  ECB AES-192 Encrypt
// =============================================================================
class tc_002_ecb_enc_192 extends msu_base_seq;
    `uvm_object_utils(tc_002_ecb_enc_192)
    function new(string name = "tc_002_ecb_enc_192"); super.new(name); endfunction
    virtual task body();
        send(nist_ecb_192_enc());
        send_random(n_random, 3'b000, 2'b01, 1'b1);
    endtask
endclass

// =============================================================================
// TC_003  ECB AES-256 Encrypt
// =============================================================================
class tc_003_ecb_enc_256 extends msu_base_seq;
    `uvm_object_utils(tc_003_ecb_enc_256)
    function new(string name = "tc_003_ecb_enc_256"); super.new(name); endfunction
    virtual task body();
        send(nist_ecb_256_enc());
        send_random(n_random, 3'b000, 2'b10, 1'b1);
    endtask
endclass

// =============================================================================
// TC_004  ECB AES-128 Decrypt
// =============================================================================
class tc_004_ecb_dec_128 extends msu_base_seq;
    `uvm_object_utils(tc_004_ecb_dec_128)
    function new(string name = "tc_004_ecb_dec_128"); super.new(name); endfunction
    virtual task body();
        send(nist_ecb_128_dec());
        send_random(n_random, 3'b000, 2'b00, 1'b0);
    endtask
endclass

// =============================================================================
// TC_005  ECB AES-192 Decrypt
// =============================================================================
class tc_005_ecb_dec_192 extends msu_base_seq;
    `uvm_object_utils(tc_005_ecb_dec_192)
    function new(string name = "tc_005_ecb_dec_192"); super.new(name); endfunction
    virtual task body();
        send(nist_ecb_192_dec());
        send_random(n_random, 3'b000, 2'b01, 1'b0);
    endtask
endclass

// =============================================================================
// TC_006  ECB AES-256 Decrypt
// =============================================================================
class tc_006_ecb_dec_256 extends msu_base_seq;
    `uvm_object_utils(tc_006_ecb_dec_256)
    function new(string name = "tc_006_ecb_dec_256"); super.new(name); endfunction
    virtual task body();
        send(nist_ecb_256_dec());
        send_random(n_random, 3'b000, 2'b10, 1'b0);
    endtask
endclass

// =============================================================================
// TC_007  CBC AES-128 Encrypt
// =============================================================================
class tc_007_cbc_enc_128 extends msu_base_seq;
    `uvm_object_utils(tc_007_cbc_enc_128)
    function new(string name = "tc_007_cbc_enc_128"); super.new(name); endfunction
    virtual task body();
        // NIST SP 800-38A CBC-AES-128 F.2.1 vector
        msu_transaction tr = msu_transaction::type_id::create("cbc128e_nist");
        tr.ModeSelect = 3'b001; tr.KeySelect = 2'b00; tr.enc_dec = 1'b1;
        tr.KeyIn2 = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        tr.KeyIn1 = 128'h0;
        tr.DataIn = 128'h6bc1bee22e409f96e93d7e117393172a;
        tr.IVIn   = 128'h000102030405060708090a0b0c0d0e0f;
        send(tr);
        send_random(n_random, 3'b001, 2'b00, 1'b1);
    endtask
endclass

// =============================================================================
// TC_008  CBC AES-192 Encrypt
// =============================================================================
class tc_008_cbc_enc_192 extends msu_base_seq;
    `uvm_object_utils(tc_008_cbc_enc_192)
    function new(string name = "tc_008_cbc_enc_192"); super.new(name); endfunction
    virtual task body();
        send_random(n_random + 1, 3'b001, 2'b01, 1'b1);
    endtask
endclass

// =============================================================================
// TC_009  CBC AES-256 Encrypt
// =============================================================================
class tc_009_cbc_enc_256 extends msu_base_seq;
    `uvm_object_utils(tc_009_cbc_enc_256)
    function new(string name = "tc_009_cbc_enc_256"); super.new(name); endfunction
    virtual task body();
        send_random(n_random + 1, 3'b001, 2'b10, 1'b1);
    endtask
endclass

// =============================================================================
// TC_010  CBC AES-128 Decrypt
// =============================================================================
class tc_010_cbc_dec_128 extends msu_base_seq;
    `uvm_object_utils(tc_010_cbc_dec_128)
    function new(string name = "tc_010_cbc_dec_128"); super.new(name); endfunction
    virtual task body();
        send_random(n_random + 1, 3'b001, 2'b00, 1'b0);
    endtask
endclass

// =============================================================================
// TC_011  OFB AES-256 Encrypt + Decrypt
// =============================================================================
class tc_011_ofb_256 extends msu_base_seq;
    `uvm_object_utils(tc_011_ofb_256)
    function new(string name = "tc_011_ofb_256"); super.new(name); endfunction
    virtual task body();
        send_random(n_random, 3'b010, 2'b10, 1'b1);
        send_random(n_random, 3'b010, 2'b10, 1'b0);
    endtask
endclass

// =============================================================================
// TC_012  CFB AES-128 Encrypt + Decrypt
// =============================================================================
class tc_012_cfb_128 extends msu_base_seq;
    `uvm_object_utils(tc_012_cfb_128)
    function new(string name = "tc_012_cfb_128"); super.new(name); endfunction
    virtual task body();
        send_random(n_random, 3'b011, 2'b00, 1'b1);
        send_random(n_random, 3'b011, 2'b00, 1'b0);
    endtask
endclass

// =============================================================================
// TC_013  CTR AES-256 Encrypt  +  CTR AES-192 Decrypt
// =============================================================================
class tc_013_ctr extends msu_base_seq;
    `uvm_object_utils(tc_013_ctr)
    function new(string name = "tc_013_ctr"); super.new(name); endfunction
    virtual task body();
        send_random(n_random, 3'b100, 2'b10, 1'b1);  // CTR-256 enc
        send_random(n_random, 3'b100, 2'b01, 1'b0);  // CTR-192 dec
    endtask
endclass

// =============================================================================
// TC_014  Random stress — fully random across all modes/keys/directions
// =============================================================================
class tc_014_random_stress extends msu_base_seq;
    `uvm_object_utils(tc_014_random_stress)
    int unsigned n_stress = 30;
    function new(string name = "tc_014_random_stress"); super.new(name); endfunction
    virtual task body();
        msu_transaction tr;
        repeat (n_stress) begin
            tr = msu_transaction::type_id::create("stress");
            start_item(tr);
            assert(tr.randomize()) else `uvm_fatal("SEQ", "randomize() failed");
            finish_item(tr);
        end
    endtask
endclass

`endif // MSU_SEQUENCES_SV
