`timescale 1ns / 1ps
// =============================================================================
// Module: AXI_main
// =============================================================================
// Description:
//   AXI4-Lite slave interface that bridges an AXI master (e.g. a processor)
//   to the AES Mode Selection Unit (MSU).
//
//   The master writes configuration and input data into an internal register
//   file (Mem_in[0..16]), and reads back status and ciphertext/plaintext
//   results from a second register file (Mem_out[0..4]).
//
// AXI Bus Parameters:
//   - Data width : 64 bits  (two 32-bit words written per transaction)
//   - Address    : 64 bits  (only lower 16 bits are used as word index)
//   - Reset      : Active-LOW  (S_AXI_ARESETn)
//   - Clock edge : Write FSMs sample on posedge; Mem_in updates on negedge
//
// Register Map (Mem_in, word-addressed via AW address):
//   Addr 0x0000  : control register
//                    [2:0] ModeSelect  - 0=ECB, 1=CBC, 2=CFB, 3=OFB, 4=CTR
//                    [4:3] KeySelect   - 00=AES-128, 01=AES-192, 10=AES-256
//                                        11=INVALID
//                    [5]   enc_dec     - 0=Decrypt, 1=Encrypt
//                    [6]   Enable      - 1 = start MSU
//   Addr 0x0001-0x0004  : KeyIn2  (128-bit key, lower word first)
//   Addr 0x0005-0x0008  : KeyIn1  (128-bit key, lower word first)
//   Addr 0x0009-0x000C  : IVIn    (128-bit IV, for CBC/CFB/OFB/CTR)
//   Addr 0x000D-0x0010  : DataIn  (128-bit plaintext or ciphertext input)
//
// Output Register Map (Mem_out, read-addressed via AR address):
//   AR addr 0 ? Mem_out[0]       : {28'b0, Status[3:0]}
//   AR addr 1 ? {Mem_out[1], Mem_out[2]} : DataOut[63:0]
//   AR addr 2 ? {Mem_out[3], Mem_out[4]} : DataOut[127:64]
//
// Status FSM encoding (6 states):
//   0 = IDLE           - waiting for Enable bit; MSU is held in reset
//   1 = INVALID        - control signals are illegal (bad KeySelect/ModeSelect)
//   2 = INPUT_PENDING  - MSU running, master may still write new data
//   3 = OUTPUT_PENDING - MSU output ready; master is reading result
//   4 = TIMED_OUT      - transaction watchdog fired; all memory cleared
//   5 = CORE_BUSY      - AES core is actively processing (OF/RF not yet set)
//
// Write Flow (AXI W-channel handshake):
//   1. Master drives AWVALID + AWADDR, WVALID + WDATA + WSTRB.
//   2. AW and W state machines each move to READY once BREADY is asserted.
//   3. B (response) FSM asserts BVALID when both AWVALID & WVALID seen.
//   4. Memory (Mem_in) is updated on negedge when cond & W_flag are both 1.
//   5. Each 64-bit write touches two consecutive 32-bit Mem_in words:
//        - Lower 32 bits ? Mem_in[ AWADDR[15:0]     ]
//        - Upper 32 bits ? Mem_in[ AWADDR[15:0] + 1 ]
//      WSTRB byte-enables guard individual bytes within each 32-bit word.
//
// Read Flow (AXI R-channel handshake):
//   1. Master drives ARVALID + ARADDR; RREADY must be asserted.
//   2. AR FSM asserts ARREADY once RREADY is seen, latching AR_flag.
//   3. R FSM asserts RVALID; RRESP=SLVERR (2) if ARADDR > 2.
//   4. RDATA is loaded from Mem_out on posedge when AR_flag is set.
//
// Dependencies: None
// =============================================================================

module AXI_main(

input logic S_AXI_ACLK,// MSU AXI inputs
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


output logic [127:0]DataIn,// MSU inputs
output logic [127:0]KeyIn1,
output logic [127:0]KeyIn2,
output logic [127:0]IVIn,
output logic [2:0]ModeSelect,
output logic [1:0] KeySelect,
output logic Enable_MSU,
output logic RST_MSU,
output logic enc_dec,
input  logic OF,
input  logic RF,
input  logic [127:0] DataOut
    );

//WRITING DATA=====================================================================================================================
logic AW_State;
logic AW_State_Next;
logic [31:0]AW_Reg;//we dont need the entire 64 bits
logic AW_flag;// to check if we have an address available


logic W_State;
logic W_State_Next;
logic [31:0]W_Reg[1:0];//Just to make it easier to work with W, no effect on hardware
logic W_flag;
assign W_Reg[0] = S_AXI_WDATA[31:0];
assign W_Reg[1] = S_AXI_WDATA[63:32];
logic [7:0]STRB_store;//to make sure that when memory updates we use the actualaddress


logic [31:0]Mem_in[16:0];//memory for inputs
logic [31:0]Mem_out[4:0];//memory for outputs

logic [3:0]Status;//To control the status register
logic [3:0]Status_Prev;
logic [3:0]Status_Next;

logic B_State;
logic B_State_Next;
logic cond;

logic Enable_MSU_internal;

assign    ModeSelect = {Mem_in[0][2:0]};
assign    KeySelect = {Mem_in[0][4:3]};
assign    enc_dec = {Mem_in[0][5]};
assign    Enable_MSU_internal = {Mem_in[0][6]};

assign    DataIn = {Mem_in[13],Mem_in[14],Mem_in[15],Mem_in[16]};
assign    KeyIn1 = {Mem_in[5],Mem_in[6],Mem_in[7],Mem_in[8]};//swapped key2/1
assign    KeyIn2 = {Mem_in[1],Mem_in[2],Mem_in[3],Mem_in[4]};
assign    IVIn = {Mem_in[9],Mem_in[10],Mem_in[11],Mem_in[12]};


always_ff@(negedge S_AXI_ACLK)//updating input memory
begin

    if(Status === 4)// if input times out, then reset
    begin
        Mem_in[0] = 0;// all theresets, theres probably a better way to do this
        Mem_in[1] = 0;
        Mem_in[2] = 0;
        Mem_in[3] = 0;
        Mem_in[4] = 0;
        Mem_in[5] = 0;
        Mem_in[6] = 0;
        Mem_in[7] = 0;
        Mem_in[8] = 0;
        Mem_in[9] = 0;
        Mem_in[10] = 0;
        Mem_in[11] = 0;
        Mem_in[12] = 0;
        Mem_in[13] = 0;
        Mem_in[14] = 0;
        Mem_in[15] = 0;
        Mem_in[16] = 0;
    end
    else
    begin    
        case(cond & W_flag)
        0://No ready/valid asserted, we can not write 
        begin
            Mem_in <= Mem_in; // leaving this empty would have the same result   //---------------UNCOMMENTED THIS
        end
        1://Ready and valid is asserted we can write (only updates memory when BRESP is valid and valid are asserted)
        begin
            //lower 32
            Mem_in[AW_Reg[15:0]][7:0] <= STRB_store[0]?W_Reg[0][7:0]:Mem_in[AW_Reg[15:0]][7:0];// First STRB bit check   //<------------CHANGED THESE FROM 16 to 15
            Mem_in[AW_Reg[15:0]][15:8] <= STRB_store[1]?W_Reg[0][15:8]:Mem_in[AW_Reg[15:0]][15:8];// Second STRB bit check
            Mem_in[AW_Reg[15:0]][23:16] <= STRB_store[2]?W_Reg[0][23:16]:Mem_in[AW_Reg[15:0]][23:16];// Third STRB bit check
            Mem_in[AW_Reg[15:0]][31:24] <= STRB_store[3]?W_Reg[0][31:24]:Mem_in[AW_Reg[15:0]][31:24];// Fourth STRB bit check
        
     
            //UPPER 32
            Mem_in[AW_Reg[31:16]][7:0] <= STRB_store[4]?W_Reg[1][7:0]:Mem_in[AW_Reg[31:16]][7:0];// First STRB bit check
            Mem_in[AW_Reg[31:16]][15:8] <= STRB_store[5]?W_Reg[1][15:8]:Mem_in[AW_Reg[31:16]][15:8];// Second STRB bit check
            Mem_in[AW_Reg[31:16]][23:16] <= STRB_store[6]?W_Reg[1][23:16]:Mem_in[AW_Reg[31:16]][23:16];// Third STRB bit check
            Mem_in[AW_Reg[31:16]][31:24] <= STRB_store[7]?W_Reg[1][31:24]:Mem_in[AW_Reg[31:16]][31:24];// Fourth STRB bit check
        end
        endcase
        
        Mem_in[0] = S_AXI_ARESETn?Mem_in[0]:0;// all theresets, theres probably a better way to do this
        Mem_in[1] = S_AXI_ARESETn?Mem_in[1]:0;
        Mem_in[2] = S_AXI_ARESETn?Mem_in[2]:0;
        Mem_in[3] = S_AXI_ARESETn?Mem_in[3]:0;
        Mem_in[4] = S_AXI_ARESETn?Mem_in[4]:0;
        Mem_in[5] = S_AXI_ARESETn?Mem_in[5]:0;
        Mem_in[6] = S_AXI_ARESETn?Mem_in[6]:0;
        Mem_in[7] = S_AXI_ARESETn?Mem_in[7]:0;
        Mem_in[8] = S_AXI_ARESETn?Mem_in[8]:0;
        Mem_in[9] = S_AXI_ARESETn?Mem_in[9]:0;
        Mem_in[10] = S_AXI_ARESETn?Mem_in[10]:0;
        Mem_in[11] = S_AXI_ARESETn?Mem_in[11]:0;
        Mem_in[12] = S_AXI_ARESETn?Mem_in[12]:0;
        Mem_in[13] = S_AXI_ARESETn?Mem_in[13]:0;
        Mem_in[14] = S_AXI_ARESETn?Mem_in[14]:0;
        Mem_in[15] = S_AXI_ARESETn?Mem_in[15]:0;
        Mem_in[16] = S_AXI_ARESETn?Mem_in[16]:0;
    end    
end

always_ff@(posedge S_AXI_ACLK)//updating State (for Reads) and MSU
begin
    STRB_store <= S_AXI_WSTRB;// <-------------------------------------- to make sure that strb doesnt change mid transaction
    AW_State <= S_AXI_ARESETn?AW_State_Next:0;//Reset is active-low
    W_State <= S_AXI_ARESETn?W_State_Next:0;//Reset is active-low
    B_State <= S_AXI_ARESETn?B_State_Next:0;
end

always_comb//State machines for Write Address
begin
    case(AW_State)//Write Address
    0://NOT READY
        begin
            S_AXI_AWREADY = 0;
            AW_Reg = 0 ; 
            AW_State_Next = (S_AXI_BREADY)?1:0;// For a succsesful burst BRESP must be ready, and both address and write need to have valid signals
        end
    1://READY
        begin 
            S_AXI_AWREADY = 1;
            AW_Reg[15:0] = (S_AXI_AWVALID)?S_AXI_AWADDR[15:0]:0;
            AW_Reg[31:16] =(S_AXI_AWVALID)?(S_AXI_AWADDR[15:0] + 1):0; 
            
            AW_State_Next = (S_AXI_BREADY)?1:0;
        end
     default: 
         begin
              S_AXI_AWREADY = 0;
              AW_Reg = 0 ; 
              AW_State_Next = 0;// sending it back to not valid
              
         end
    endcase
end

always_comb//State machines for Write data
begin
    case(W_State)//Write data
    0://NOT READY
        begin
            S_AXI_WREADY = 0;
            W_flag = 0;            
            W_State_Next = (S_AXI_BREADY)?1:0;// For a succsesful burst BRESP must be ready, and both address and write need to have valid signals
        end
    1://READY
        begin
            S_AXI_WREADY = 1;
            W_flag = 1;
            W_State_Next = (S_AXI_BREADY)?1:0;
        end
     default: 
        begin
            S_AXI_WREADY = 0;
            W_flag = 0;            
            W_State_Next = 0;// For a succsesful burst BRESP must be ready, and both address and write need to have valid signals
        end        
    endcase
end

always_comb//State machines for BRESP
begin    
    case(B_State)//BRESP
    0://NOT VALID
        begin
            S_AXI_BVALID = 0;
            cond = 0;
            S_AXI_BRESP = 0;//not ready, no error
            B_State_Next = ((S_AXI_AWVALID & S_AXI_WVALID))?1:0;
        end
    1://VALID
        begin
            S_AXI_BVALID = 1;
            cond = (S_AXI_AWADDR > 16)?0:1;
            S_AXI_BRESP = (S_AXI_AWADDR > 16)?2:0;  //ERROR THROWN HERE WEHENEVER AW AND W ARE NOT READY
            B_State_Next = ((S_AXI_AWVALID & S_AXI_WVALID))?1:0;
        end
     default:
        begin
         S_AXI_BVALID = 0;
         cond = 0;
         S_AXI_BRESP = 0;
         B_State_Next = 0;
        end             
    endcase      
end    


//READING DATA=====================================================================================================================
logic AR_State;
logic AR_State_Next;
logic AR_flag;

logic R_State;
logic R_State_Next;

always_ff@(posedge S_AXI_ACLK)//updating State (For writes)
begin
    AR_State <= S_AXI_ARESETn?AR_State_Next:0;//Reset is active-low
    R_State <= S_AXI_ARESETn?R_State_Next:0;//Reset is active-low
end

always_ff@(negedge S_AXI_ACLK)//updating output memory 
begin
    if(Status === 4)// if input times out, then reset
    begin
        Mem_out[0] = {{28{1'b0}},Status};// Status register
        Mem_out[1] = 0;
        Mem_out[2] = 0;
        Mem_out[3] = 0;
        Mem_out[4] = 0;
    end
    else
    begin
        Mem_out[0] = {{29{1'b0}},Status};// Status register
    
        Mem_out[1] = OF?{DataOut[31:0]}:Mem_out[1];  //Data 1
        Mem_out[2] = OF?{DataOut[63:32]}:Mem_out[2]; //Data 2
        Mem_out[3] = OF?{DataOut[95:64]}:Mem_out[3]; //Data 3
        Mem_out[4] = OF?{DataOut[127:96]}:Mem_out[4];//Data 4
    
        Mem_out[0] = S_AXI_ARESETn?Mem_out[0]:0;// all the resets, theres probably a better way to do this
        Mem_out[1] = S_AXI_ARESETn?Mem_out[1]:0;
        Mem_out[2] = S_AXI_ARESETn?Mem_out[2]:0;
        Mem_out[3] = S_AXI_ARESETn?Mem_out[3]:0;
        Mem_out[4] = S_AXI_ARESETn?Mem_out[4]:0;
    end       
end

always_ff@(posedge S_AXI_ACLK)//Reading output memory
begin
    if((S_AXI_ARADDR == 0) && AR_flag)
    begin
        S_AXI_RDATA = {32'h00000000,Mem_out[0]};
    end    
    if((S_AXI_ARADDR == 1) && AR_flag)
    begin
        S_AXI_RDATA = {Mem_out[1],Mem_out[2]};
    end    
    if((S_AXI_ARADDR == 2) && AR_flag)
    begin
        S_AXI_RDATA = {Mem_out[3],Mem_out[4]};
    end
    if((S_AXI_RRESP[1]) && AR_flag)// to make sure that i cant output a value if RESP = 2
    begin
        S_AXI_RDATA = {32'h00000000,32'h00000000};
    end
end    


always_comb//State machines for Read Address
begin
    case(AR_State)//Read Address
    0://NOT READY
        begin
            S_AXI_ARREADY = 0;
            AR_flag = 0;        
            AR_State_Next = (S_AXI_RREADY)?1:0;// can only do a full transaction if the master is ready in the same cycle
        end
    1://READY
        begin
            S_AXI_ARREADY = 1;
            AR_flag = S_AXI_ARVALID?1:0;//to allow address use
            AR_State_Next = (S_AXI_RREADY)?1:0;
        end
     default:
            begin
                S_AXI_ARREADY = 0;
                AR_flag = 0;//to allow address use
                AR_State_Next = 0;
            end        
    endcase
end

always_comb//State machines for Read Data
begin    
    case(R_State)//Read Data
    0://NOT VALID
        begin
            S_AXI_RVALID = 0;
            S_AXI_RRESP = 0;//not valid so no error
            R_State_Next = (S_AXI_ARREADY)?1:0;
        end
    1://VALID
        begin
            S_AXI_RVALID = 1;
            S_AXI_RRESP = (S_AXI_ARADDR > 2)?2:0;
            R_State_Next = (S_AXI_ARREADY)?1:0;
        end
        
     default:  
            begin
                S_AXI_RVALID = 0;   
                S_AXI_RRESP = 0;
                R_State_Next = 0;
            end
    endcase      
end    


//CONTROL FOR STATUS

logic invalid_cond;
logic CNTRF;//for read counter logic
logic CNTRCNTRL;// for read counter control
logic [2:0]cntr;//read counter

logic CNTRF_write;//for write counter logic
logic CNTRCNTRL_write;// for write counter control
logic [3:0]cntr_write;//write counter

logic CNTRF_over;//for if output pending takes too long
logic [3:0]cntr_over;//write counter
    
always@(posedge S_AXI_ACLK)// updating state machine for status
begin
    Status_Prev <=  S_AXI_ARESETn?Status:0;//<-----------------------Changed this IS NEW NEW NEW
    Status <=  S_AXI_ARESETn?Status_Next:0;//updating state
end

always@(negedge S_AXI_ACLK)// updating counter
begin
    cntr <= S_AXI_ARESETn?(CNTRCNTRL?(cntr+1):0):0;//to update read counter
    cntr_write <= S_AXI_ARESETn?(CNTRCNTRL_write?(cntr_write+1):0):0;//to update write counter
    cntr_over <= S_AXI_ARESETn?(CNTRCNTRL_write?(cntr+1):0):0;//to keep an eye on output coubter
end
 /*
 //     just a reminder of what each variable is
 ModeSelect = {Mem_in[0][2:0]};
 KeySelect = {Mem_in[0][4:3]};
 enc_dec = {Mem_in[0][5]};
 Enable_MSU = {Mem_in[0][6]};
 */

always_comb// FSM for status
begin
    CNTRF = (cntr == 3);//if 3 reads are done its high
    CNTRF_write = (cntr_write >= 2);//if at least 2 writes are done its high
    CNTRF_over = (cntr_write > 5);//too many cycles wasted on reading output
    invalid_cond = (KeySelect == 3) || (ModeSelect > 4);//if this is high then control signals are invalid 
    
    case(Status)
    0://idle - no enable
            begin
                RST_MSU = 1;//resetting the MSU
                Enable_MSU = 0;// MSU not enabled
                CNTRCNTRL = 0;
                CNTRCNTRL_write = 0;
                Status_Next = Enable_MSU_internal?(invalid_cond?1:5):0;//stays idle till enabled
            end
    1://invalid control signal
            begin
                RST_MSU = 1;//resetting the MSU
                Enable_MSU = 0;// MSU not enabled
                CNTRCNTRL = 0;
                CNTRCNTRL_write = 0;
                Status_Next = invalid_cond?1:(Enable_MSU_internal?(5):(0));//stays in this state till the control signals are valid
            end
    2://input pending
            begin
                RST_MSU = 0;//not resetting the MSU
                Enable_MSU = 1;// MSU enabled to generate key/process data
                CNTRCNTRL = 0;
                CNTRCNTRL_write = (~S_AXI_BRESP[1]) & (S_AXI_AWVALID);//counts succsessful writes
                Status_Next = CNTRF_write?(5):(OF?4:2);
            end
    3://output pending
            begin
                RST_MSU = 0;//not resetting the MSU
                Enable_MSU = 1;
                CNTRCNTRL = ~S_AXI_RRESP[1];//only updates counter if no write errors occour
                CNTRCNTRL_write = (~S_AXI_BRESP[1]) & (S_AXI_AWVALID);
                Status_Next = CNTRF?(2):(CNTRF_over?4:(CNTRF_write?5:3));
            end
    4://timed out
           begin
                RST_MSU = 1;//not resetting the MSU
                Enable_MSU = 0;
                CNTRCNTRL = 0;
                CNTRCNTRL_write = 0; 
                Status_Next = 0;// causes memory to reset, back into idle
            end
    5://core busy
            begin
                RST_MSU = 0;//not resetting the MSU
                Enable_MSU = 1;
                CNTRCNTRL = 0;
                CNTRCNTRL_write = 0; 
                Status_Next = OF?3:(RF?2:5);
            end                                      
    default:
            begin
                            RST_MSU = 1;//not resetting the MSU
                            Enable_MSU = 0;// MSU not enabled
                            CNTRCNTRL = 0;// only updates counter if no transfer errors occour
                            CNTRCNTRL_write = 0; 
                            Status_Next = 0;// stays in this state till 3 transactions happen
            end
    endcase
end
    
endmodule
