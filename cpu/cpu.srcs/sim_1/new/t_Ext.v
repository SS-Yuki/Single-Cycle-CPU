`timescale 1ns / 1ps


module t_Ext();
    reg select;
    reg [15:0] imm;
    wire [31:0] extend_i;
    Ext ext(select, imm, extend_i);
    initial begin
        imm = 16'hf0f0; select = 0;
        #10 select = 1;
    end
endmodule
