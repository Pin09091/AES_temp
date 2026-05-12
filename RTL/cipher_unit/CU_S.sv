// =============================================================================
// Module: CU_S (Control Unit - Sequential)
// Description:
//   Finite-state machine (FSM) that orchestrates the AES cipher datapath.
//   It controls all muxes, enables, and clears required for both encryption
//   and decryption across AES-128, AES-192, and AES-256 key lengths.
//
//   The FSM has nine named states:
//     0 - RESET  : Initialise all control signals; wait for key-expansion done (KF).
//     1 - STALL  : Drain remaining key-expansion rounds before accepting new data.
//     2 - INPUT  : Accept a plaintext/ciphertext block from the outside; assert CF.
//     3 - E0     : Encryption round 0 - initial AddRoundKey only.
//     4 - EX     : Encryption rounds 1..(Rt-1) - full BS?RS?MC?ARK pipeline.
//     5 - EN     : Encryption final round - BS?RS?ARK (no MixColumns).
//     6 - D0     : Decryption round 0 - initial ARK only (equivalent to EN inverse).
//     7 - DX     : Decryption rounds 1..(Rt-1) - full IBS?IRS?IMC?ARK pipeline.
//     8 - DN     : Decryption final round - IBS?IRS?ARK (no InvMixColumns).
//
//   Round counter (R_reg):
//     Counts from 0 up to Rt (total rounds determined by key length).
//     For encryption, R is used directly as the round-key index.
//     For decryption, R is inverted (Rt - R_reg) so the correct round key
//     is fetched in reverse order from KEXP.
//
//   Key-length encoding (KL):
//     KL = 2'b00 ? AES-128 (10 rounds, Rt = 10)
//     KL = 2'b01 ? AES-192 (12 rounds, Rt = 12)
//     KL = 2'b10 ? AES-256 (14 rounds, Rt = 14)
//
//   Mux control signals (active-high unless noted):
//     mux0 - State register data source: 1=external input, 0=ARK output (or BS for decrypt)
//     mux1 - BS input source:            1=state register, 0=RS output (decryption feedback)
//     mux2 - RS input source (2-bit):    0=ARK out, 1=BS out, 2=MC out
//     mux3 - MC input source:            1=RS output, 0=ARK output
//     mux4 - ARK input source:           1=state register, 0=datapath (RS or MC depending on mux6)
//     mux5 - State register write source:1=ARK output (enc), 0=BS output (dec)
//     mux6 - ARK encrypt sub-select:     1=RS output (final enc round), 0=MC output (normal enc)
//
//   Other outputs:
//     SE    - State register clock enable (write enable)
//     SCLR  - State register synchronous clear
//     Valid - Asserted for one cycle when a valid ciphertext/plaintext is at the output
//     CF    - Cipher-ready Flag: asserted when the unit is ready to accept a new data block
//     R     - Current round number forwarded to KEXP for round-key selection
//
// Inputs:
//   CLK     - System clock
//   CLR     - Synchronous reset (active-high)
//   enc_dec - 1 = encryption, 0 = decryption
//   KL[1:0] - Key length select (see encoding above)
//   KF      - Key-expansion finished flag from KEXP
//
// Dependencies: None
// =============================================================================


module CU_S(
input CLK,
input CLR,
input enc_dec,
input [1:0]KL,
input KF,
output logic mux0,
output logic mux1,
output logic [1:0]mux2,
output logic mux3,
output logic mux4,
output logic mux5,
output logic mux6,
output logic SE,
output logic SCLR,
output logic Valid,
output logic CF,
output logic [3:0]R
    );

logic [3:0]STATE;
logic [3:0]NXT_STATE;
logic [3:0]PREV_STATE;


//Round counter --- variables
reg [3:0]R_reg;
wire [3:0]Rt;
logic cond1;//to check if R = Rt
logic cond2;//to check if R = 0
logic cond3;//to choose R
logic cond4;//to check if R = Rt - 1
logic cond5;//to reset R_reg based off of state

