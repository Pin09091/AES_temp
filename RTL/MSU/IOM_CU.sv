`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2025 03:09:26 PM
// Design Name: 
// Module Name: IOM_CU
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


module IOM_CU(
input logic [1:0] KeySelect,
input logic [2:0] ModeSelect,
input logic RST, CLK,AES_CF, AES_Valid,
output logic IVSel, Data_WEN , DIn_WEN ,DIn1_WEN ,   In1Reg_WEN, BlockReg_WEN, OutReg_WEN, Counter_WEN, CLR, CK,OF,
output logic [1:0] statebits
    );
    logic [2:0] state, next_state;
    logic AES_CF_neg, AES_Valid_neg;
    logic IVSel_, CK_;
    assign statebits = state[1:0];
    always_ff@(negedge CLK) begin
    AES_CF_neg <= AES_CF;
    AES_Valid_neg <= AES_Valid;
    end
    
    always_ff@(posedge CLK or posedge RST) begin
    if(RST) begin
    state <= 3'b000;
    IVSel_ <= 1'b0;
    CK_ <= 1'b1;
    end else begin
    state <= next_state;
    IVSel_ <= IVSel;
    CK_ <= CK;
    end
    end
    
    always_comb begin
    
    case(state)
    3'b000: begin // Reset State
    OF = 0;
    IVSel = 0;
    Data_WEN = 1;
    DIn_WEN = 1;
    DIn1_WEN = 1;
    In1Reg_WEN = 0;
    BlockReg_WEN = 0;
    OutReg_WEN = 0;
    Counter_WEN = 0;
    CLR = 1;
    CK = 1;
    
    next_state = 3'b001;
    end
    
    3'b001: begin // Load Key,Data,Iv
    OF = 0;
    IVSel = IVSel_;
    Data_WEN = 0;
    DIn_WEN = 1;
    DIn1_WEN = 0;
    Counter_WEN = 0;
    In1Reg_WEN = 0;
    BlockReg_WEN = 0;
    OutReg_WEN = 0;
    CK = CK_;
    CLR = 1;
    next_state = 3'b010;
    end
    
    3'b010: begin // AES Stall/Input takein
    OF = 0;
    IVSel = IVSel_;
    Data_WEN = 0;
    DIn_WEN = 1;
    DIn1_WEN = 0;
    Counter_WEN = 0;
    In1Reg_WEN = 0;
    BlockReg_WEN = 0;
    OutReg_WEN = 0;
    CK = 0;
    CLR = 0;
        if(AES_CF_neg) begin
        next_state = 3'b011;
        end else begin
        next_state = 3'b010;
        end
        end
    
    3'b011: begin // AES Operation
    OF = 0;
    IVSel = IVSel_;
    Data_WEN = 0;
    DIn_WEN = 0;
    DIn1_WEN = 0;
    Counter_WEN = 0;
    In1Reg_WEN = 0;
    OutReg_WEN = 0;
    CK = CK_;
    CLR = 0;
    if(AES_Valid_neg) begin
    BlockReg_WEN = 1;
    next_state = 3'b100;
    end else begin
    BlockReg_WEN = 0;
    next_state = 3'b011;
    end
    end
    
    3'b100: begin // Output Computation
    OF = 0;
    Data_WEN = 0;
    DIn_WEN = 0;
    DIn1_WEN = 0;
    CK = CK_;
    CLR = 1;
    BlockReg_WEN = 0;
    OutReg_WEN = 1;
    Counter_WEN = 1;
    In1Reg_WEN = 1;
    IVSel = IVSel_;
    next_state = 3'b101;
    end
    
    3'b101: begin // Output Send to Bus
    OF = 1;
    IVSel = 1;
    CLR = 1;
    CK = CK_;
    Counter_WEN = 0;
    In1Reg_WEN = 0;
    BlockReg_WEN = 0;
    OutReg_WEN = 0;
    DIn_WEN = 1;
    DIn1_WEN = 1;
    Data_WEN = 0;
    next_state = 3'b001;
    end
    
    default: begin
    next_state = 3'b000;
    OF = 0;
    IVSel = 0;
    Data_WEN = 0;
    DIn_WEN = 0;
    DIn1_WEN = 0;
    In1Reg_WEN = 0;
    BlockReg_WEN = 0;
    OutReg_WEN = 0;
    Counter_WEN = 0;
    CLR = 1;
    CK = 1;
    end
    endcase
    end
endmodule
