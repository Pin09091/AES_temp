`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/07/2025 09:16:15 PM
// Design Name: 
// Module Name: AXI_main_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AXI_main_tb();

//declaring everything
logic S_AXI_ACLK = 1;// AXI inputs
logic S_AXI_ARESETn = 0;

logic S_AXI_AWVALID;
logic S_AXI_AWREADY;
logic [63:0]S_AXI_AWADDR;

logic S_AXI_WVALID;
logic S_AXI_WREADY;
logic [7:0]S_AXI_WSTRB;
logic [63:0]S_AXI_WDATA;

logic S_AXI_BVALID;
logic S_AXI_BREADY;
logic [1:0]S_AXI_BRESP;

logic S_AXI_ARVALID;
logic S_AXI_ARREADY;
logic [63:0]S_AXI_ARADDR;

logic S_AXI_RVALID;
logic S_AXI_RREADY;
logic [63:0]S_AXI_RDATA;
logic [1:0]S_AXI_RRESP;



logic [127:0]DataIn;// MSU inputs
logic [127:0]KeyIn1;
logic [127:0]KeyIn2;
logic [127:0]IVIn;
logic [2:0]ModeSelect;
logic [1:0] KeySelect;
logic Enable_MSU;
logic RST_MSU;
logic enc_dec;
logic OF;
logic RF;
logic [127:0] DataOut;

AXI_main    a(

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


.DataIn(DataIn),// MSU inputs
.KeyIn1(KeyIn1),
.KeyIn2(KeyIn2),
.IVIn(IVIn),
.ModeSelect(ModeSelect),
.KeySelect(KeySelect),
.Enable_MSU(Enable_MSU),
.enc_dec(enc_dec),
.RST_MSU(RST_MSU),
.OF(OF),
.RF(RF),
.DataOut(DataOut)
    );

always #20 S_AXI_ACLK = ~S_AXI_ACLK;

logic [31:0]MEMORY_INPUT[16:0];
logic [31:0]MEMORY_OUTPUT[4:0];
logic [1:0]Write_data_state;
logic [1:0]Write_addr_state;
logic [1:0]Read_data_state;
logic [1:0]Read_addr_state;
logic [1:0]BRESP_state;
logic cond;
logic cond_read;

assign MEMORY_INPUT = a.Mem_in;
assign Write_data_state = a.W_State;
assign Write_addr_state = a.AW_State;
assign BRESP_state = a.B_State;
assign cond =a.cond;

assign MEMORY_OUTPUT = a.Mem_out;
assign Read_data_state = a.R_State;
assign Read_addr_state = a.AR_State;
assign cond_read =a.AR_flag;

initial
begin

S_AXI_ARESETn = 0;// reset
#40
OF = 0;
DataOut[127:96] = 32'h1a21d73a;// setting data for  read later on
DataOut[95:64] = 32'h402299b3;
DataOut[63:32] = 32'h571420f6;
DataOut[31:0] = 32'h29c3505f;
#40


S_AXI_ARESETn = 1;// no longer reset

S_AXI_BREADY = 1;//master is ready for a burst

S_AXI_WSTRB = 8'b11111111;
S_AXI_WVALID = 1;// sending data
S_AXI_WDATA = 64'hDEADBEEFDEADCAFE;

S_AXI_AWADDR = 0;
S_AXI_AWVALID = 1;// sending address

S_AXI_RREADY = 1;//not testing reading
S_AXI_ARVALID = 0;//not testing reading

#40
S_AXI_ARESETn = 1;// no longer reset

S_AXI_AWADDR = 1;
S_AXI_AWVALID = 1;// sending address

S_AXI_BREADY = 1;//master is ready for a burst

S_AXI_WSTRB = 8'b11110000;
S_AXI_WVALID = 0;// checking for valid
S_AXI_WDATA = 64'hBEEFBEEFCAFECAFE;


#40
S_AXI_WVALID = 1;// allowing data to be sent

#40
S_AXI_ARESETn = 1;// no longer reset

S_AXI_AWADDR = 14333;//checking for BRESP
S_AXI_AWVALID = 1;// sending address

S_AXI_BREADY = 1;//master is ready for a burst

S_AXI_WSTRB = 8'b11110000;
S_AXI_WVALID = 1;// sending data
S_AXI_WDATA = 64'hBEEFBEEFCAFECAFE;

#40
S_AXI_ARESETn = 1;// no longer reset

S_AXI_AWADDR = 4;//
S_AXI_AWVALID = 1;// sending address

S_AXI_BREADY = 0;//Testing lack of BREADY

S_AXI_WSTRB = 8'b11111111;
S_AXI_WVALID = 1;// sending data
S_AXI_WDATA = 64'hC0FFEEBAD1234567;

#40
S_AXI_ARESETn = 1;// no longer reset

S_AXI_AWADDR = 4;//
S_AXI_AWVALID = 1;// sending address

S_AXI_BREADY = 1;

S_AXI_WSTRB = 8'b11111111;
S_AXI_WVALID = 1;// sending data
S_AXI_WDATA = 64'hC0FFEEBAD1234567;

#40
OF = 1;//reading data into read registers
#40

S_AXI_ARADDR = 1;
S_AXI_ARVALID = 1;// sending address [upper 64 bits]

S_AXI_RREADY = 1;//Testing reading

#40

S_AXI_ARADDR = 2;
S_AXI_ARVALID = 1;// sending address [lower 64 bits]

S_AXI_RREADY = 1;//Testing reading

#40

S_AXI_ARADDR = 100;// Testing R resp
S_AXI_ARVALID = 1;// sending address

S_AXI_RREADY = 1;//Testing reading

#40
//BEGINING MSU TESTS HERE
//Default config
//control signals
S_AXI_ARESETn = 0;// reset
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 0;
S_AXI_BREADY = 0;
S_AXI_WVALID = 0;
S_AXI_AWVALID = 0;
S_AXI_WDATA = 0;
S_AXI_AWADDR = 0;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting KEY1 and KEY2
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b11111111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = 64'hC0FFEEBAD1234567;
S_AXI_AWADDR = 1;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting KEY3 and KEY4
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b11111111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = 64'hBADFEEBAD2233322;
S_AXI_AWADDR = 3;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting KEY5 and KEY6
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b11111111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = 64'hDADDADAD12555521;
S_AXI_AWADDR = 5;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting KEY7 and KEY8
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b11111111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = 64'hFFFFFFFF77777777;
S_AXI_AWADDR = 7;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting IV1 and IV2
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b11111111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = 64'hAAABAAAA11223344;
S_AXI_AWADDR = 9;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting IV3 and IV4
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b11111111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = 64'hCCABACCC17273747;
S_AXI_AWADDR = 11;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting Data1 and Data2
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b11111111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = 64'h4F6E652054776F20;
S_AXI_AWADDR = 13;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting Data3 and Data4
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b11111111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = 64'h2054776F4E696E65;
S_AXI_AWADDR = 15;

//all read signals
S_AXI_RREADY = 0;
S_AXI_ARVALID = 0;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//Inputting control register
//control signals
S_AXI_ARESETn = 1;// reset
OF = 0;//output flag set to zero
RF = 0;//read flag set to zero

//all write signals
S_AXI_WSTRB = 8'b00001111;
S_AXI_BREADY = 1;
S_AXI_WVALID = 1;
S_AXI_AWVALID = 1;
S_AXI_WDATA = {24'b0,1'b1,1'b1,2'b01,3'b010};// ->enable 1 enc_dec 1  Keylen 1 Mode 2
S_AXI_AWADDR = 0;//address for control register

//all read signals
S_AXI_RREADY = 1;
S_AXI_ARVALID = 1;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

// a cycle to represent however many rounds are required
#40

// a cycle to represent however many rounds are required
#40

//Once Key generation is completed
//control signals
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 1;//read flag set to zero

//all write signals
S_AXI_WSTRB = 0;
S_AXI_BREADY = 0;
S_AXI_WVALID = 0;
S_AXI_AWVALID = 0;
S_AXI_WDATA = 0;
S_AXI_AWADDR = 0;

//all read signals
S_AXI_RREADY = 1;
S_AXI_ARVALID = 1;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40

//another cycle required to update status into memory
//control signals
S_AXI_ARESETn = 1;
OF = 0;//output flag set to zero
RF = 1;//read flag set to zero

//all write signals
S_AXI_WSTRB = 0;
S_AXI_BREADY = 0;
S_AXI_WVALID = 0;
S_AXI_AWVALID = 0;
S_AXI_WDATA = 0;
S_AXI_AWADDR = 0;

//all read signals
S_AXI_RREADY = 1;
S_AXI_ARVALID = 1;
S_AXI_ARADDR = 0;

DataOut[127:96] = 0;// output from MSU
DataOut[95:64] = 0;
DataOut[63:32] = 0;
DataOut[31:0] = 0;
#40
#40
#40
#40
#40


$stop;
$finish;
end

endmodule
