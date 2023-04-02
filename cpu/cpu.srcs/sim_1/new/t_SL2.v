`timescale 1ns / 1ps


module t_SL2();
    reg [25 : 0] a;
    wire [27 : 0] y;
    SL2 sl2(a, y);

    initial begin
        a = 26'b11_1111_1111_1111_1111_1111_1111;
        #10 a = 26'b11_1111_1111_1111_1111_0000_1111;
    end
endmodule