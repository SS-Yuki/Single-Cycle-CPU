`timescale 1ns / 1ps


module t_RegFile();
    reg clk, rst, WE;
    reg [4 : 0] N1;
    reg [4 : 0] N2;
    reg [4 : 0] ND;
    reg [31 : 0] DI;
    wire [31 : 0] Q1;
    wire [31 : 0] Q2;
    RegFile regfile(clk, rst, WE, N1, N2, ND, DI, Q1, Q2);
    always #10 clk = ~clk;
    initial begin
        clk = 0; rst = 1; WE = 0; N1 = 5'b00000; N2 = 5'b00000; 
        #20 rst = 0; 
        #20 ND = 5'b10101; DI = 32'hffffffff;
        #20 WE = 1;
        #20 N1 = 5'b10101; 
    end
endmodule
