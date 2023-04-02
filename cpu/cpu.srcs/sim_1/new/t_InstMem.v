`timescale 1ns / 1ps


module t_InstMem();
    reg [31 : 0] PC;
    wire [5 : 0] op;
    wire [4 : 0] rs; 
    wire [4 : 0] rt;
    wire [4 : 0] rd;
    wire [25 : 0] address;
    wire [15 : 0] imm;
    wire [5 : 0] func;
    InstMem instmem(PC, op, rs, rt, rd, address, imm, func);
    always #10 PC = PC + 4; 
    initial begin
        PC = 0;
    end
endmodule