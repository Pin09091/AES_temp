`timescale 1ns / 1ps

module tb_AvalonMM_MSU();

    logic CLK;
    logic RST;
    
    logic [127:0] writedata_h;
    logic [31:0]  address_h;
    logic         write_h;
    logic         read_h;
    logic [127:0] readdata_h;
    logic         waitrequest_h;
    logic         readdatavalid_h;
    logic         error;
    
    logic [127:0] DataIn;
    logic [127:0] KeyIn1;
    logic [127:0] KeyIn2;
    logic [127:0] IVIn;
    logic [2:0]   ModeSelect;
    logic [1:0]   KeySelect;
    logic         Enable_MSU;
    logic         RST_MSU;
    logic         enc_dec;
    logic         OF;
    logic         RF;
    logic [127:0] DataOut;

    AvalonMM_MSU uut (
        .CLK(CLK),
        .RST(RST),
        .writedata_h(writedata_h),
        .address_h(address_h),
        .write_h(write_h),
        .read_h(read_h),
        .readdata_h(readdata_h),
        .waitrequest_h(waitrequest_h),
        .readdatavalid_h(readdatavalid_h),
        .error(error),
        .DataIn(DataIn),
        .KeyIn1(KeyIn1),
        .KeyIn2(KeyIn2),
        .IVIn(IVIn),
        .ModeSelect(ModeSelect),
        .KeySelect(KeySelect),
        .Enable_MSU(Enable_MSU),
        .RST_MSU(RST_MSU),
        .enc_dec(enc_dec),
        .OF(OF),
        .RF(RF),
        .DataOut(DataOut)
    );

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    task avalon_write(input [31:0] addr, input [127:0] data);
        begin
            @(negedge CLK);
            address_h   = addr;
            writedata_h = data;
            write_h     = 1;
            
            @(posedge CLK);
            while (waitrequest_h) @(posedge CLK);
            
            @(negedge CLK);
            write_h     = 0;
            address_h   = 0;
            writedata_h = 0;
        end
    endtask

    task avalon_read(input [31:0] addr, output [127:0] data);
        begin
            @(negedge CLK);
            address_h = addr;
            read_h    = 1;
            
            @(posedge CLK);
            while (waitrequest_h) @(posedge CLK);
            
            @(negedge CLK);
            read_h    = 0;
            address_h = 0;
            
            while (!readdatavalid_h) @(posedge CLK);
            data = readdata_h;
            $display("Time=%0t | Addr: %0h | Data: %h", $time, addr, data);
        end
    endtask

    logic [127:0] read_data_var;

    initial begin
        RST         = 1;
        writedata_h = 0;
        address_h   = 0;
        write_h     = 0;
        read_h      = 0;
        OF          = 0;
        RF          = 0;
        DataOut     = 0;

        #25;
        RST = 0;
        #15;

        avalon_write(32'h1, 128'h54776F204F6E65204E696E652054776F);
        //avalon_write(32'h1,128'h5468617473206D79204B756E67204675);//inputting KEY1/2/3/4
        
        
        avalon_write(32'h2, 128'h5468617473206D79204B756E67204675);
        //avalon_write(32'h2,128'h54776F204F6E65204E696E652054776F);//inputting Data1/2/3/4
        
        avalon_write(32'h0, 128'h00000000000000000000000000000060);

        repeat(10) @(posedge CLK);

        avalon_read(32'h0, read_data_var);

        @(negedge CLK);
        DataOut = 128'hDEADBEEF_CAFEBABE_12345678_9ABCDEF0;
        OF = 1; 
        @(negedge CLK);
        OF = 0; 
        
        repeat(5) @(posedge CLK);

        avalon_read(32'h1, read_data_var);

        #50;
        $stop;
    end

    initial begin
        $monitor("Time=%0t | RST=%b | Status=%d | Enable_MSU=%b | RST_MSU=%b | error=%b", 
                 $time, RST, uut.Status, Enable_MSU, RST_MSU, error);
    end

endmodule