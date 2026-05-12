`timescale 1ns / 1ps
// =============================================================================
// Module: AES  (Top-Level)
// =============================================================================
// Description:
//   Top-level wrapper for the AES encryption/decryption .
//   Instantiates both interface controllers and the AES Mode Selection Unit
//   (MSU), and multiplexes between them based on the `interface_toggle` pin.
//   details about the operation are mentioned in depth in the testbench
//
//   Only ONE interface should be active at a time:
//     interface_toggle = 1 ? AXI4-Lite  interface (AXI_main)
//     interface_toggle = 0 ? Avalon-MM   interface (AvalonMM_MSU)
//
// Clock Architecture:
//   - AXI path  : S_AXI_ACLK (fed to AXI_main and gated for MSU when AXI active)
//   - Avalon path: AVA_CLK   (fed to AvalonMM_MSU and gated for MSU when Ava active)
//   - MSU_CLK   : Gated clock = (interface_toggle ? S_AXI_ACLK : AVA_CLK)
//                              AND the respective Enable_MSU signal.
//                 Enable_MSU gates the clock to save power when the MSU is idle.
//
// Reset Architecture:
//   - AXI_main uses active-LOW  reset (S_AXI_ARESETn).
//   - AvalonMM_MSU uses active-HIGH reset (AVA_RST).
//   - RST_MSU (from the active interface) drives the MSU reset (active-HIGH).
//
// Dependencies: AXI_main, AvalonMM_MSU, mode_selection_unit
// =============================================================================
module AES(
input logic interface_toggle,//toggle for choosing interface 0-avalon 1-axi


input logic S_AXI_ACLK,//AXI inputs
input logic S_AXI_ARESETn,

input logic S_AXI_AWVALID,
output logic S_AXI_AWREADY,
input logic [63:0]S_AXI_AWADDR,

input logic S_AXI_WVALID,
output logic S_AXI_WREADY,
input logic [7:0]S_AXI_WSTRB,
input logic [63:0]S_AXI_WDATA,

output logic S_AXI_BVALID,
input logic S_AXI_BREADY,
output logic [1:0]S_AXI_BRESP,

input logic S_AXI_ARVALID,
output logic S_AXI_ARREADY,
input logic [63:0]S_AXI_ARADDR,

output logic S_AXI_RVALID,
input logic S_AXI_RREADY,
output logic [63:0]S_AXI_RDATA,
output logic [1:0]S_AXI_RRESP,


input  logic AVA_CLK,// avalon inputs
input  logic AVA_RST,
input  logic [127:0] writedata_h,
input  logic [31:0]  address_h,
input  logic write_h,
input  logic read_h,
output logic [127:0] readdata_h,
output logic waitrequest_h,
output logic readdatavalid_h,
output logic error
);

logic [127:0]DataIn_axi;// MSU inputs from axi
logic [127:0]KeyIn1_axi;
logic [127:0]KeyIn2_axi;
logic [127:0]IVIn_axi;
logic [2:0]ModeSelect_axi;
logic [1:0] KeySelect_axi;
logic Enable_MSU_axi;
logic RST_MSU_axi;
logic enc_dec_axi;

logic [127:0]DataIn_ava;// MSU inputs from axi
logic [127:0]KeyIn1_ava;
logic [127:0]KeyIn2_ava;
logic [127:0]IVIn_ava;
logic [2:0]ModeSelect_ava;
logic [1:0] KeySelect_ava;
logic Enable_MSU_ava;
logic RST_MSU_ava;
logic enc_dec_ava;


logic OF;//MSU outputs
logic RF;
logic [127:0] DataOut;

//interface declerations
AXI_main    axi(
.S_AXI_ACLK(S_AXI_ACLK),
.S_AXI_ARESETn(S_AXI_ARESETn),

.S_AXI_AWVALID(S_AXI_AWVALID),
.S_AXI_AWREADY(S_AXI_AWREADY),
.S_AXI_AWADDR(S_AXI_AWADDR),

.S_AXI_WVALID(S_AXI_WVALID),
.S_AXI_WREADY(S_AXI_WREADY),
.S_AXI_WSTRB(S_AXI_WSTRB),
.S_AXI_WDATA(S_AXI_WDATA),

.S_AXI_BVALID(S_AXI_BVALID),
.S_AXI_BREADY(S_AXI_BREADY),
.S_AXI_BRESP(S_AXI_BRESP),

.S_AXI_ARVALID(S_AXI_ARVALID),
.S_AXI_ARREADY(S_AXI_ARREADY),
.S_AXI_ARADDR(S_AXI_ARADDR),

.S_AXI_RVALID(S_AXI_RVALID),
.S_AXI_RREADY(S_AXI_RREADY),
.S_AXI_RDATA(S_AXI_RDATA),
.S_AXI_RRESP(S_AXI_RRESP),


.DataIn(DataIn_axi),// MSU inputs
.KeyIn1(KeyIn1_axi),
.KeyIn2(KeyIn2_axi),
.IVIn(IVIn_axi),
.ModeSelect(ModeSelect_axi),
.KeySelect(KeySelect_axi),
.Enable_MSU(Enable_MSU_axi),
.enc_dec(enc_dec_axi),
.RST_MSU(RST_MSU_axi),
.OF(OF),
.RF(RF),
.DataOut(DataOut)
    );
    
AvalonMM_MSU  ava(    
.CLK(AVA_CLK),
.RST(AVA_RST),
.writedata_h(writedata_h),
.address_h(address_h),
.write_h(write_h),
.read_h(read_h),
.readdata_h(readdata_h),
.waitrequest_h(waitrequest_h),
.readdatavalid_h(readdatavalid_h),
.error(error),
        
.DataIn(DataIn_ava),
.KeyIn1(KeyIn1_ava),
.KeyIn2(KeyIn2_ava),
.IVIn(IVIn_ava),
.ModeSelect(ModeSelect_ava),
.KeySelect(KeySelect_ava),
.Enable_MSU(Enable_MSU_ava),
.RST_MSU(RST_MSU_ava),
.enc_dec(enc_dec_ava),
.OF(OF),
.RF(RF),
.DataOut(DataOut)
    );


//MSU declerations
wire MSU_CLK = interface_toggle?(S_AXI_ACLK & Enable_MSU_axi):(AVA_CLK & Enable_MSU_ava);

wire [127:0]DataIn = interface_toggle?(DataIn_axi):(DataIn_ava);// MSU inputs
wire [127:0]KeyIn1 = interface_toggle?(KeyIn1_axi):(KeyIn1_ava);
wire [127:0]KeyIn2 = interface_toggle?(KeyIn2_axi):(KeyIn2_ava);
wire [127:0]IVIn = interface_toggle?(IVIn_axi):(IVIn_ava);
wire [2:0]ModeSelect = interface_toggle?(ModeSelect_axi):(ModeSelect_ava);
wire [1:0] KeySelect = interface_toggle?(KeySelect_axi):(KeySelect_ava);
wire RST_MSU = interface_toggle?(RST_MSU_axi):(RST_MSU_ava);
wire enc_dec = interface_toggle?(enc_dec_axi):(enc_dec_ava);


mode_selection_unit msu(
.DataIn(DataIn), 
.KeyIn1(KeyIn1), 
.KeyIn2(KeyIn2), 
.IVIn(IVIn),
.ModeSelect(ModeSelect), 
.KeySelect(KeySelect), 
.RST(RST_MSU), 
.CLK(MSU_CLK), 
.enc_dec(enc_dec),
.DataOut(DataOut), 
.OF(OF), 
.RF(RF)
);


endmodule
