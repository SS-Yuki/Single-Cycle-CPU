`timescale 1ns / 1ps


module t_Adder();
    reg [31 : 0] a;
    reg [31 : 0] b;
    wire [31 : 0] sum;

    Adder adder(a, b, sum);

    initial #100 $finish;
    initial begin
        a = 1; b = 1;
        forever #10 a = a + 1;
    end
endmodule
