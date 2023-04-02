`timescale 1ns / 1ps


module t_ALU();
    reg [31 : 0] a;
    reg [31 : 0] b;
    reg [2 : 0] alucont;
    wire [31 : 0] result;
    wire overflow;
    ALU alu(a, b, alucont, result, overflow);
    
    initial #100 $finish;
    initial begin
        a = 32'h7fff_fff0;
        b = 32'h7fff_fff0;
        alucont = 3'b000;        //add
        #10 alucont = 3'b010;    //addu
        #10 alucont = 3'b001;    //sub
        #10 b = 32'h8fff_fff0;
        #10 b = 32'h0101_0101;
        #10 alucont = 3'b011;    //and
        #10 alucont = 3'b100;    //or
        #10 alucont = 3'b101;    //less than
        #10 b = 32'h8fff_fff0;
    end
endmodule
