`timescale 1ns / 1ps


module S_Box(
input logic [7:0] A,
output logic [7:0] B    //Output Byte
    );
    logic [3:0] row, col;                       //row no. and col no.
    assign row = A [7:4];                       //row is first 4 bits
    assign col = A [3:0];                       //col is last 4 bits
    logic [7:0] re [15:0];                      //16 rows for encryption
    assign B = re[row];                         //Row Selector Mux
    always_comb begin
    
                        // Column Selector Case
    case(col)
    
    4'h0: begin         // Column0
    re[0] = 8'h63;
    re[1] = 8'hca;
    re[2] = 8'hb7;
    re[3] = 8'h04;
    re[4] = 8'h09;
    re[5] = 8'h53;
    re[6] = 8'hd0;
    re[7] = 8'h51;
    re[8] = 8'hcd;
    re[9] = 8'h60;
    re[10] = 8'he0;
    re[11] = 8'he7;
    re[12] = 8'hba;
    re[13] = 8'h70;
    re[14] = 8'he1;
    re[15] = 8'h8c;
    end
    
    4'h1: begin         // Column1
    re[0] = 8'h7c;
    re[1] = 8'h82;
    re[2] = 8'hfd;
    re[3] = 8'hc7;
    re[4] = 8'h83;
    re[5] = 8'hd1;
    re[6] = 8'hef;
    re[7] = 8'ha3;
    re[8] = 8'h0c;
    re[9] = 8'h81;
    re[10] = 8'h32;
    re[11] = 8'hc8;
    re[12] = 8'h78;
    re[13] = 8'h3e;
    re[14] = 8'hf8;
    re[15] = 8'ha1;
    end
    
    4'h2: begin         // Column2
    re[0] = 8'h77;
    re[1] = 8'hc9;
    re[2] = 8'h93;
    re[3] = 8'h23;
    re[4] = 8'h2c;
    re[5] = 8'h00;
    re[6] = 8'haa;
    re[7] = 8'h40;
    re[8] = 8'h13;
    re[9] = 8'h4f;
    re[10] = 8'h3a;
    re[11] = 8'h37;
    re[12] = 8'h25;
    re[13] = 8'hb5;
    re[14] = 8'h98;
    re[15] = 8'h89;
    end
    
    4'h3: begin         // Column3
    re[0] = 8'h7b;
    re[1] = 8'h7d;
    re[2] = 8'h26;
    re[3] = 8'hc3;
    re[4] = 8'h1a;
    re[5] = 8'hed;
    re[6] = 8'hfb;
    re[7] = 8'h8f;
    re[8] = 8'hec;
    re[9] = 8'hdc;
    re[10] = 8'h0a;
    re[11] = 8'h6d;
    re[12] = 8'h2e;
    re[13] = 8'h66;
    re[14] = 8'h11;
    re[15] = 8'h0d;
    end
    
    4'h4: begin         // Column4
    re[0] = 8'hf2;
    re[1] = 8'hfa;
    re[2] = 8'h36;
    re[3] = 8'h18;
    re[4] = 8'h1b;
    re[5] = 8'h20;
    re[6] = 8'h43;
    re[7] = 8'h92;
    re[8] = 8'h5f;
    re[9] = 8'h22;
    re[10] = 8'h49;
    re[11] = 8'h8d;
    re[12] = 8'h1c;
    re[13] = 8'h48;
    re[14] = 8'h69;
    re[15] = 8'hbf;
    end
    
    4'h5: begin         // Column5
    re[0] = 8'h6b;
    re[1] = 8'h59;
    re[2] = 8'h3f;
    re[3] = 8'h96;
    re[4] = 8'h6e;
    re[5] = 8'hfc;
    re[6] = 8'h4d;
    re[7] = 8'h9d;
    re[8] = 8'h97;
    re[9] = 8'h2a;
    re[10] = 8'h06;
    re[11] = 8'hd5;
    re[12] = 8'ha6;
    re[13] = 8'h03;
    re[14] = 8'hd9;
    re[15] = 8'he6;
    end
    
    4'h6: begin         // Column6
    re[0] = 8'h6f;
    re[1] = 8'h47;
    re[2] = 8'hf7;
    re[3] = 8'h05;
    re[4] = 8'h5a;
    re[5] = 8'hb1;
    re[6] = 8'h33;
    re[7] = 8'h38;
    re[8] = 8'h44;
    re[9] = 8'h90;
    re[10] = 8'h24;
    re[11] = 8'h4e;
    re[12] = 8'hb4;
    re[13] = 8'hf6;
    re[14] = 8'h8e;
    re[15] = 8'h42;
    end
    
    4'h7: begin         // Column7
    re[0] = 8'hc5;
    re[1] = 8'hf0;
    re[2] = 8'hcc;
    re[3] = 8'h9a;
    re[4] = 8'ha0;
    re[5] = 8'h5b;
    re[6] = 8'h85;
    re[7] = 8'hf5;
    re[8] = 8'h17;
    re[9] = 8'h88;
    re[10] = 8'h5c;
    re[11] = 8'ha9;
    re[12] = 8'hc6;
    re[13] = 8'h0e;
    re[14] = 8'h94;
    re[15] = 8'h68;
    end
    
    4'h8: begin         // Column8
    re[0] = 8'h30;
    re[1] = 8'had;
    re[2] = 8'h34;
    re[3] = 8'h07;
    re[4] = 8'h52;
    re[5] = 8'h6a;
    re[6] = 8'h45;
    re[7] = 8'hbc;
    re[8] = 8'hc4;
    re[9] = 8'h46;
    re[10] = 8'hc2;
    re[11] = 8'h6c;
    re[12] = 8'he8;
    re[13] = 8'h61;
    re[14] = 8'h9b;
    re[15] = 8'h41;
    end
    
    4'h9: begin         // Column9
    re[0] = 8'h01;
    re[1] = 8'hd4;
    re[2] = 8'ha5;
    re[3] = 8'h12;
    re[4] = 8'h3b;
    re[5] = 8'hcb;
    re[6] = 8'hf9;
    re[7] = 8'hb6;
    re[8] = 8'ha7;
    re[9] = 8'hee;
    re[10] = 8'hd3;
    re[11] = 8'h56;
    re[12] = 8'hdd;
    re[13] = 8'h35;
    re[14] = 8'h1e;
    re[15] = 8'h99;
    end
    
    4'ha: begin         // ColumnA
    re[0] = 8'h67;
    re[1] = 8'ha2;
    re[2] = 8'he5;
    re[3] = 8'h80;
    re[4] = 8'hd6;
    re[5] = 8'hbe;
    re[6] = 8'h02;
    re[7] = 8'hda;
    re[8] = 8'h7e;
    re[9] = 8'hb8;
    re[10] = 8'hac;
    re[11] = 8'hf4;
    re[12] = 8'h74;
    re[13] = 8'h57;
    re[14] = 8'h87;
    re[15] = 8'h2d;
    end
    
    4'hb: begin         // ColumnB
    re[0] = 8'h2b;
    re[1] = 8'haf;
    re[2] = 8'hf1;
    re[3] = 8'he2;
    re[4] = 8'hb3;
    re[5] = 8'h39;
    re[6] = 8'h7f;
    re[7] = 8'h21;
    re[8] = 8'h3d;
    re[9] = 8'h14;
    re[10] = 8'h62;
    re[11] = 8'hea;
    re[12] = 8'h1f;
    re[13] = 8'hb9;
    re[14] = 8'he9;
    re[15] = 8'h0f;
    end
    
    4'hc: begin         // ColumnC
    re[0] = 8'hfe;
    re[1] = 8'h9c;
    re[2] = 8'h71;
    re[3] = 8'heb;
    re[4] = 8'h29;
    re[5] = 8'h4a;
    re[6] = 8'h50;
    re[7] = 8'h10;
    re[8] = 8'h64;
    re[9] = 8'hde;
    re[10] = 8'h91;
    re[11] = 8'h65;
    re[12] = 8'h4b;
    re[13] = 8'h86;
    re[14] = 8'hce;
    re[15] = 8'hb0;
    end
    
    4'hd: begin         // ColumnD
    re[0] = 8'hd7;
    re[1] = 8'ha4;
    re[2] = 8'hd8;
    re[3] = 8'h27;
    re[4] = 8'he3;
    re[5] = 8'h4c;
    re[6] = 8'h3c;
    re[7] = 8'hff;
    re[8] = 8'h5d;
    re[9] = 8'h5e;
    re[10] = 8'h95;
    re[11] = 8'h7a;
    re[12] = 8'hbd;
    re[13] = 8'hc1;
    re[14] = 8'h55;
    re[15] = 8'h54;
    end
    
    4'he: begin         // ColumnE
    re[0] = 8'hab;
    re[1] = 8'h72;
    re[2] = 8'h31;
    re[3] = 8'hb2;
    re[4] = 8'h2f;
    re[5] = 8'h58;
    re[6] = 8'h9f;
    re[7] = 8'hf3;
    re[8] = 8'h19;
    re[9] = 8'h0b;
    re[10] = 8'he4;
    re[11] = 8'hae;
    re[12] = 8'h8b;
    re[13] = 8'h1d;
    re[14] = 8'h28;
    re[15] = 8'hbb;
    end
    
    4'hf: begin         // ColumnF
    re[0] = 8'h76;
    re[1] = 8'hc0;
    re[2] = 8'h15;
    re[3] = 8'h75;
    re[4] = 8'h84;
    re[5] = 8'hcf;
    re[6] = 8'ha8;
    re[7] = 8'hd2;
    re[8] = 8'h73;
    re[9] = 8'hdb;
    re[10] = 8'h79;
    re[11] = 8'h08;
    re[12] = 8'h8a;
    re[13] = 8'h9e;
    re[14] = 8'hdf;
    re[15] = 8'h16;
    end
    
    endcase
    end
endmodule