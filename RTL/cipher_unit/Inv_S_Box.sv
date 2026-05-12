`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2025 04:21:31 PM
// Design Name: 
// Module Name: Inv_S_Box
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


module Inv_S_Box(
input logic [7:0] A,    //Input Byte
output logic [7:0] B    //Output Byte
    );
    logic [3:0] row, col;                       //row no. and col no.
    assign row = A [7:4];                       //row is first 4 bits
    assign col = A [3:0];                       //col is last 4 bits
    logic [7:0] rd [15:0];                      //16 rows for decryption
    assign B = rd[row];                         //Row Selector Mux
    
    
    always_comb begin
    
                        //Column Selector Case
    case(col)
    
    4'h0: begin         // Column0
    rd[0] = 8'h52;
    rd[1] = 8'h7c;
    rd[2] = 8'h54;
    rd[3] = 8'h08;
    rd[4] = 8'h72;
    rd[5] = 8'h6c;
    rd[6] = 8'h90;
    rd[7] = 8'hd0;
    rd[8] = 8'h3a;
    rd[9] = 8'h96;
    rd[10] = 8'h47;
    rd[11] = 8'hfc;
    rd[12] = 8'h1f;
    rd[13] = 8'h60;
    rd[14] = 8'ha0;
    rd[15] = 8'h17;
    end
    
    4'h1: begin         // Column1
    rd[0] = 8'h09;
    rd[1] = 8'he3;
    rd[2] = 8'h7b;
    rd[3] = 8'h2e;
    rd[4] = 8'hf8;
    rd[5] = 8'h70;
    rd[6] = 8'hd8;
    rd[7] = 8'h2c;
    rd[8] = 8'h91;
    rd[9] = 8'hac;
    rd[10] = 8'hf1;
    rd[11] = 8'h56;
    rd[12] = 8'hdd;
    rd[13] = 8'h51;
    rd[14] = 8'he0;
    rd[15] = 8'h2b;
    end
    
    4'h2: begin         // Column2
    rd[0] = 8'h6a;
    rd[1] = 8'h39;
    rd[2] = 8'h94;
    rd[3] = 8'ha1;
    rd[4] = 8'hf6;
    rd[5] = 8'h48;
    rd[6] = 8'hab;
    rd[7] = 8'h1e;
    rd[8] = 8'h11;
    rd[9] = 8'h74;
    rd[10] = 8'h1a;
    rd[11] = 8'h3e;
    rd[12] = 8'ha8;
    rd[13] = 8'h7f;
    rd[14] = 8'h3b;
    rd[15] = 8'h04;
    end
    
    4'h3: begin         // Column3
    rd[0] = 8'hd5;
    rd[1] = 8'h82;
    rd[2] = 8'h32;
    rd[3] = 8'h66;
    rd[4] = 8'h64;
    rd[5] = 8'h50;
    rd[6] = 8'h00;
    rd[7] = 8'h8f;
    rd[8] = 8'h41;
    rd[9] = 8'h22;
    rd[10] = 8'h71;
    rd[11] = 8'h4b;
    rd[12] = 8'h33;
    rd[13] = 8'ha9;
    rd[14] = 8'h4d;
    rd[15] = 8'h7e;
    end
    
    4'h4: begin         // Column4
    rd[0] = 8'h30;
    rd[1] = 8'h9b;
    rd[2] = 8'ha6;
    rd[3] = 8'h28;
    rd[4] = 8'h86;
    rd[5] = 8'hfd;
    rd[6] = 8'h8c;
    rd[7] = 8'hca;
    rd[8] = 8'h4f;
    rd[9] = 8'he7;
    rd[10] = 8'h1d;
    rd[11] = 8'hc6;
    rd[12] = 8'h88;
    rd[13] = 8'h19;
    rd[14] = 8'hae;
    rd[15] = 8'hba;
    end
    
    4'h5: begin         // Column5
    rd[0] = 8'h36;
    rd[1] = 8'h2f;
    rd[2] = 8'hc2;
    rd[3] = 8'hd9;
    rd[4] = 8'h68;
    rd[5] = 8'hed;
    rd[6] = 8'hbc;
    rd[7] = 8'h3f;
    rd[8] = 8'h67;
    rd[9] = 8'had;
    rd[10] = 8'h29;
    rd[11] = 8'hd2;
    rd[12] = 8'h07;
    rd[13] = 8'hb5;
    rd[14] = 8'h2a;
    rd[15] = 8'h77;
    end
    
    4'h6: begin         // Column6
    rd[0] = 8'ha5;
    rd[1] = 8'hff;
    rd[2] = 8'h23;
    rd[3] = 8'h24;
    rd[4] = 8'h98;
    rd[5] = 8'hb9;
    rd[6] = 8'hd3;
    rd[7] = 8'h0f;
    rd[8] = 8'hdc;
    rd[9] = 8'h35;
    rd[10] = 8'hc5;
    rd[11] = 8'h79;
    rd[12] = 8'hc7;
    rd[13] = 8'h4a;
    rd[14] = 8'hf5;
    rd[15] = 8'hd6;
    end
    
    4'h7: begin         // Column7
    rd[0] = 8'h38;
    rd[1] = 8'h87;
    rd[2] = 8'h3d;
    rd[3] = 8'hb2;
    rd[4] = 8'h16;
    rd[5] = 8'hda;
    rd[6] = 8'h0a;
    rd[7] = 8'h02;
    rd[8] = 8'hea;
    rd[9] = 8'h85;
    rd[10] = 8'h89;
    rd[11] = 8'h20;
    rd[12] = 8'h31;
    rd[13] = 8'h0d;
    rd[14] = 8'hb0;
    rd[15] = 8'h26;
    end
    
    4'h8: begin         // Column8
    rd[0] = 8'hbf;
    rd[1] = 8'h34;
    rd[2] = 8'hee;
    rd[3] = 8'h76;
    rd[4] = 8'hd4;
    rd[5] = 8'h5e;
    rd[6] = 8'hf7;
    rd[7] = 8'hc1;
    rd[8] = 8'h97;
    rd[9] = 8'he2;
    rd[10] = 8'h6f;
    rd[11] = 8'h9a;
    rd[12] = 8'hb1;
    rd[13] = 8'h2d;
    rd[14] = 8'hc8;
    rd[15] = 8'he1;
    end
    
    4'h9: begin         // Column9
    rd[0] = 8'h40;
    rd[1] = 8'h8e;
    rd[2] = 8'h4c;
    rd[3] = 8'h5b;
    rd[4] = 8'ha4;
    rd[5] = 8'h15;
    rd[6] = 8'he4;
    rd[7] = 8'haf;
    rd[8] = 8'hf2;
    rd[9] = 8'hf9;
    rd[10] = 8'hb7;
    rd[11] = 8'hdb;
    rd[12] = 8'h12;
    rd[13] = 8'he5;
    rd[14] = 8'heb;
    rd[15] = 8'h69;
    end
    
    4'ha: begin         // ColumnA
    rd[0] = 8'ha3;
    rd[1] = 8'h43;
    rd[2] = 8'h95;
    rd[3] = 8'ha2;
    rd[4] = 8'h5c;
    rd[5] = 8'h46;
    rd[6] = 8'h58;
    rd[7] = 8'hbd;
    rd[8] = 8'hcf;
    rd[9] = 8'h37;
    rd[10] = 8'h62;
    rd[11] = 8'hc0;
    rd[12] = 8'h10;
    rd[13] = 8'h7a;
    rd[14] = 8'hbb;
    rd[15] = 8'h14;
    end
    
    4'hb: begin         // ColumnB
    rd[0] = 8'h9e;
    rd[1] = 8'h44;
    rd[2] = 8'h0b;
    rd[3] = 8'h49;
    rd[4] = 8'hcc;
    rd[5] = 8'h57;
    rd[6] = 8'h05;
    rd[7] = 8'h03;
    rd[8] = 8'hce;
    rd[9] = 8'he8;
    rd[10] = 8'h0e;
    rd[11] = 8'hfe;
    rd[12] = 8'h59;
    rd[13] = 8'h9f;
    rd[14] = 8'h3c;
    rd[15] = 8'h63;
    end
    
    4'hc: begin         // ColumnC
    rd[0] = 8'h81;
    rd[1] = 8'hc4;
    rd[2] = 8'h42;
    rd[3] = 8'h6d;
    rd[4] = 8'h5d;
    rd[5] = 8'ha7;
    rd[6] = 8'hb8;
    rd[7] = 8'h01;
    rd[8] = 8'hf0;
    rd[9] = 8'h1c;
    rd[10] = 8'haa;
    rd[11] = 8'h78;
    rd[12] = 8'h27;
    rd[13] = 8'h93;
    rd[14] = 8'h83;
    rd[15] = 8'h55;
    end
    
    4'hd: begin         // ColumnD
    rd[0] = 8'hf3;
    rd[1] = 8'hde;
    rd[2] = 8'hfa;
    rd[3] = 8'h8b;
    rd[4] = 8'h65;
    rd[5] = 8'h8d;
    rd[6] = 8'hb3;
    rd[7] = 8'h13;
    rd[8] = 8'hb4;
    rd[9] = 8'h75;
    rd[10] = 8'h18;
    rd[11] = 8'hcd;
    rd[12] = 8'h80;
    rd[13] = 8'hc9;
    rd[14] = 8'h53;
    rd[15] = 8'h21;
    end
    
    4'he: begin         // ColumnE
    rd[0] = 8'hd7;
    rd[1] = 8'he9;
    rd[2] = 8'hc3;
    rd[3] = 8'hd1;
    rd[4] = 8'hb6;
    rd[5] = 8'h9d;
    rd[6] = 8'h45;
    rd[7] = 8'h8a;
    rd[8] = 8'he6;
    rd[9] = 8'hdf;
    rd[10] = 8'hbe;
    rd[11] = 8'h5a;
    rd[12] = 8'hec;
    rd[13] = 8'h9c;
    rd[14] = 8'h99;
    rd[15] = 8'h0c;
    end
    
    4'hf: begin         // ColumnF
    rd[0] = 8'hfb;
    rd[1] = 8'hcb;
    rd[2] = 8'h4e;
    rd[3] = 8'h25;
    rd[4] = 8'h92;
    rd[5] = 8'h84;
    rd[6] = 8'h06;
    rd[7] = 8'h6b;
    rd[8] = 8'h73;
    rd[9] = 8'h6e;
    rd[10] = 8'h1b;
    rd[11] = 8'hf4;
    rd[12] = 8'h5f;
    rd[13] = 8'hef;
    rd[14] = 8'h61;
    rd[15] = 8'h7d;
    end
    
    endcase
    end
endmodule
