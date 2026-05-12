`timescale 1ns / 1ps


module aes_tb();

//Module Declerations
logic CLK = 0;
logic CLR;
logic CK;      //Whenever this is asserted, key is reset
logic [31:0] KEY [7:0];
logic [1:0] KL; 
logic enc_dec;
logic [31:0]state_i[3:0];
logic [31:0]state_o[3:0];
logic Valid;
logic CF;


cipher_unit a(
.CLK(CLK),
.CLR(CLR),
.CK(CK),
.KEY(KEY),
.KL(KL), 
.enc_dec(enc_dec),
.state_i(state_i),
.state_o(state_o),
.Valid(Valid),
.CF(CF)
);

//Starting Clock
always #20 CLK = ~CLK;


//Debugging Declerations
logic [3:0] round;      //This is the round counter
logic Mux0;             //This controls external input into state
logic Mux1;             //This controls input into BS (byte sub)
logic [1:0]Mux2;        //This controls input into RS(row shift)
logic Mux3;             //This controls input into MC (mix column)
logic Mux4;             //This controls input into ARK (add round key)
logic Mux5;             //This controls input into state (swaps between encryption and decryption flow)
logic Mux6;             //This controls input into ARK (wether MC is skipped or not)
logic [31:0]bso[3:0];
logic [31:0]rso[3:0];
logic [31:0]mco[3:0];
logic [31:0]arko[3:0];
logic [31:0]bsi[3:0];
logic [31:0]rsi[3:0];
logic [31:0]mci[3:0];
logic [31:0]arki[3:0];
logic [3:0]STate;
logic [31:0]ROUNDKEY[3:0];//THIS IS THE ENTIRE ROUND KEY PER ROUND
logic [3:0]Prev_STate;
logic [3:0]Next_STate;


//Test bench Declerations
logic [5:0]CNTR = 0;
logic [5:0]CNTR_MAX;
logic [5:0]ITERATION = -1;


//Debugging Signals
assign STate = a.s.STATE;
assign Prev_STate = a.s.PREV_STATE;
assign Next_STate = a.s.NXT_STATE;
assign round = a.s.R;
assign Mux0 = a.s.mux0;
assign Mux1 = a.s.mux1;
assign Mux2 = a.s.mux2;
assign Mux3 = a.s.mux3;
assign Mux4 = a.s.mux4;
assign Mux5 = a.s.mux5;
assign Mux6 = a.s.mux6;

assign bsi = a.Bs.state_i;
assign bso = a.Bs.state_o;

assign rsi = a.Rs.state_i;
assign rso = a.Rs.state_o;

assign mci = a.Mc.state_i;;
assign mco = a.Mc.state_o;;

assign arki = a.Ark.state_i;
assign arko = a.Ark.state_o;

assign ROUNDKEY = a.Rk;//DOUBLE CHECK THIS

initial 
begin
    //INPUT DATA
    enc_dec = 1;//1 is encryption 0 is decryption
    CLR = 1;
    CK = 1;// 1 clears the round keys, 0 does not
    KL = 0;// 0 -> 10 , 1 -> 11 , 2 -> 14


    //USE THIS WHEN TESTING ENCRYPTION, THE NEXT COMMENTED SECTION HAS ITS ENCRYPTED VALUE
    state_i[3] = 32'h2054776F;
    state_i[2] = 32'h4E696E65;
    state_i[1] = 32'h4F6E6520;
    state_i[0] = 32'h54776F20;
   /**/
   
    /*     
    //USE THIS WHEN TESTING DECRYPTION, THE PREVIOUS COMMENTED SECTION HAS ITS DECRYPTED VALUE
    state_i[3] = 32'h1a21d73a;
    //state_i[3] = 32'h1a02d73a;
    state_i[2] = 32'h402299b3;
    state_i[1] = 32'h571420f6;
    state_i[0] = 32'h29c3505f;
    */
    
    KEY[0] =32'h54686174;
    KEY[1] =32'h73206D79;
    KEY[2] =32'h204B756E;
    KEY[3] =32'h67204675;
    KEY[4] =32'h00000000;
    KEY[5] =32'h00000000;
    KEY[6] =32'h00000000;
    KEY[7] =32'h00000000;
    
    CNTR = 0;
    #100
    CNTR = 0;
    #80
    
    CLR = 0;
    CK = 0;
    CNTR = 0; 
    /*
    #80// < ----------------------------------------------------to test if changing KL resets everything
    KL = 1;    
    */
end


always_comb//To choose number of cycles required 
begin
    case(KL)
    0:
        begin
            CNTR_MAX = 12;
        end
    1:
        begin
            CNTR_MAX = 14;
        end
    2:
        begin
            CNTR_MAX = 16;
        end
    3:
        begin
            CNTR_MAX = 16;
        end            
    endcase
end

always@(posedge CLK)// Loop for updating time
begin
    CNTR = CNTR + 1;
    if(CNTR_MAX == CNTR)
        CNTR = 0;
    else
        #40;
    if(CF == 1)//updating iteration
        ITERATION = ITERATION + 1;  //First iteration includes round key generation
        
    if(ITERATION == 3) //ADJUST NUMBER OF ITERATIONS FROM HERE -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
            begin
                $stop;
                $finish;
            end
            
end


endmodule
