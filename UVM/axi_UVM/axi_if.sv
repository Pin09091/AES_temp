`timescale 1ns/1ps

interface axi_if (input logic clk);

    // Top-level mux select (1 = AXI, 0 = Avalon) – matches AES wrapper
    logic        interface_toggle;

    // Global
    logic        ARESETn;

    // Write Address Channel
    logic        AWVALID;
    logic        AWREADY;
    logic [63:0] AWADDR;

    // Write Data Channel
    logic        WVALID;
    logic        WREADY;
    logic [7:0]  WSTRB;
    logic [63:0] WDATA;

    // Write Response Channel
    logic        BVALID;
    logic        BREADY;
    logic [1:0]  BRESP;

    // Read Address Channel
    logic        ARVALID;
    logic        ARREADY;
    logic [63:0] ARADDR;

    // Read Data Channel
    logic        RVALID;
    logic        RREADY;
    logic [63:0] RDATA;
    logic [1:0]  RRESP;

    // MSU side-band signals (outputs of DUT observed by monitor)
    logic [127:0] DataIn;
    logic [127:0] KeyIn1;
    logic [127:0] KeyIn2;
    logic [127:0] IVIn;
    logic [2:0]   ModeSelect;
    logic [1:0]   KeySelect;
    logic         Enable_MSU;
    logic         RST_MSU;
    logic         enc_dec;

    // MSU response signals (driven by testbench stub)
    logic         OF;
    logic         RF;
    logic [127:0] DataOut;

    // ------------------------------------------------------------------
    // Clocking blocks
    // ------------------------------------------------------------------
    clocking master_cb @(posedge clk);
        default input #1 output #1;
        output ARESETn;
        output AWVALID, AWADDR;
        input  AWREADY;
        output WVALID, WSTRB, WDATA;
        input  WREADY;
        output BREADY;
        input  BVALID, BRESP;
        output ARVALID, ARADDR;
        input  ARREADY;
        output RREADY;
        input  RVALID, RDATA, RRESP;
    endclocking

    clocking monitor_cb @(posedge clk);
        default input #1;
        input ARESETn;
        input AWVALID, AWADDR, AWREADY;
        input WVALID, WSTRB, WDATA, WREADY;
        input BVALID, BREADY, BRESP;
        input ARVALID, ARADDR, ARREADY;
        input RVALID, RREADY, RDATA, RRESP;
        input DataIn, KeyIn1, KeyIn2, IVIn;
        input ModeSelect, KeySelect, Enable_MSU, RST_MSU, enc_dec;
        input OF, RF, DataOut;
    endclocking

    modport master_mp (clocking master_cb, input clk);
    modport monitor_mp(clocking monitor_cb, input clk);
endinterface