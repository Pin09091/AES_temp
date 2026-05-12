// =============================================================================
// Module: cipher_unit (AES Encryption/Decryption Core)
// Description:
//   Top-level AES cipher unit integrating all datapath and control submodules.
//   Supports AES-128, AES-192, and AES-256 for both encryption and decryption
//   using a single iterative datapath (one physical copy of each AES step,
//   reused across all rounds).
//
//   Datapath pipeline (per round):
//     State Register ? BS (ByteSub) ? RS (RowShift) ? MC (MixColumn) ? ARK (AddRoundKey) ? State Register
//   Final round skips MC:
//     State Register ? BS ? RS ? ARK ? State Register
//   Decryption uses the inverse of each step and applies them in reverse order.
//   Refer to FYP documentation (i provided a drive link) for more details
//
//   Key expansion (KEXP) runs concurrently and signals completion via KF.
//   The control unit (CU_S) orchestrates all mux/enable signals.
//
//   Key-length change detection:
//     If KL changes while a cipher operation is in progress (should never
//     happen in normal use), both CLR_S and CLR_H are asserted to immediately
//     reset the cipher and key-expansion units, preventing corrupt state.
//
// Interface:
//   CLK     - System clock
//   CLR     - Active-high synchronous reset for cipher control unit
//   CK      - Clock-enable / reset input for KEXP (from MSU control unit)
//   KEY     - 256-bit key input as 8 x 32-bit words; KEY[0..3] = lower 128 bits,
//             KEY[4..7] = upper 128 bits (used only for AES-192/256)
//   KL      - Key length: 2'b00=AES-128, 2'b01=AES-192, 2'b10=AES-256
//   enc_dec - 1=encrypt, 0=decrypt
//   state_i - 128-bit plaintext/ciphertext input as 4 x 32-bit words
//   state_o - 128-bit ciphertext/plaintext output as 4 x 32-bit words
//   Valid   - Asserted for one cycle when state_o holds a valid result
//   CF      - Cipher-ready Flag: asserted when ready to accept a new state_i block
//
// Dependencies: CU_S, KEXP, State, BS, RS, MC, ARK
// =============================================================================

module cipher_unit(
input CLK,
input CLR,
input CK,
input [31:0] KEY [7:0],
input [1:0] KL, 
input enc_dec,
input logic [31:0]state_i[3:0],
output logic [31:0]state_o[3:0],
output logic Valid,
output logic CF
);
    

//declaring varibales
logic [31:0]Rk[3:0];
logic [3:0]R;            
logic SCLR;
logic SE;
logic KF;

logic mux0;
logic mux1;
logic [1:0]mux2;
logic mux3;
logic mux4;
logic mux5;
logic mux6;



logic [31:0]state_i0[3:0];//    for state
logic [31:0]state_o0[3:0];

logic [31:0]state_i1[3:0];//    for BS
logic [31:0]state_o1[3:0];

logic [31:0]state_i2[3:0];//    for RS 
logic [31:0]state_o2[3:0];

logic [31:0]state_i3[3:0];//    for MC
logic [31:0]state_o3[3:0];

logic [31:0]state_i4[3:0];//    for ARK
logic [31:0]state_o4[3:0];


//To handle key length changing in between messages
logic [1:0]PREV_KL;//if KL changes in between somehow(it should NEVER change once encryption starts) ill use this to reset
logic CLR_S;
logic CLR_H;


always_ff@(negedge CLK)// KL and prev_kl need to be desynced by some ammount, half a cycle should suffice
begin
    PREV_KL <= KL;  
end

always_comb
begin
    if(KL != PREV_KL)
        begin
           CLR_S = 1;
           CLR_H = 1;  
        end
    else
        begin
           CLR_S = CLR;
           CLR_H = CK;  
        end
end


CU_S s(
.CLK(CLK),
.CLR(CLR_S),
.enc_dec(enc_dec),
.KL(KL),
.KF(KF),
.mux0(mux0),
.mux1(mux1),
.mux2(mux2),
.mux3(mux3),
.mux4(mux4),
.mux5(mux5),
.mux6(mux6),
.SE(SE),
.SCLR(SCLR),
.Valid(Valid),
.CF(CF),
.R(R)
);//            CONTROL UNIT




KEXP kexp(
.CLK(CLK),
.R(R),
.KL(KL),
.KEY(KEY),
.Rk(Rk),
.CLR(CLR_H),
.KF(KF)
);//            KEY EXPANSION


State Si(
.CLK(CLK),
.enable(SE),
.CLR(SCLR),
.state_i(state_i0),
.state_o(state_o0)
);  


assign state_o = state_o0;

BS Bs(
.state_i(state_i1),   
.enc_dec(enc_dec),
.state_o(state_o1)
);//            BYTE SUB ARRAY


RS Rs(
.state_i(state_i2),
.enc_dec(enc_dec),
.state_o(state_o2)
);//            ROW SHIFT


MC Mc(
.state_i(state_i3),   
.enc_dec(enc_dec),
.state_o(state_o3)
);//            MIXED COLUMN ARRAY


ARK Ark(
.state_i(state_i4),
.Rk(Rk),
.state_o(state_o4)
);//            ADD ROUND KEY



always_comb
begin
    state_i1 = mux1?(state_o0):(state_o2);//        into BS 

    
    state_i2 = mux2[1]?(state_o3):(mux2[0]?(state_o1):(state_o4));//into RS
    
    
    state_i3 = mux3?(state_o2):(state_o4);//        into MC


    case(mux4)//                                    into ARK
        0:
            begin
                state_i4 = mux6?state_o2:state_o3;//EN
            end
        1:
            begin
                state_i4 = state_o0;//E0
            end  
    endcase


    case(mux5)//                               into state
        0:
            begin
                state_i0 = mux0?state_i:state_o1;//decryption
            end
        1:
            begin
                state_i0 = mux0?state_i:state_o4;//encryption
            end        
    endcase


end

    
endmodule