// =============================================================================
// File        : avalon_if.sv
// Description : SystemVerilog interface for the AvalonMM_MSU DUT.
//               Wraps all Avalon-MM host-side signals plus the MSU sideband
//               signals (outputs observed by the monitor, inputs driven by
//               the testbench stub to simulate MSU responses).
// =============================================================================
`ifndef AVALON_IF_SV
`define AVALON_IF_SV

interface avalon_if (input logic CLK);

    // ---- Avalon-MM host → DUT -----------------------------------------------
    logic [127:0] writedata_h;
    logic [31:0]  address_h;
    logic         write_h;
    logic         read_h;

    // ---- Avalon-MM DUT → host -----------------------------------------------
    logic [127:0] readdata_h;
    logic         waitrequest_h;
    logic         readdatavalid_h;
    logic         error;

    // ---- Avalon reset (active-high) -----------------------------------------
    logic RST;

    // ---- MSU sideband outputs (DUT drives, monitor observes) ----------------
    logic [127:0] DataIn;
    logic [127:0] KeyIn1;
    logic [127:0] KeyIn2;
    logic [127:0] IVIn;
    logic [2:0]   ModeSelect;
    logic [1:0]   KeySelect;
    logic         Enable_MSU;
    logic         RST_MSU;
    logic         enc_dec;

    // ---- MSU sideband inputs (testbench stub drives, DUT reads) -------------
    logic         OF;
    logic         RF;
    logic [127:0] DataOut;

    // ---- Clocking block: host master (driver) --------------------------------
    clocking master_cb @(posedge CLK);
        default input #1 output #1;
        output RST;
        output writedata_h, address_h, write_h, read_h;
        input  waitrequest_h, readdatavalid_h, readdata_h, error;
        // MSU stubs (driven by testbench)
        output OF, RF, DataOut;
    endclocking

    // ---- Clocking block: monitor (passive, all inputs) ----------------------
    clocking monitor_cb @(posedge CLK);
        default input #1;
        input RST;
        input writedata_h, address_h, write_h, read_h;
        input waitrequest_h, readdatavalid_h, readdata_h, error;
        input DataIn, KeyIn1, KeyIn2, IVIn;
        input ModeSelect, KeySelect, Enable_MSU, RST_MSU, enc_dec;
        input OF, RF, DataOut;
    endclocking

    modport master_mp  (clocking master_cb,  input CLK);
    modport monitor_mp (clocking monitor_cb, input CLK);

endinterface : avalon_if

`endif // AVALON_IF_SV
