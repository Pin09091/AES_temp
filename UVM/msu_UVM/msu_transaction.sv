// =============================================================================
// File        : msu_transaction.sv
// Description : UVM sequence item for mode_selection_unit.
//               Carries one complete encrypt/decrypt request and the
//               corresponding DUT response captured by the monitor.
// =============================================================================
`ifndef MSU_TRANSACTION_SV
`define MSU_TRANSACTION_SV

class msu_transaction extends uvm_sequence_item;

    // ---- Stimulus fields (randomisable) ------------------------------------
    rand bit [127:0] DataIn;
    rand bit [127:0] KeyIn1;     // upper 128b of key (AES-192 / AES-256)
    rand bit [127:0] KeyIn2;     // lower 128b of key (always used)
    rand bit [127:0] IVIn;       // IV (used by CBC / OFB / CFB / CTR)
    rand bit [2:0]   ModeSelect; // 000=ECB 001=CBC 010=OFB 011=CFB 100=CTR
    rand bit [1:0]   KeySelect;  // 00=AES-128  01=AES-192  10=AES-256
    rand bit         enc_dec;    // 1 = encrypt, 0 = decrypt

    // ---- Result fields (filled by monitor / driver) ------------------------
    bit [127:0] dut_result;      // DataOut captured on OF pulse
    bit         of_seen;         // 1 if OF pulsed for this transaction
    bit         is_output;       // 0 = input txn, 1 = output txn (monitor use)

    // ---- Default constraints -----------------------------------------------
    constraint c_valid_mode { ModeSelect inside {3'b000, 3'b001, 3'b010, 3'b011, 3'b100}; }
    constraint c_valid_kl   { KeySelect  inside {2'b00,  2'b01,  2'b10};  }

    `uvm_object_utils_begin(msu_transaction)
        `uvm_field_int(DataIn,     UVM_ALL_ON)
        `uvm_field_int(KeyIn1,     UVM_ALL_ON)
        `uvm_field_int(KeyIn2,     UVM_ALL_ON)
        `uvm_field_int(IVIn,       UVM_ALL_ON)
        `uvm_field_int(ModeSelect, UVM_ALL_ON)
        `uvm_field_int(KeySelect,  UVM_ALL_ON)
        `uvm_field_int(enc_dec,    UVM_ALL_ON)
        `uvm_field_int(dut_result, UVM_ALL_ON)
        `uvm_field_int(of_seen,    UVM_ALL_ON)
        `uvm_field_int(is_output,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "msu_transaction");
        super.new(name);
    endfunction

    // Human-readable summary
    virtual function string convert2string();
        string mode_str, kl_str;
        case (ModeSelect)
            3'b000: mode_str = "ECB";
            3'b001: mode_str = "CBC";
            3'b010: mode_str = "OFB";
            3'b011: mode_str = "CFB";
            3'b100: mode_str = "CTR";
            default: mode_str = "???";
        endcase
        case (KeySelect)
            2'b00: kl_str = "AES-128";
            2'b01: kl_str = "AES-192";
            2'b10: kl_str = "AES-256";
            default: kl_str = "???";
        endcase
        if (is_output)
            return $sformatf("%s %s %s DataIn=%h | DataOut=%h OF=%b",
                mode_str, kl_str, enc_dec ? "ENC" : "DEC",
                DataIn, dut_result, of_seen);
        else
            return $sformatf("%s %s %s DataIn=%h KeyIn2=%h IV=%h",
                mode_str, kl_str, enc_dec ? "ENC" : "DEC",
                DataIn, KeyIn2, IVIn);
    endfunction

endclass : msu_transaction

`endif // MSU_TRANSACTION_SV
