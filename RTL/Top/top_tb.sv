`timescale 1ns / 1ps
// =============================================================================
// Module: AES testbench 
// =============================================================================
// Description:
//   Test bench with two tests, (1) to debug specific plaintexts and (2) to
//   do the following operation plaintext -> encrypt -> decrypt on the 
//   appropriatly named mem files. The debugging test runs for all modes and KL
//   Set all the required IV and KEY values before begining either tests. 
//
//   Only ONE interface should be active at a time:
//     interface_toggle = 1 ? AXI4-Lite  interface (AXI_main)
//     interface_toggle = 0 ? Avalon-MM   interface (AvalonMM_MSU)
//
//   For normal operation the following order must be followed:
//     input KEY 1/2/3/4/5/6/7/8 (its a big number so it takes up a bunch of registers)
//     input IV 1/2/3/4/ (initial vector)
//     input DATA IN 1/2/3/4/ (128 bit plaintext)
//     input control register with enable ON (mapping mentioned below)
//     input second DATA IN when Status is 2
//     read first DATA OUT when Status is 3
//     input third DATA OUT when Status is 3 or 2 (you can both read and write at the same time)
//     repeat the last three steps till the file finishes, reset and repeat all steps for a new file or mode
//     all of this is detailed in the tasks below, read through them
//
//   There are 5 valid modes of operations (you can change these before test(2) ):
//     mode_test = 0 ? ECB
//     mode_test = 1 ? CBC
//     mode_test = 2 ? CFB
//     mode_test = 3 ? OFB
//     mode_test = 4 ? CTR
//     A mode_test greater than 4 will be treated as invalid, this test does not accompdate
//     the invalid satus as it was designed to check the correctness of the top
//
//   There are 2 valid enc/dec modes (these are handled by the tasks in both tests):
//     enc_dec_test = 0 ? decrypt
//     enc_dec_test = 1 ? encrypt
//     It is recomended to restart when switching from encryption to decryption
//     as although the results should be correct for ECB, the other modes rely on
//     the output of the previous result, which will be incorrect if not reset
//
//   There are 2 valid enable_test modes (these are handled by the tasks in both tests):
//     enable_test = 0 ? internal operations paused
//     enable_test = 1 ? internal operations started
//     The processor should only be enabled once the Key, first data input
//     and IV are filled into the memory, the Control register should be updated
//     as the final step before starting processing on a file.
//
//   There are 3 valid Key lengths (you can change these before test(2) ):
//     KL_test = 0 ? 128 bit key
//     KL_test = 1 ? 192 bit key
//     KL_test = 2 ? 256 bit key
//     A KL_test greater than 3 will be treated as invalid, this test does not accompdate
//     the invalid satus as it was designed to check the correctness of the top
//
// Clock Architecture:
//   - AXI path  : S_AXI_ACLK (fed to AXI_main and gated for MSU when AXI active)
//   - Avalon path: AVA_CLK   (fed to AvalonMM_MSU and gated for MSU when Ava active)
//
// Reset Architecture:
//   - AXI_main uses active-LOW  reset (S_AXI_ARESETn).
//   - AvalonMM_MSU uses active-HIGH reset (AVA_RST).
//   - RST_MSU (from the active interface) drives the MSU reset (active-HIGH).
//
// =============================================================================

module top_tb();

logic interface_toggle;//toggle for choosing interface


//Declerations for test bench use
int total = 0;
int passed = 0;

logic [127:0] tb_ava_out;// for avalon output to the testbench
logic [127:0] Encrypt_test;// to input to encrypt
logic [127:0] Decrypt_test;// to input to decrypt
logic [127:0] Check_test;// to input to decrypt

logic [127:0] Encrypt_test_1;// to input to encrypt
logic [127:0] Decrypt_test_1;// to input to decrypt
logic [127:0] Check_test_1;// to input to decrypt

logic [127:0] Key_test;// to input as a key
logic [127:0] Key_test_u;//upper key input
logic [127:0] IVIn_test;// inital vector

logic [2:0] mode_test;//mode select in control register
logic [1:0] KL_test;//KL select in control register
logic enable_test;//enable in control register
logic enc_dec_test;// to toggle between encryption and decryption

logic [127:0] control_test_ava;
logic [63:0] control_test_axi;

assign control_test_axi = {56'b0,enable_test,enc_dec_test,KL_test,mode_test};//<-----------------------------------MAPPING FOR CONTROL REGISTER
assign control_test_ava = {120'b0,enable_test,enc_dec_test,KL_test,mode_test};

//Declerations for connections
logic S_AXI_ACLK = 0;//AXI inputs
logic S_AXI_ARESETn;

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


logic AVA_CLK = 0;// avalon inputs
logic AVA_RST;
logic [127:0] writedata_h;
logic [31:0]  address_h;
logic write_h;
logic read_h;
logic [127:0] readdata_h;
logic waitrequest_h;
logic readdatavalid_h;
logic error;

//Connecting signals
AES aes(
.interface_toggle(interface_toggle),//toggle for choosing interface   1-AXI   0-Avalon


.S_AXI_ACLK(S_AXI_ACLK),//AXI inputs
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


.AVA_CLK(AVA_CLK),// avalon inputs
.AVA_RST(AVA_RST),
.writedata_h(writedata_h),
.address_h(address_h),
.write_h(write_h),
.read_h(read_h),
.readdata_h(readdata_h),
.waitrequest_h(waitrequest_h),
.readdatavalid_h(readdatavalid_h),
.error(error)
);



//Clock inputs
always #20 S_AXI_ACLK = ~S_AXI_ACLK;//both of these can be diffrent values as neither interface depends on the other
always #20 AVA_CLK = ~AVA_CLK;

//Tasks
//To handle avalon writes
task avalon_write(input [31:0] addr, input [127:0] data);
    begin
        @(negedge AVA_CLK);
        address_h   = addr;
        writedata_h = data;
        write_h     = 1;
        
        @(posedge AVA_CLK);
        while (waitrequest_h) @(posedge AVA_CLK);
        
        @(negedge AVA_CLK);
        write_h     = 0;
        address_h   = 0;
        writedata_h = 0;
    end
endtask

//To handle avalon reads
task avalon_read(input [31:0] addr, output [127:0] data);
    begin
        @(negedge AVA_CLK);
        address_h = addr;
        read_h    = 1;
        
        @(posedge AVA_CLK);
        while (waitrequest_h) @(posedge AVA_CLK);
        
        @(negedge AVA_CLK);
        read_h    = 0;
        address_h = 0;
        
        while (!readdatavalid_h) @(posedge AVA_CLK);
        data = readdata_h;
    end
endtask

//To handle AXI reads and writes (easier to throw everything into one big task)
task axi_transaction(input [31:0]addr_w,input [63:0]data,input [7:0]strb,input [31:0]addr_r,input read,input write);
    begin
        @(negedge S_AXI_ACLK);
        S_AXI_AWADDR = addr_w;
        S_AXI_AWVALID = write;
        S_AXI_BREADY = write;
        S_AXI_WSTRB = strb;
        S_AXI_WVALID = write;
        S_AXI_WDATA = data;
        
        S_AXI_RREADY = read;
        S_AXI_ARVALID = read;
        S_AXI_ARADDR = addr_r;
        
        @(posedge S_AXI_ACLK);//runing everything
    end
endtask

task reset();
    begin
        @(posedge S_AXI_ACLK or AVA_CLK);
            //resetting
            S_AXI_ARESETn = 0;
            AVA_RST = 1;
            //zeroing AXI signals
            S_AXI_AWADDR = 0;
            S_AXI_AWVALID = 0;
            S_AXI_BREADY = 0;
            S_AXI_WSTRB = 0;
            S_AXI_WVALID = 0;
            S_AXI_WDATA = 0;
            S_AXI_RREADY = 0;
            S_AXI_ARVALID = 0;
            S_AXI_ARADDR = 0;
            //zeroing avalon signals
            address_h = 0;
            read_h    = 0;
            writedata_h = 0;
            write_h     = 0;
            
        @(posedge S_AXI_ACLK or AVA_CLK);
            //un-resetting
            S_AXI_ARESETn = 1;
            AVA_RST = 0;
        @(posedge S_AXI_ACLK or AVA_CLK);    
    end
endtask

//monitors status register for AXI for output pending status
task wait_for_output_axi();//ensure that read adress is 0
    
    @(posedge S_AXI_ACLK);
    S_AXI_AWADDR = 0;
    S_AXI_AWVALID = 0;
    S_AXI_BREADY = 0;
    S_AXI_WSTRB = 0;
    S_AXI_WVALID = 0;
    S_AXI_WDATA = 0;
   
    S_AXI_RREADY = 1;
    S_AXI_ARVALID = 1;
    S_AXI_ARADDR = 0;        
        forever
        begin

          @(S_AXI_RDATA);     
            if((S_AXI_RDATA == 3))//if status is output pending or input is pending
                break;
        end
endtask

//monitors status register for AXI for input pending status
task wait_for_input_axi();//ensure that read adress is 0
    begin
    @(posedge S_AXI_ACLK);
    S_AXI_AWADDR = 0;
    S_AXI_AWVALID = 0;
    S_AXI_BREADY = 0;
    S_AXI_WSTRB = 0;
   S_AXI_WVALID = 0;
    S_AXI_WDATA = 0;
   
    S_AXI_RREADY = 1;
    S_AXI_ARVALID = 1;
    S_AXI_ARADDR = 0;        
        forever
        begin
          @(S_AXI_RDATA);     
            if((S_AXI_RDATA == 2))//if status is output pending or input is pending
                break;
        end
    end
endtask

//montiors status register for both input and output pending (use any of these they all work, included 3 examples so that its easier to understand)
task wait_axi();//ensure that read adress is 0
    begin
    @(posedge S_AXI_ACLK);
    S_AXI_AWADDR = 0;
    S_AXI_AWVALID = 0;
    S_AXI_BREADY = 0;
    S_AXI_WSTRB = 0;
    S_AXI_WVALID = 0;
    S_AXI_WDATA = 0;
   
    S_AXI_RREADY = 1;
    S_AXI_ARVALID = 1;
    S_AXI_ARADDR = 0;        
        forever
        begin
          @(S_AXI_RDATA);     
            if((S_AXI_RDATA == 2)||(S_AXI_RDATA == 3))//if status is output pending or input is pending
                break;
        end
    end
endtask

//same as above but for avalon
task wait_ava();
          
        forever
        begin
        avalon_read(32'h0,tb_ava_out);  
        @(AVA_CLK);     
            if((tb_ava_out == 3) || (tb_ava_out == 2))//if status is output pending or input is pending
                break;
        end
endtask    

//Main task to run a test within (1)
task test();// for KL = 0
    if(interface_toggle)
    begin
        //AXI
        //Encrypt 
        enable_test = 1;//enable in control register
        enc_dec_test = 1;// to toggle between encryption and decryption
        
        reset();
                
        axi_transaction(1,{Key_test[95:64],Key_test[127:96]},8'b11111111,0,1,1);//inputting KEY1/2
        axi_transaction(3,{Key_test[31:0],Key_test[63:32]},8'b11111111,0,1,1);//inputting KEY3/4
        
        axi_transaction(5,{Key_test_u[95:64],Key_test_u[127:96]},8'b11111111,0,1,1);//inputting KEY5/6
        axi_transaction(7,{Key_test_u[31:0],Key_test_u[63:32]},8'b11111111,0,1,1);//inputting KEY7/8
        
        axi_transaction(9,{IVIn_test[95:64],IVIn_test[127:96]},8'b11111111,0,1,1);//inputting IV1/2
        axi_transaction(11,{IVIn_test[31:0],IVIn_test[63:32]},8'b11111111,0,1,1);//inputting IV3/4
        
        
        axi_transaction(13,{Encrypt_test[95:64],Encrypt_test[127:96]},8'b11111111,0,1,1);//inputting Data1/2
        axi_transaction(15,{Encrypt_test[31:0],Encrypt_test[63:32]},8'b11111111,0,1,1);//inputting Data3/4
        
        axi_transaction(0,control_test_axi,8'b00001111,0,1,1);//inputting control
        
        
        wait_axi();// Waits till input of second block
        
        axi_transaction(13,{Encrypt_test_1[95:64],Encrypt_test_1[127:96]},8'b11111111,0,1,1);//inputting second block
        axi_transaction(15,{Encrypt_test_1[31:0],Encrypt_test_1[63:32]},8'b11111111,0,1,1);//inputting second block


        wait_axi();// waits for output of first block
        
        axi_transaction(13,0,8'b11111111,1,1,0);//Reading data for decrypt test
        @(negedge S_AXI_ACLK)
        //Decrypt_test [127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};
        Decrypt_test [63:0] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};
            
        
        axi_transaction(13,0,8'b11111111,2,1,0);//Reading data for decrypt test             
        @(negedge S_AXI_ACLK)
        Decrypt_test [127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};

        axi_transaction(13,0,0,0,1,1);//inputting to prevent timeout
        axi_transaction(15,0,0,0,1,1);//inputting to prevent timeout
        
        wait_axi();// waits for output of second block           
        
        axi_transaction(13,0,8'b11111111,1,1,0);//Reading data for decrypt test
        @(negedge S_AXI_ACLK)
        //Decrypt_test [127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};
        Decrypt_test_1 [63:0] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};
            
        
        axi_transaction(13,0,8'b11111111,2,1,0);//Reading data for decrypt test             
        @(negedge S_AXI_ACLK)
        Decrypt_test_1 [127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};

        
        //Decrypt
        enable_test = 1;//enable in control register
        enc_dec_test = 0;// to toggle between encryption and decryption
        
        reset();
                
        axi_transaction(1,{Key_test[95:64],Key_test[127:96]},8'b11111111,0,1,1);//inputting KEY1/2
        axi_transaction(3,{Key_test[31:0],Key_test[63:32]},8'b11111111,0,1,1);//inputting KEY3/4
        
        axi_transaction(5,{Key_test_u[95:64],Key_test_u[127:96]},8'b11111111,0,1,1);//inputting KEY5/6
        axi_transaction(7,{Key_test_u[31:0],Key_test_u[63:32]},8'b11111111,0,1,1);//inputting KEY7/8   
        
        axi_transaction(9,{IVIn_test[95:64],IVIn_test[127:96]},8'b11111111,0,1,1);//inputting IV1/2
        axi_transaction(11,{IVIn_test[31:0],IVIn_test[63:32]},8'b11111111,0,1,1);//inputting IV3/4                     
        
        axi_transaction(13,{Decrypt_test[95:64],Decrypt_test[127:96]},8'b11111111,0,1,1);//inputting Data1/2
        axi_transaction(15,{Decrypt_test[31:0],Decrypt_test[63:32]},8'b11111111,0,1,1);//inputting Data3/4
        
        
        axi_transaction(0,control_test_axi,8'b00001111,0,1,1);//inputting control
        
        
        
        wait_axi();// wait till input of second block
        
        axi_transaction(13,{Decrypt_test_1[95:64],Decrypt_test_1[127:96]},8'b11111111,0,1,1);//inputting second block
        axi_transaction(15,{Decrypt_test_1[31:0],Decrypt_test_1[63:32]},8'b11111111,0,1,1);//inputting second block


        wait_axi();// waits till output
        
        axi_transaction(13,0,8'b11111111,1,1,0);//Reading data for decrypt test
        @(negedge S_AXI_ACLK)
        //Decrypt_test [127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};
        Check_test [63:0] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};
            
        
        axi_transaction(13,0,8'b11111111,2,1,0);//Reading data for decrypt test             
        @(negedge S_AXI_ACLK)
        Check_test [127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};

        axi_transaction(13,0,0,0,1,1);//inputting to prevent timeout
        axi_transaction(15,0,0,0,1,1);//inputting to prevent timeout
        
        wait_axi();// waits for output of second block            
        
        axi_transaction(13,0,8'b11111111,1,1,0);//Reading data for decrypt test
        @(negedge S_AXI_ACLK)
        //Decrypt_test [127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};
        Check_test_1 [63:0] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};
            
        
        axi_transaction(13,0,8'b11111111,2,1,0);//Reading data for decrypt test             
        @(negedge S_AXI_ACLK)
        Check_test_1 [127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};            

    end  
    else
    begin
        //AVA
        //Encrypt 
        enable_test = 1;//enable in control register
        enc_dec_test = 1;// to toggle between encryption and decryption
        
        reset();
        avalon_write(3,Key_test);
        avalon_write(2,Key_test_u);
        avalon_write(4,IVIn_test);
        avalon_write(1,Encrypt_test);// first inputs
        avalon_write(0,control_test_ava);// starts processing
        
        wait_ava();//waits for second block input
        
        avalon_write(1,Encrypt_test_1);
        
        wait_ava();// waits for first block output
        wait_ava();
        
        avalon_read(1,Decrypt_test);  
        
        //avalon_write(1,0);// to prevent timeout
                    
        wait_ava();//waits for second output
        wait_ava();
        
        //avalon_read(1,Decrypt_test_1);//  
        avalon_write(1,0);
                    
        wait_ava();// waits for first block output
        wait_ava();
                    
        avalon_read(1,Decrypt_test_1);
                                
        //Decrypt
        enable_test = 1;//enable in control register
        enc_dec_test = 0;// to toggle between encryption and decryption
        
        reset();
        avalon_write(3,Key_test);
        avalon_write(2,Key_test_u);
        avalon_write(4,IVIn_test);
        avalon_write(1,Decrypt_test);// first inputs
        avalon_write(0,control_test_ava);// starts processing
        
        wait_ava();//waits for second block input
        
        avalon_write(1,Decrypt_test_1);
        
        wait_ava();// waits for first block output
        wait_ava();
        
        avalon_read(1,Check_test);  
        
        //avalon_write(1,0);// to prevent timeout
                    
        wait_ava();//waits for second output
        wait_ava();
        
        //avalon_read(1,Check_test_1);//  
        avalon_write(1,0);
                    
        wait_ava();// waits for first block output
        wait_ava();
                    
        avalon_read(1,Check_test_1);  
                               
        
    end
    
    if(Encrypt_test === Check_test)
    begin
        $display("RESULT ======== Test Passed ======== || Plaintext = %h || Ciphertext = %h || Decrypted = %h || KL = %h || Mode = %h || Interface = %h ||",Encrypt_test,Decrypt_test,Check_test,KL_test,mode_test,interface_toggle);
        passed = passed + 1;
    end
    else 
        $display("RESULT ======== Test Failed ======== || Plaintext = %h || Ciphertext = %h || Decrypted = %h || KL = %h || Mode = %h || Interface = %h ||",Encrypt_test,Decrypt_test,Check_test,KL_test,mode_test,interface_toggle);

    if(Encrypt_test_1 === Check_test_1)
    begin
        $display("RESULT ======== Test Passed ======== || Plaintext = %h || Ciphertext = %h || Decrypted = %h || KL = %h || Mode = %h || Interface = %h ||",Encrypt_test_1,Decrypt_test_1,Check_test_1,KL_test,mode_test,interface_toggle);
        passed = passed + 1;
    end
    else 
        $display("RESULT ======== Test Failed ======== || Plaintext = %h || Ciphertext = %h || Decrypted = %h || KL = %h || Mode = %h || Interface = %h ||",Encrypt_test_1,Decrypt_test_1,Check_test_1,KL_test,mode_test,interface_toggle);
    
    
    total = total + 2;
endtask

//Main task for test (1)
task test_all();
    interface_toggle = 0;// Avalon tests
        mode_test = 0;// ECB tests
        
            KL_test = 0;//for 128
            test();
            
            KL_test = 1;//for 192
            test();
            
            KL_test = 2;//for 256
            test();        

        mode_test = 1;// CBC tests
            
                KL_test = 0;//for 128
                test();
                
                KL_test = 1;//for 192
                test();
                
                KL_test = 2;//for 256
                test();   
                   
        mode_test = 2;//  tests
                
                    KL_test = 0;//for 128
                    test();
                    
                    KL_test = 1;//for 192
                    test();
                    
                    KL_test = 2;//for 256
                    test();        

        mode_test = 3;//  tests
        
            KL_test = 0;//for 128
            test();
            
            KL_test = 1;//for 192
            test();
            
            KL_test = 2;//for 256
            test();       
             
         mode_test = 4;//  tests
            
                KL_test = 0;//for 128
                test();
                
                KL_test = 1;//for 192
                test();
                
                KL_test = 2;//for 256
                test();        
                                                                                         
                                
    interface_toggle = 1;// Axi tests
                mode_test = 0;// ECB tests
    
        KL_test = 0;//for 128
        test();
        
        KL_test = 1;//for 192
        test();
        
        KL_test = 2;//for 256
        test();        

    mode_test = 1;// CBC tests
        
            KL_test = 0;//for 128
            test();
            
            KL_test = 1;//for 192
            test();
            
            KL_test = 2;//for 256
            test();   
               
    mode_test = 2;//  tests
            
                KL_test = 0;//for 128
                test();
                
                KL_test = 1;//for 192
                test();
                
                KL_test = 2;//for 256
                test();        

    mode_test = 3;//  tests
    
        KL_test = 0;//for 128
        test();
        
        KL_test = 1;//for 192
        test();
        
        KL_test = 2;//for 256
        test();       
         
     mode_test = 4;//  tests
        
            KL_test = 0;//for 128
            test();
            
            KL_test = 1;//for 192
            test();
            
            KL_test = 2;//for 256
            test();

$display("RESULT ======== Overview    ======== || Passed / Total = %d / %d   ||",passed,total);
                                     
                          
endtask




parameter NUM_CHUNKS = 64;// defines how many data items you can read from the mem files, a queue could have worked here too, but this is easier to work with

logic [127:0] file_data [NUM_CHUNKS];      //storage for plaintext
logic [127:0] file_encrypted  [NUM_CHUNKS];//storage for encrypted text
logic [127:0] file_decrypted  [NUM_CHUNKS];//storage for decrypted text

int f_plain;//file pointers for all the files neeeded
int f_encrypted;
int f_decrypted;

//task to handle encryption within test (2)
task encrypt();
enc_dec_test = 1;
enable_test = 1;
if(interface_toggle)
begin
    // AXI
    @(negedge S_AXI_ACLK);
    reset();
            
    axi_transaction(1,{Key_test[95:64],Key_test[127:96]},8'b11111111,0,1,1);//inputting KEY1/2
    axi_transaction(3,{Key_test[31:0],Key_test[63:32]},8'b11111111,0,1,1);//inputting KEY3/4
    
    axi_transaction(5,{Key_test_u[95:64],Key_test_u[127:96]},8'b11111111,0,1,1);//inputting KEY5/6
    axi_transaction(7,{Key_test_u[31:0],Key_test_u[63:32]},8'b11111111,0,1,1);//inputting KEY7/8
    
    axi_transaction(9,{IVIn_test[95:64],IVIn_test[127:96]},8'b11111111,0,1,1);//inputting IV1/2
    axi_transaction(11,{IVIn_test[31:0],IVIn_test[63:32]},8'b11111111,0,1,1);//inputting IV3/4
    
    axi_transaction(13,{file_data[0][95:64],file_data[0][127:96]},8'b11111111,0,1,1);//inputting Data1/2
    axi_transaction(15,{file_data[0][31:0],file_data[0][63:32]},8'b11111111,0,1,1);//inputting Data3/4
    
    axi_transaction(0,control_test_axi,8'b00001111,0,1,1);//inputting control
    
    wait_axi();// Waits till input of second block
    
    axi_transaction(13,{file_data[1][95:64],file_data[1][127:96]},8'b11111111,0,1,1);//inputting second block
    axi_transaction(15,{file_data[1][31:0],file_data[1][63:32]},8'b11111111,0,1,1);//inputting second block

    for (int i = 2; i < NUM_CHUNKS; i++) begin
        wait_axi();

        // Read output of block (i-2)
        axi_transaction(13,0,8'b11111111,1,1,0);
        @(negedge S_AXI_ACLK);
        file_encrypted[i-2][63:0]   = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};

        axi_transaction(13,0,8'b11111111,2,1,0);
        @(negedge S_AXI_ACLK);
        file_encrypted[i-2][127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};

        // Let bus settle before next write
        @(posedge S_AXI_ACLK);
        @(negedge S_AXI_ACLK);

        // Send next input block
        axi_transaction(13,{file_data[i][95:64],file_data[i][127:96]},8'b11111111,0,1,1);
        axi_transaction(15,{file_data[i][31:0], file_data[i][63:32]}, 8'b11111111,0,1,1);
    end
end
else
begin
    // Avalon
    reset();
    avalon_write(3,Key_test);
    avalon_write(2,Key_test_u);
    avalon_write(4,IVIn_test);
    avalon_write(1,file_data[0]);// first block
    avalon_write(0,control_test_ava);// starts processing

    wait_ava();// waits till ready for second block

    avalon_write(1,file_data[1]);// second block

    for (int i = 2; i < NUM_CHUNKS; i++) begin
        wait_ava();// waits for output of block (i-2)
        wait_ava();

        avalon_read(1,file_encrypted[i-2]);// read output of block (i-2)

        avalon_write(1,file_data[i]);// send next block
    end
end

endtask

//task to handle decryption within test (2)
task decrypt();
enc_dec_test = 0;
enable_test = 1;
if(interface_toggle)
begin
    // AXI
    @(negedge S_AXI_ACLK);
    reset();
            
    axi_transaction(1,{Key_test[95:64],Key_test[127:96]},8'b11111111,0,1,1);//inputting KEY1/2
    axi_transaction(3,{Key_test[31:0],Key_test[63:32]},8'b11111111,0,1,1);//inputting KEY3/4
    
    axi_transaction(5,{Key_test_u[95:64],Key_test_u[127:96]},8'b11111111,0,1,1);//inputting KEY5/6
    axi_transaction(7,{Key_test_u[31:0],Key_test_u[63:32]},8'b11111111,0,1,1);//inputting KEY7/8
    
    axi_transaction(9,{IVIn_test[95:64],IVIn_test[127:96]},8'b11111111,0,1,1);//inputting IV1/2
    axi_transaction(11,{IVIn_test[31:0],IVIn_test[63:32]},8'b11111111,0,1,1);//inputting IV3/4
    
    axi_transaction(13,{file_encrypted[0][95:64],file_encrypted[0][127:96]},8'b11111111,0,1,1);//inputting Data1/2
    axi_transaction(15,{file_encrypted[0][31:0],file_encrypted[0][63:32]},8'b11111111,0,1,1);//inputting Data3/4
    
    axi_transaction(0,control_test_axi,8'b00001111,0,1,1);//inputting control
    
    wait_axi();// Waits till input of second block
    
    axi_transaction(13,{file_encrypted[1][95:64],file_encrypted[1][127:96]},8'b11111111,0,1,1);//inputting second block
    axi_transaction(15,{file_encrypted[1][31:0],file_encrypted[1][63:32]},8'b11111111,0,1,1);//inputting second block

    for (int i = 2; i < NUM_CHUNKS; i++) begin
        wait_axi();

        // Read output of block (i-2)
        axi_transaction(13,0,8'b11111111,1,1,0);
        @(negedge S_AXI_ACLK);
        file_decrypted[i-2][63:0]   = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};

        axi_transaction(13,0,8'b11111111,2,1,0);
        @(negedge S_AXI_ACLK);
        file_decrypted[i-2][127:64] = {S_AXI_RDATA[31:0],S_AXI_RDATA[63:32]};

        // Let bus settle before next write
        @(posedge S_AXI_ACLK);
        @(negedge S_AXI_ACLK);

        // Send next input block
        axi_transaction(13,{file_encrypted[i][95:64],file_encrypted[i][127:96]},8'b11111111,0,1,1);
        axi_transaction(15,{file_encrypted[i][31:0], file_encrypted[i][63:32]}, 8'b11111111,0,1,1);
    end
end
else
begin
    // Avalon
    reset();
    avalon_write(3,Key_test);
    avalon_write(2,Key_test_u);
    avalon_write(4,IVIn_test);
    avalon_write(1,file_encrypted[0]);// first block
    avalon_write(0,control_test_ava);// starts processing

    wait_ava();// waits till ready for second block

    avalon_write(1,file_encrypted[1]);// second block

    for (int i = 2; i < NUM_CHUNKS; i++) begin
        wait_ava();// waits for output of block (i-2)
        wait_ava();

        avalon_read(1,file_decrypted[i-2]);// read output of block (i-2)

        avalon_write(1,file_encrypted[i]);// send next block
    end
end

endtask

initial
begin

//================================================================== TEST (2) ================================================================== 
Key_test = 128'h54776F204F6E65754E697E651054736F;// Lower 128 bits of key
Key_test_u = 128'h1234599873D4ADBEE4696E652056776F;// upper 128 bits of key

IVIn_test = 128'hB2E3BE3FBE1FBE1FBE1FB2EFBEaaBEEF;// initial vector

interface_toggle = 1;//<-----------------------------------------------------------------------SET INTERFACE HERE
mode_test = 0;//<------------------------------------------------------------------------------SET MODE HERE
KL_test = 2;//<--------------------------------------------------------------------------------SET KEY LENGTH HERE

//setting all zeros to prevent any null reads (vivado does not like null values)
foreach (file_data[i]) file_data[i] = '0;  
foreach (file_encrypted[i]) file_encrypted[i] = '0;  
foreach (file_decrypted[i]) file_decrypted[i] = '0;  
    

//encrypting
f_plain = $fopen("plaintext.mem", "rb");//<----------------------------------------------------PLAINTEXT FILE HANDLE
if (!f_plain) begin $display("Failed to open plaintext file"); $finish; end

void'($fread(file_data, f_plain));
$fclose(f_plain);

$display("DEBUG: file_data[0] = %h", file_data[0]);
$display("DEBUG: file_data[1] = %h", file_data[1]);

encrypt();

f_encrypted = $fopen("encrypted.mem", "wb");//<------------------------------------------------CIPHERTEXT FILE HANDLE
if (!f_encrypted) begin $display("Failed to open encrypted file"); $finish; end
foreach (file_encrypted[i])
  for (int b = 15; b >= 0; b--)
    $fwrite(f_encrypted, "%c", file_encrypted[i][b*8 +: 8]);  // MSB first, byte by byte
$fclose(f_encrypted);   

//decrypting

foreach (file_encrypted[i]) file_encrypted[i] = '0;//setting all zeros, it should re read all the data to ensure that file reads are working fine  
foreach (file_decrypted[i]) file_decrypted[i] = '0; //no need to touch plaintext since we wont be changing it directly

f_encrypted = $fopen("encrypted.mem", "rb");//<----------------------------------------------------CIPHERTEXT FILE HANDLE
if (!f_encrypted) begin $display("Failed to open encrypted file"); $finish; end

void'($fread(file_encrypted, f_encrypted));
$fclose(f_encrypted);

decrypt();

f_decrypted = $fopen("decrypted.mem", "wb");//<----------------------------------------------------DECRYPTED CIPHERTEXT FILE HANDLE
if (!f_decrypted) begin $display("Failed to open decrypted file"); $finish; end
foreach (file_decrypted[i])
  for (int b = 15; b >= 0; b--)
    $fwrite(f_decrypted, "%c", file_decrypted[i][b*8 +: 8]);  // MSB first, byte by byte
$fclose(f_decrypted);
//================================================================== TEST (2) ==================================================================   




//================================================================== TEST (1) ==================================================================   
/*
$display("Start ======== ======== ======== ======== ======== ======== ======== ======== ======== ======== =======  ");
//test to check for specific plaintexts for debugging

Encrypt_test = file_data[0];// Data to test, for debugging file reading
Encrypt_test_1 = file_data[1];// Data to test, for debugging file reading

//Encrypt_test = 128'hADAA617173206D792345756E752E6767;// Data to test, user defined
//Encrypt_test_1 = 128'hBEABCDFD4CAFEBEFBEEFB0EFCAFECAFE;// Data to test, user defined

Key_test = 128'h54776F204F6E65754E697E651054736F;// Lower 128 bits of key
Key_test_u = 128'h1234599873D4ADBEE4696E652056776F;// upper 128 bits of key

IVIn_test = 128'hB2E3BE3FBE1FBE1FBE1FB2EFBEaaBEEF;// initial vector
//Uncomment for all zeros test wherever you feel like it
//IVIn_test = 128'h00000000000000000000000000000000;// To check for all zerosor
//Key_test = 128'h00000000000000000000000000000000;// Lower 128 bits of key
//Key_test_u = 128'h00000000000000000000000000000000;// upper 128 bits of key
//Encrypt_test = 128'h00000000000000000000000000000000;// To check for all zeros
//Encrypt_test_1 = 128'h00000000000000000000000000000000;// To check for all zeros

test_all();// to test for every mode, KL and interface two pre-set plaintexts
$display("END ======== ======== ======== ======== ======== ======== ======== ======== ======== ======== ========  ");    
*/
//================================================================== TEST (1) ==================================================================

$stop;
$finish;
end

endmodule
