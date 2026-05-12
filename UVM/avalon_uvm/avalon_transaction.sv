// =============================================================================
// File        : avalon_transaction.sv
// Description : UVM sequence item for AvalonMM_MSU.
//
//   Two kinds of transaction are modelled:
//     AVALON_WRITE  — host writes one 128-bit word to an address (0–4)
//     AVALON_READ   — host reads from address 0 (Status) or 1 (DataOut)
//
//   A complete "operation" in the testbench is:
//     1. Write addr 1..4 (data, keys, IV)
//     2. Write addr 0  (control word — sets Enable_MSU among other fields)
//     3. Optionally drive OF/DataOut stub to simulate MSU completion
//     4. Read  addr 0  (Status register)
//     5. Read  addr 1  (Output data)
// =============================================================================
`ifndef AVALON_TRANSACTION_SV
`define AVALON_TRANSACTION_SV

class avalon_transaction extends uvm_sequence_item;

    // ---- Transaction kind ---------------------------------------------------
    typedef enum logic { AVALON_WRITE = 1'b0, AVALON_READ = 1'b1 } av_kind_e;
    rand av_kind_e kind;

    // ---- Avalon-MM fields ---------------------------------------------------
    rand logic [31:0]  address;    // 0–4 (write map) / 0–1 (read map)
    rand logic [127:0] wdata;      // payload for writes
         logic [127:0] rdata;      // captured by driver on a read
         logic         rd_valid;   // 1 when rdata is meaningful
         logic         av_error;   // error signal captured

    // ---- MSU stub fields (set by sequence, used by driver) ------------------
    // These are driven on the DUT's MSU-side input ports after a write to
    // addr 0 (control) to simulate the MSU completing its operation.
    logic         of_pulse;        // drive OF = 1 for one cycle
    logic         rf_pulse;        // drive RF = 1 for one cycle
    logic [127:0] msu_dataout;     // value to present on DataOut when OF pulses
    int unsigned  of_delay_cycles; // cycles after control write before OF fires

    // ---- Constraints --------------------------------------------------------
    // Write addresses: 0=Control, 1=DataIn, 2=KeyIn1, 3=KeyIn2, 4=IVIn
    constraint c_write_addr { kind == AVALON_WRITE -> address inside {[0:4]}; }
    // Read addresses:  0=Status, 1=DataOut
    constraint c_read_addr  { kind == AVALON_READ  -> address inside {0, 1}; }
    // By default no OF/RF stub pulse
    constraint c_of_default { of_pulse == 1'b0; }

    `uvm_object_utils_begin(avalon_transaction)
        `uvm_field_enum(av_kind_e, kind,    UVM_ALL_ON)
        `uvm_field_int(address,             UVM_ALL_ON)
        `uvm_field_int(wdata,               UVM_ALL_ON)
        `uvm_field_int(rdata,               UVM_ALL_ON)
        `uvm_field_int(rd_valid,            UVM_ALL_ON)
        `uvm_field_int(av_error,            UVM_ALL_ON)
        `uvm_field_int(of_pulse,            UVM_ALL_ON)
        `uvm_field_int(msu_dataout,         UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "avalon_transaction");
        super.new(name);
        of_pulse        = 1'b0;
        rf_pulse        = 1'b0;
        msu_dataout     = '0;
        of_delay_cycles = 0;
        rd_valid        = 1'b0;
        av_error        = 1'b0;
    endfunction

    virtual function string convert2string();
        if (kind == AVALON_WRITE)
            return $sformatf("WRITE addr=0x%0h data=0x%032h of_pulse=%b",
                             address, wdata, of_pulse);
        else
            return $sformatf("READ  addr=0x%0h rdata=0x%032h valid=%b err=%b",
                             address, rdata, rd_valid, av_error);
    endfunction

endclass : avalon_transaction

`endif // AVALON_TRANSACTION_SV
