// =============================================================================
// File        : cipher_transaction.sv
// Description : UVM sequence item carrying one full AES block transaction.
//               Holds the stimulus fields plus result fields populated by the
//               monitor after DUT output is observed.
// =============================================================================
`ifndef CIPHER_TRANSACTION_SV
`define CIPHER_TRANSACTION_SV

class cipher_transaction extends uvm_sequence_item;

  // ---- Stimulus fields (randomisable) ------------------------------------
  rand bit [255:0] Key;       // Full 256-bit key field; lower bits used for 128/192
  rand bit [127:0] Data;      // 128-bit plaintext / ciphertext block
  rand bit         enc_dec;   // 1 = encrypt, 0 = decrypt
  rand bit [1:0]   KL;        // 0=AES-128  1=AES-192  2=AES-256  3=invalid

  // ---- Result fields (filled by monitor) ---------------------------------
  bit [127:0] dut_result;     // output captured from state_o
  bit [127:0] ref_result;     // golden value from reference model
  bit         match;          // 1 if dut_result == ref_result

  // ---- Classification flag -----------------------------------------------
  // 0 = this object carries a DUT input (plaintext / key / mode)
  // 1 = this object carries a DUT output (ciphertext result)
  bit is_output;

  // ---- Test identity — set by each sequence before sending ---------------
  string test_name = "UNKNOWN";
  string mode_str  = "---";
  int    tc_id     = 0;

  // ---- Reset type — controls which reset the driver applies before driving -
  // 0 = hard reset (CLR+CK, default — safe for all feature tests)
  // 1 = soft reset (CLR only — TC_008)
  // 2 = key reset  (CK only  — TC_007)
  bit [1:0] reset_type = 2'b00;

  // ---- Default constraints -----------------------------------------------
  // Exclude KL=3 (invalid) from feature tests; individual sequences override
  constraint c_valid_kl { KL inside {2'b00, 2'b01, 2'b10}; }

  // ---- UVM factory / field macros ----------------------------------------
  `uvm_object_utils_begin(cipher_transaction)
    `uvm_field_int(Key,        UVM_ALL_ON)
    `uvm_field_int(Data,       UVM_ALL_ON)
    `uvm_field_int(enc_dec,    UVM_ALL_ON)
    `uvm_field_int(KL,         UVM_ALL_ON)
    `uvm_field_int(dut_result, UVM_ALL_ON)
    `uvm_field_int(ref_result, UVM_ALL_ON)
    `uvm_field_int(match,      UVM_ALL_ON)
    `uvm_field_int(is_output,  UVM_ALL_ON)
    `uvm_field_string(test_name, UVM_ALL_ON)
    `uvm_field_string(mode_str,  UVM_ALL_ON)
    `uvm_field_int(tc_id,        UVM_ALL_ON)
    `uvm_field_int(reset_type,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "cipher_transaction");
    super.new(name);
  endfunction

  // Human-readable summary
  virtual function string convert2string();
    string s;
    s = $sformatf("KL=%0d enc_dec=%0d Data=0x%032h Key=0x%064h",
                  KL, enc_dec, Data, Key);
    if (is_output)
      s = {s, $sformatf(" | DUT=0x%032h REF=0x%032h %s",
                        dut_result, ref_result, match ? "PASS" : "FAIL")};
    return s;
  endfunction

endclass : cipher_transaction

`endif // CIPHER_TRANSACTION_SV