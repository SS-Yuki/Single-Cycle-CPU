`timescale 1ns / 1ps


module t_DataMemory();
    reg clk, rst, WE;
    reg [31 : 0] address, wd;
    wire [31 : 0] rd;
    DataMemory datamemory(clk, rst, WE, address, wd, rd);
    always #10 clk = ~clk;
    initial begin
        clk = 0; rst = 1; WE = 0;
        address = 32'h0000_0000; wd = 32'hffff_ffff;
        #20 rst = 0; WE = 1;
    end
endmodule
