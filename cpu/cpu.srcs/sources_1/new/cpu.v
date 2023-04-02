`timescale 1ns / 1ps


//基本部件: 程序计数器
/*(1)部件功能说明: 输入的值nextPC是下一周期的PC，用于更新PC。
(2)部件设计思路: 本模块仅需要进行赋值，利用always语句通过时钟信号进行触发（另加了reset功能）。
(3)部件会在单周期CPU的哪些地方能够用到: 获得一个周期操作的指令地址。
*/
module ProgramCounter (
    input clk, rst,
    input [31 : 0] nextPC,
    output reg[31 : 0] PC
);
    always @(posedge clk, posedge rst) begin
        if (rst) PC <= 0;
        else PC <= nextPC;
    end
endmodule


//基本部件: 指令存储单元
/*(1)部件功能说明: 利用存储的指令，将输入的指令地址进行分析，得到rs、rt等指令信息。
(2)部件设计思路: 截取PC有效位，在指令RAM中找到对应指令，再将指令截取成不同信息输出。
(3)部件会在单周期CPU的哪些地方能够用到: 利用PC得到各种指令信息。
*/
module InstMem (
    input [31 : 0] PC,
    output [5 : 0] op,
    output [4 : 0] rs, 
    output [4 : 0] rt,
    output [4 : 0] rd,
    output [25 : 0] address,
    output [15 : 0] imm,
    output [5 : 0] func
);
    wire [31 : 0] RAM[0 : 15];

    //初始化
    assign RAM[0] = 32'h00000000;
    assign RAM[1] = 32'h20010008;   //addi
	assign RAM[2] = 32'h3402000c;   //ori
	assign RAM[3] = 32'h3049000a;   //andi
	assign RAM[4] = 32'h282a000c;   //slti 
    assign RAM[5] = 32'h00221820;   //add
    assign RAM[6] = 32'h00412022;   //sub
    assign RAM[7] = 32'h00222824;   //and 
	assign RAM[8] = 32'h00223025;   //or 
    assign RAM[9] = 32'h0022382a;   //slt 
    assign RAM[10] = 32'hac220004;   //sw 
    assign RAM[11] = 32'h8c280004;   //lw 
    assign RAM[12] = 32'h00000000;   //nop
    assign RAM[13] = 32'h0800000f;   //jump
    assign RAM[14] = 32'h00000000;   
    assign RAM[15] = 32'h00000000;   

    wire [3 : 0] PC_use;
    assign PC_use = PC[5 : 2];
    
    assign op = RAM[PC_use][31 : 26];
    assign rs = RAM[PC_use][25 : 21];
    assign rt = RAM[PC_use][20 : 16];
    assign rd = RAM[PC_use][15 : 11];
    assign address = RAM[PC_use][25 : 0];
    assign imm = RAM[PC_use][15 : 0];
    assign func = RAM[PC_use][5 : 0];

endmodule


//基本部件: 寄存器单元
/*(1)部件功能说明: 输出寄存器中地址N1、N2对应的值Q1、Q2；在写入使能WE有效时，执行写入操作。
(2)部件设计思路: 利用assign输出Q1、Q2；在时钟下降沿通过if进行条件判断，进而进行写入赋值操作（另加了reset功能）
(3)部件会在单周期CPU的哪些地方能够用到: 在执行寄存器的读取、写入中使用。
*/
module RegFile (
    input clk, rst, WE,
    input [4 : 0] N1,
    input [4 : 0] N2,
    input [4 : 0] ND,
    input [31 : 0] DI,
    output [31 : 0] Q1,
    output [31 : 0] Q2
); 
    reg [31 : 0] regfile[0 : 31];
    assign Q1 = (N1 != 0) ? regfile[N1] : 0;
    assign Q2 = (N2 != 0) ? regfile[N2] : 0;

    integer i;
    always @(negedge clk) begin
        if (rst) for (i = 0; i < 32; i = i + 1) regfile[i] <= 0;
        else if (WE && ND) regfile[ND] <= DI;
    end
endmodule


//基本部件: ALU运算单元
/*(1)部件功能说明: 对输入的a、b根据操作码的不同，输出不同的运算结果，对运算的溢出情况进行判断。
(2)部件设计思路: 利用case对于不同的操作码执行不同操作，根据对支持指令的要求，ALU运算包括有符号的加减、无符号的加、与、或、小于。
(3)部件会在单周期CPU的哪些地方能够用到: 根据指令信息进行ALU运算。
*/
module ALU (
    input [31 : 0] a,
    input [31 : 0] b,
    input [2 : 0] alucont,
    output reg [31 : 0] result,
    output reg overflow
);
    reg [32:0] sum;
    reg [32:0] sub;
    always @(*) begin
        case (alucont)
            //加（判断溢出）
            3'b000: begin
                result = a + b;
                sum = {a[31], a[31 : 0]} + {b[31], b[31 : 0]};
                if (sum[31] == sum[32]) overflow = 1'b0;
                else overflow = 1'b1;
            end
            //减（判断溢出）
            3'b001: begin
                result = a - b;
                sub = {a[31], a[31 : 0]} - {b[31], b[31 : 0]};
                if (sub[31] == sub[32]) overflow = 1'b0;
                else overflow = 1'b1;
            end
            //加（不判断溢出）
            3'b010: begin
                result = a + b;
                overflow = 1'b0;
            end
            //与
            3'b011: begin
                result = a & b;
                overflow = 1'b0;
            end
            //或
            3'b100: begin
                result = a | b;
                overflow = 1'b0;
            end
            //小于
            3'b101: begin
                if (a < b) result = 32'h00000001;
                else result = 32'h00000000;
                overflow = 1'b0;
            end
        endcase
    end
endmodule


//基本部件: 数据存储单元
/*(1)部件功能说明: 进行数据的读取和写入。
(2)部件设计思路: 利用assign输出rd；在时钟下降沿通过if进行条件判断，进而进行写入赋值操作（另加了reset功能）
(3)部件会在单周期CPU的哪些地方能够用到: 在CPU中用于对此数据存储单元的操作。
*/
module DataMemory (
    input clk, rst, WE,
    input [31 : 0] address, wd,
    output [31 : 0] rd
);
    reg [31 : 0] date_mem[0 : 63];
    wire [5 : 0] address_use;
    assign address_use = address[7 : 2];
    assign rd = date_mem[address_use];

    integer i;
    always@(negedge clk) begin
        if (rst) for(i = 0; i < 64; i = i + 1) date_mem[i] <= 0;
        else if (WE) date_mem[address_use] <= wd;
    end
endmodule


//基本部件: 立即数扩展单元
/*(1)部件功能说明: 将16bit的立即数补为32bit，分为sign_extend和zero_extend两种。
(2)部件设计思路: 利用？:运算符，借助select判断扩展类型，并进行相应操作。
(3)部件会在单周期CPU的哪些地方能够用到: 将立即数进行位宽拓展方便进行之后的运算等。
*/
module Ext (
    input select,
    input [15:0] imm,
    output [31:0] extend_i
);
    assign extend_i[15:0] = imm;
    assign extend_i[31:16] = select ? (imm[15] ? 16'hffff : 16'h0000) : 16'h0000;
endmodule


//基本部件: 选择器
/*(1)部件功能说明: 在a、b两个数据中进行选择。
(2)部件设计思路: 利用?:运算符，借助select进行数据的选择。
(3)部件会在单周期CPU的哪些地方能够用到: ALU中输入B的选择、下一个PC值的选择、写入寄存器数据的选择、写入地址ND的选择。
*/
module MUX_32 (
    input select,
    input [31 : 0] a,
    input [31 : 0] b,
    output [31 : 0] result
);
    assign result = select ? a : b;
endmodule
module MUX_5 (
    input select,
    input [4 : 0] a,
    input [4 : 0] b,
    output [4 : 0] result
);
    assign result = select ? a : b;
endmodule


//基本部件: 无符号加法器
/*(1)部件功能说明: 输出a、b的和。
(2)部件设计思路: 直接利用运算符输出结果。
(3)部件会在单周期CPU的哪些地方能够用到: 计算PC + 4。
*/
module Adder (
    input [31 : 0] a,
    input [31 : 0] b,
    output [31 : 0] sum
);
    assign sum = a + b;
endmodule


//基本部件: 左移器
/*(1)部件功能说明: 将数值a左移两位。
(2)部件设计思路: 利用assign直接输出结果。
(3)部件会在单周期CPU的哪些地方能够用到: jump指令时对address的操作。
*/
module SL2 (
    input [25 : 0] a,
    output [27 : 0] y
);
    assign y = {a, 2'b00};
endmodule


//控制单元
/*(1)部件功能说明: 控制基本部件功能的实现。
(2)部件设计思路: 通过设计图得出所有控制信号，将控制单元分成两个译码器部件，在MainDec中由op得到除ALUop之外的控制信号的值，在AluDec中由MainDec中得到的信息和func综合，得到ALUop。
(3)部件会在单周期CPU的哪些地方能够用到: 与其他基本部件相连，控制基本部件功能的实现。
*/
module Controller (
    input [5 : 0] op,
    input [5 : 0] func,
    output regrt, sext, wreg, aluimm, wmem, m2reg, jump, getalu,
    output [2 : 0] aluop
);
    wire [2:0] aluop1;
    MainDec md (op, regrt, sext, wreg, aluimm, wmem, m2reg, jump, getalu, aluop1);
    AluDec ad (func, getalu, aluop1, aluop);
    
endmodule

module MainDec (
    input [5 : 0] op, 
    output regrt, sext, wreg, aluimm, wmem, m2reg, jump, getalu, 
    output [2 : 0] aluop1
);
    reg [10 : 0] controls;
    assign {regrt, sext, wreg, aluimm, wmem, m2reg, jump, getalu, aluop1} = controls;

    always@(*) begin
        case (op)
            //R-type
            6'b000000 : controls = 11'b00100000_000;
            //addi
            6'b001000 : controls = 11'b11110001_000;
            //addiu
            6'b001001 : controls = 11'b10110001_010;
            //andi
            6'b001100 : controls = 11'b10110001_011;
            //ori
            6'b001101 : controls = 11'b10110001_100;
            //slti
            6'b001010 : controls = 11'b11110001_101;
            //sw
            6'b101011 : controls = 11'b01011001_010;
            //lw
            6'b100011 : controls = 11'b11110101_010;
            //jump
            6'b000010 : controls = 11'b00000011_000;
            default:  controls = 11'b000000000_000;
        endcase
    end
endmodule

module AluDec (
    input [5 : 0] func, 
    input getalu, 
    input [2 : 0] aluop1, 
    output [2 : 0] aluop
);
    reg [2 : 0] funcop;
    assign aluop = getalu ? aluop1 : funcop;
    always@(*) begin
        case (func)
            //add
            6'b100000 : funcop = 3'b000;
            //sub
            6'b100010 : funcop = 3'b001;
            //addu
            6'b100001 : funcop = 3'b010;
            //and
            6'b100100 : funcop = 3'b011;
            //or
            6'b100101 : funcop = 3'b100;
            //slt
            6'b101010 : funcop = 3'b101;
            //nop
            default:  funcop = 3'b000;
        endcase
    end
endmodule


//CPU成品
/*(1)部件功能说明: 连接CPU所有部件。
(2)部件设计思路: 依照设计图，依次连接每个部件。
(3)部件会在单周期CPU的哪些地方能够用到: 连线其他部件，得到完整CPU。
*/
module CPU (
    input clk, pc_rst, mem_rst, reg_rst
);
    wire regrt, sext, wreg, aluimm, wmem, m2reg, jump, getalu, overflow;
    wire [31 : 0] nextPC, PC, P4, excimm, DI, q1, q2, alu2, result, data;
    wire [4 : 0] rs, rt, rd, ND;
    wire [15 : 0] imm;
    wire [5 : 0] op, func;
    wire [25 : 0] address;
    wire [27 : 0] addressl;
    wire [2 : 0] aluop;

    ProgramCounter pc(clk, pc_rst, nextPC, PC);
    InstMem instmem(PC, op, rs, rt, rd, address, imm, func);
    Controller controller(op, func, regrt, sext, wreg, aluimm, wmem, m2reg, jump, getalu, aluop);
    Ext ext(sext, imm, excimm);
    MUX_5 rt_or_rd(regrt, rt, rd, ND);
    RegFile regfile(clk, reg_rst, wreg & (~overflow), rs, rt, ND, DI, q1, q2);
    MUX_32 excimm_or_q2(aluimm, excimm, q2, alu2);
    ALU alu(q1, alu2, aluop, result, overflow);
    DataMemory mem(clk, mem_rst, wmem, result, q2, data);
    MUX_32 data_or_result(m2reg, data, result, DI);
    Adder adder(PC, 32'h00000004, P4);
    SL2 sl2(address, addressl);
    MUX_32 pcjump_or_P4(jump, {P4[31:28], addressl}, P4, nextPC);
endmodule




