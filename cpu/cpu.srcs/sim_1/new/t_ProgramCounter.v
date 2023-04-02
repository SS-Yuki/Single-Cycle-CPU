`timescale 1ns / 1ps


module t_ProgramCounter();
    reg clk, rst;
    wire [31 : 0] nextPC;
    wire [31 : 0] PC;
    ProgramCounter pc(clk, rst, nextPC, PC);
    assign nextPC = PC + 4;

    always #10 clk = ~clk;

    initial #1000 $finish;
    initial begin
        clk = 0;
        rst = 1;

        #20 rst = 0;
    end
endmodule
