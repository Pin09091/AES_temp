`timescale 1ns / 1ps

module AvalonMM_MSU (    
    input  logic CLK,
    input  logic RST,
    input  logic [127:0] writedata_h,
    input  logic [31:0]  address_h,
    input  logic write_h,
    input  logic read_h,
    output logic [127:0] readdata_h,
    output logic waitrequest_h,
    output logic readdatavalid_h,
    output logic error,
    
    output logic [127:0] DataIn,
    output logic [127:0] KeyIn1,
    output logic [127:0] KeyIn2,
    output logic [127:0] IVIn,
    output logic [2:0]   ModeSelect,
    output logic [1:0]   KeySelect,
    output logic         Enable_MSU,
    output logic         RST_MSU,
    output logic         enc_dec,
    input  logic         OF,
    input  logic         RF,
    input  logic [127:0] DataOut
);

    logic [127:0] Mem_in [4:0];
    logic [127:0] Mem_out [1:0];
    
    logic [2:0] Status, Status_Next, Status_Prev;
    logic invalid_cond;
    logic CNTRF;
    logic CNTRCNTRL;
    logic [1:0] cntr;
    logic Enable_MSU_internal;
    
    assign ModeSelect          = Mem_in[0][2:0];
    assign KeySelect           = Mem_in[0][4:3];
    assign enc_dec             = Mem_in[0][5];
    assign Enable_MSU_internal = Mem_in[0][6];
    
    assign DataIn = Mem_in[1];
    assign KeyIn1 = Mem_in[2];
    assign KeyIn2 = Mem_in[3];
    assign IVIn   = Mem_in[4];

    logic [1:0] state, next_state;
    
    always_ff @(posedge CLK or posedge RST) begin
        if(RST) begin
            state <= 2'b00;
        end else begin
            state <= next_state;
        end
    end
    
    always_comb begin
        case(state)
            2'b00: begin
                waitrequest_h   = 0;
                readdatavalid_h = 0;
                error           = 0;
                
                if (write_h && !read_h) begin
                    next_state = 2'b01;
                end else if (read_h && !write_h) begin
                    next_state = 2'b10;
                end else if (read_h && write_h) begin
                    next_state = 2'b11;
                end else begin
                    next_state = 2'b00;
                end
            end
            
            2'b01: begin
                waitrequest_h   = 1;
                readdatavalid_h = 0;
                error           = 0;
                next_state      = 2'b00;
            end
            
            2'b10: begin
                waitrequest_h   = 1;
                readdatavalid_h = 1;
                error           = 0;
                next_state      = 2'b00;
            end
            
            2'b11: begin
                waitrequest_h   = 0;
                readdatavalid_h = 0;
                error           = 1;
                
                if (!write_h && !read_h) begin
                    next_state = 2'b00;
                end else begin
                    next_state = 2'b11;
                end
            end
            
            default: begin
                waitrequest_h   = 0;
                readdatavalid_h = 0;
                error           = 0;
                next_state      = 2'b00;
            end
        endcase
    end
    
    always_ff @(posedge CLK) begin
        if (RST) begin
            Mem_in[0] <= 128'b0;
            Mem_in[1] <= 128'b0;
            Mem_in[2] <= 128'b0;
            Mem_in[3] <= 128'b0;
            Mem_in[4] <= 128'b0;
        end 
        else
        if(Status == 4)// if input times out
        begin
            Mem_in[0] <= 128'b0;
            Mem_in[1] <= 128'b0;
            Mem_in[2] <= 128'b0;
            Mem_in[3] <= 128'b0;
            Mem_in[4] <= 128'b0;            
        end
        else
        begin 
            if (state == 2'b00 && write_h) 
            begin    
                case(address_h)
                32'h0: Mem_in[0] <= writedata_h;
                32'h1: Mem_in[1] <= writedata_h;
                32'h2: Mem_in[2] <= writedata_h;
                32'h3: Mem_in[3] <= writedata_h;
                32'h4: Mem_in[4] <= writedata_h;
                default: ;
                endcase
            end
         end
    end
    
    always_ff @(posedge CLK) begin
        if (RST) begin
            Mem_out[0] <= 128'b0;
            Mem_out[1] <= 128'b0;
        end 
        else 
        if(Status == 4)
            Mem_out[1] <= 128'b0;//reset if status 4
        else
            begin
                Mem_out[0] <= {125'b0, Status};
                if (OF) begin
                    Mem_out[1] <= DataOut;
                end
            end
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            readdata_h <= 128'b0;
        end 
        else 
            if (state == 2'b00 && read_h) 
            begin
                case(address_h)
                    32'h0: readdata_h <= Mem_out[0];
                    32'h1: readdata_h <= Mem_out[1];
                    default: readdata_h <= 128'b0;
                endcase
            end
    end
    

    logic CNTRF_write;//for write counter logic
    logic CNTRCNTRL_write;// for write counter control
    logic [3:0]cntr_write;//write counter
    
    logic CNTRF_over;//for if output pending takes too long
    logic [3:0]cntr_over;//write counter
        
    always@(posedge CLK)// updating state machine for status
    begin
        Status_Prev <=  (~RST)?Status:0;//<-----------------------Changed this IS NEW NEW NEW
        Status <=  (~RST)?Status_Next:0;//updating state
    end
    
    always@(negedge CLK)// updating counter
    begin
        cntr <= (~RST)?(CNTRCNTRL?(cntr+1):0):0;//to update read counter
        cntr_write <= (~RST)?(CNTRCNTRL_write?(cntr_write+1):0):0;//to update write counter
        cntr_over <= (~RST)?(CNTRCNTRL_write?(cntr+1):0):0;//to keep an eye on output coubter
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
        CNTRF = (cntr == 2);//if 2 reads are done its high
        CNTRF_write = (cntr_write >= 1);//if at least 1 writes are done its high
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
                    CNTRCNTRL_write = write_h;//counts succsessful writes
                    //Status_Next = OF?3:2;
                    Status_Next = CNTRF_write?(5):(OF?4:2);
                    //<----------------------CHANGED THE line ABOVE FROM RF?(OF?4:3):2; to (~Enable_MSU)?(OF?4:3):2;
                end
        3://output pending
                begin
                    RST_MSU = 0;//not resetting the MSU
                    Enable_MSU = 1;
                    CNTRCNTRL = readdatavalid_h;//only updates counter if no write errors occour
                    CNTRCNTRL_write = write_h;;
                    //CNTRCNTRL_write = 0;
    
                    Status_Next = CNTRF?(2):(CNTRF_over?4:(CNTRF_write?5:3));//<------changed from above
                    //Status_Next = CNTRF?(2):(CNTRF_over?4:(CNTRF_write?5:3));//<------changed from above
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
                    Status_Next = OF?3:(RF?2:5);//<----------------------Changed
                    //Status_Next = OF?3:(5);
                    //Status_Next = OF?3:5;// causes memory to reset, back into idle
                    //Status_Next = RF?(OF?3:2):5;
                end                                      
        default:
                begin//<---------------------CHANGED THIS ENTIRE THING
                
                                RST_MSU = 1;//not resetting the MSU
                                Enable_MSU = 0;// MSU not enabled
                                CNTRCNTRL = 0;// only updates counter if no transfer errors occour
                                CNTRCNTRL_write = 0; 
                                Status_Next = 0;// stays in this state till 3 transactions happen
                end
        endcase
    end    
endmodule