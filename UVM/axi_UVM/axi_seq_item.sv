`ifndef AXI_SEQ_ITEM_SV
`define AXI_SEQ_ITEM_SV

class axi_seq_item extends uvm_sequence_item;
    `uvm_object_utils(axi_seq_item)

    // ------------------------------------------------------------------
    // Transaction kind
    // ------------------------------------------------------------------
    typedef enum {AXI_WRITE, AXI_READ} axi_kind_e;
    rand axi_kind_e kind;

    // ------------------------------------------------------------------
    // Payload
    // ------------------------------------------------------------------
    rand logic [63:0] addr;
    rand logic [63:0] wdata;
    rand logic [7:0]  wstrb;

    // Response (filled by driver / collected by monitor)
    logic [63:0] rdata;
    logic [1:0]  bresp;
    logic [1:0]  rresp;

    // ------------------------------------------------------------------
    // Constraints
    // ------------------------------------------------------------------
    // Input register map: addr 0..16 are valid write targets
    constraint c_write_addr { kind == AXI_WRITE -> addr inside {[0:16]}; }
    // Read map: 0 = status, 1 = DataOut[63:0], 2 = DataOut[127:64]
    constraint c_read_addr  { kind == AXI_READ  -> addr inside {0, 1, 2}; }
    // Default: full write strobe
    constraint c_wstrb_dist {
        wstrb dist { 8'hFF := 80, 8'h0F := 10, 8'hF0 := 10 };
    }

    function new(string name = "axi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("kind=%s addr=0x%0h wdata=0x%0h wstrb=%0b rdata=0x%0h bresp=%0b rresp=%0b",
                         kind.name(), addr, wdata, wstrb, rdata, bresp, rresp);
    endfunction
endclass

`endif