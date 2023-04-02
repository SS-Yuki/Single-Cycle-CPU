`timescale 1ns / 1ps


module t_MUX_5();
    reg select;
    reg [4 : 0] a;
    reg [4 : 0] b;
    wire [4 : 0] result;
    MUX_5 mux_5(select, a, b, result);

    initial begin
        a = 5'b01010; b = 5'b11111;
        select = 0;
        #10 select = 1;
    end
endmodule
