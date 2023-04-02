`timescale 1ns / 1ps


module t_CPU();
    reg clk, pc_rst, mem_rst, reg_rst;
    CPU cpu(clk, pc_rst, mem_rst, reg_rst);

    always #10 clk = ~clk;
    
    initial #1000 $finish;
    initial begin
        clk = 1; pc_rst = 1; mem_rst = 1; reg_rst = 1;
        #20 pc_rst = 0; mem_rst = 0; reg_rst = 0;
    end
endmodule