//Round counter --- body
assign Rt = KL[1]?(14):(KL[0]?(12):(10));// to choose rt 0 (4) = 10 ; 1 (6) = 12 ; 2 (8) = 14

always_comb
begin
    if(R_reg == Rt)
        begin
            cond1 = 1;
        end
    else
        begin
            cond1 = 0; 
        end
     //to change state input
     if(R_reg == 0)
        begin
            cond2 = 1;
        end
     else
        begin
            cond2 = 0;      
        end
        
    if(R_reg == (Rt-1))
            begin
                cond4 = 1;
            end
        else
            begin
                cond4 = 0; 
            end   

    case(STATE)// STATE MACHINE
        0://RESET
            begin
                NXT_STATE = KF?2:1;// INPUT IF KF is HIGH OR STALL IF KF is LOW
                
                cond5 = 0;//resetinng R to zero
                cond3 = 1;  //R
                Valid = 0;
                CF = 0;
                SCLR = 1;   //state RESET
                SE = 0;     //state DISABLED                
                mux0 = 0;   // MUX VALUES UPDATED TO PREVENT A FEEDBACK LOOP
                mux1 = 1;   
                mux2 = 1;   
                mux3 = 1;   
                mux4 = 0;    
                mux5 = 1;   
                mux6 = 0;                                
            end
        1://STALL
            begin
                NXT_STATE = cond1?0:1;//stays in STALL till R = Rt then goes to reset
                    
                cond5 = 1;// allowing R to be updated
                cond3 = 1;  //R
                Valid = 0;
                CF = 0;
                SCLR = 1;   //state RESET
                SE = 0;     //state DISABLED                
                mux0 = 0; //state
                mux1 = 1;    //changed from zero
                mux2 = 1;   //changed from zero
                mux3 = 1;    //changed from zero, used to take in state 4
                mux4 = 0;   //takes in state 3
                mux5 = 1; //Also state   (changed from zero)
                mux6 = 0;                    
            end
        2://INPUT
            begin
                NXT_STATE = KF?(enc_dec?3:6):0;// 1 -> encryption  0 -> decryption, if KF is 0 then it resets again                                
                
                if((PREV_STATE == 0))// If the previous state was EN or DN then the output is valid, otherwise it was not valid
                    Valid = 0;
                else
                    Valid = KL[1]?(KL[0]?0:1):1;// when KL = 3 Valid will ALWAYS be zero
                cond5 = 0;// pausing R
                
                if((PREV_STATE == 5))// If the previous state was EN or DN then the output is valid, otherwise it was not valid
                    cond3 = 1;
                else
                    cond3 = 0;              
                
                
                CF = 1;     //Ready to take input
                SCLR = 0;   //state not RESET
                SE = 1;     //state enabled                
                mux0 = 1;   // 1 means that state takes input from the outside
                mux1 = 0;   //BS
                mux2 = 0;   //RS
                mux3 = 0;   //MC
                mux4 = 1;   //ARK
                mux5 = 1;   // can be either 1 or zero, we dont care
                mux6 = 0;   //Swapping between EN/EX and DN/DX                             
                 
            end
        3://E0
            begin
                NXT_STATE = 4;// the next state HAS to be EX
                    
                cond3 = 1;  //R
                cond5 = 1;// allowing R to be updated
                
                Valid = 0;
                CF = 0;
                SCLR = 0;   //state not RESET
                SE = 1;     //state enabled                
                mux0 = 0;   // 1 means that state takes input from the outside
                mux1 = 0;
                mux2 = 0;
                mux3 = 0;
                mux4 = 1;
                mux5 = 1;   // needs to be 1 for ARK input into state
                mux6 = 0;   //No outside inputs                                         
            end
        4://EX
            begin
                NXT_STATE = cond4?5:4;// Stay in this state till R = Rt - 1  
                cond3 = 1;  //R
                cond5 = 1;
                Valid = 0;    
                CF = 0;    
                SCLR = 0;   //state not RESET
                SE = 1;     //state enabled                
                mux0 = 0;   // 1 means that state takes input from the outside
                mux1 = 1;   //state into BS
                mux2 = 1;   //BS into RS
                mux3 = 1;   //RS into MC
                mux4 = 0;   //MC into ARK 
                mux5 = 1;   // needs to be 1 for ARK input into state
                mux6 = 0;   //MC into ARK                             
            end 
        5://EN
            begin
                    NXT_STATE = 2;//into INPUT
                    cond3 = 1;  //R
                    cond5 = 1;
                    Valid = 0;
                    CF = 0;     //input to be taken in the next cycle    
                    SCLR = 0;   //state not RESET
                    SE = 1;     //state enabled                
                    mux0 = 0;   // 1 means that state takes input from the outside
                    mux1 = 1;   //state into BS
                    mux2 = 1;   //BS into RS
                    mux3 = 1;   //dont care since its not being used
                    mux4 = 0;   //RS into ARK 
                    mux5 = 1;   // needs to be 1 for ARK input into state
                    mux6 = 1;   //RS into ARK                                    
            end
        6://D0 
            begin
                    NXT_STATE = 7;//into DX

                    cond5 = 1;// allowing R to be updated
                    cond3 = 0;  //R
                    
                    Valid = 0;
                    CF = 0;       
                    SCLR = 0;   //state not RESET
                    SE = 1;     //state enabled                
                    mux0 = 0;   // 1 means that state takes input from the outside
                    mux1 = 0;   //RS into BS
                    mux2 = 0;   //ARK into RS
                    mux3 = 0;   //dont care since MC is being skipped
                    mux4 = 1;   //state into ARK 
                    mux5 = 0;   // BS into state
                    mux6 = 0;   // no user input                                      
            end
        7://DX
            begin
                    NXT_STATE = cond4?8:7;// Stay in this state till R = Rt - 1
                    cond3 = 0;  //R
                    cond5 = 1;
                    CF = 0;        
                    SCLR = 0;   //state not RESET
                    Valid = 0;
                    SE = 1;     //state enabled                
                    mux0 = 0;   // 1 means that state takes input from the outside
                    mux1 = 0;   //RS into BS
                    mux2 = 2;   //MC into RS
                    mux3 = 0;   //ARK into MC
                    mux4 = 1;   //state into ARK 
                    mux5 = 0;   // BS into state
                    mux6 = 0;   // no user input                        
            end
        8://DN
            begin

                    NXT_STATE = 2;//into INPUT
                    Valid = 0;
                    cond3 = 0;  //R
                    cond5 = 1;
                    
                    CF = 0;         
                    SCLR = 0;   //state not RESET
                    SE = 1;     //state enabled                
                    mux0 = 0;   //1 means that state takes input from the outside
                    mux1 = 0;   //We dont care
                    mux2 = 2;   //We dont care
                    mux3 = 0;   //We dont care
                    mux4 = 1;   //state into ARK 
                    mux5 = 1;   //ARK into state
                    mux6 = 0;   //no user input                              
            end  
         default:// Adding default values to prevent issues in XCELIIUM 
            begin
                 NXT_STATE = 0;
                 cond5 = 0;
                 cond3 = 0;  //R
                 SCLR = 0;   //state not RESET
                 SE = 0;
                 CF = 0;
                 Valid = 0;
                 mux0 = 0;   // 1 means that state takes input from the outside
                 mux1 = 0;   //BS
                 mux2 = 0;   //RS
                 mux3 = 0;   //MC
                 mux4 = 0;   //ARK
                 mux5 = 1;   // can be either 1 or zero, we dont care
                 mux6 = 0;   //Swapping between EN/EX and DN/DX                             
                                                          
            end                                                                                                                                          
    endcase

end


always_ff@(posedge CLK)
begin
    //for round incrementing
    if(R_reg == Rt)
        begin
            R_reg <= 0;
        end
    else
        begin
            R_reg <= cond5?(R_reg + 1):(0);    
        end


    if(CLR)
        begin
            STATE <= 0;
        end
    else
        begin
            PREV_STATE <= STATE;
            STATE <= NXT_STATE;// into next state
        end            
end


assign R = cond3?(R_reg):(Rt - R_reg);// to swap between round counts for round key

endmodule