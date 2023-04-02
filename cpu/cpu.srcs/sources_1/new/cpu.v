`timescale 1ns / 1ps


//��������: ���������
/*(1)��������˵��: �����ֵnextPC����һ���ڵ�PC�����ڸ���PC��
(2)�������˼·: ��ģ�����Ҫ���и�ֵ������always���ͨ��ʱ���źŽ��д����������reset���ܣ���
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ���һ�����ڲ�����ָ���ַ��
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


//��������: ָ��洢��Ԫ
/*(1)��������˵��: ���ô洢��ָ��������ָ���ַ���з������õ�rs��rt��ָ����Ϣ��
(2)�������˼·: ��ȡPC��Чλ����ָ��RAM���ҵ���Ӧָ��ٽ�ָ���ȡ�ɲ�ͬ��Ϣ�����
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ����PC�õ�����ָ����Ϣ��
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

    //��ʼ��
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


//��������: �Ĵ�����Ԫ
/*(1)��������˵��: ����Ĵ����е�ַN1��N2��Ӧ��ֵQ1��Q2����д��ʹ��WE��Чʱ��ִ��д�������
(2)�������˼·: ����assign���Q1��Q2����ʱ���½���ͨ��if���������жϣ���������д�븳ֵ�����������reset���ܣ�
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ��ִ�мĴ����Ķ�ȡ��д����ʹ�á�
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


//��������: ALU���㵥Ԫ
/*(1)��������˵��: �������a��b���ݲ�����Ĳ�ͬ�������ͬ����������������������������жϡ�
(2)�������˼·: ����case���ڲ�ͬ�Ĳ�����ִ�в�ͬ���������ݶ�֧��ָ���Ҫ��ALU��������з��ŵļӼ����޷��ŵļӡ��롢��С�ڡ�
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ����ָ����Ϣ����ALU���㡣
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
            //�ӣ��ж������
            3'b000: begin
                result = a + b;
                sum = {a[31], a[31 : 0]} + {b[31], b[31 : 0]};
                if (sum[31] == sum[32]) overflow = 1'b0;
                else overflow = 1'b1;
            end
            //�����ж������
            3'b001: begin
                result = a - b;
                sub = {a[31], a[31 : 0]} - {b[31], b[31 : 0]};
                if (sub[31] == sub[32]) overflow = 1'b0;
                else overflow = 1'b1;
            end
            //�ӣ����ж������
            3'b010: begin
                result = a + b;
                overflow = 1'b0;
            end
            //��
            3'b011: begin
                result = a & b;
                overflow = 1'b0;
            end
            //��
            3'b100: begin
                result = a | b;
                overflow = 1'b0;
            end
            //С��
            3'b101: begin
                if (a < b) result = 32'h00000001;
                else result = 32'h00000000;
                overflow = 1'b0;
            end
        endcase
    end
endmodule


//��������: ���ݴ洢��Ԫ
/*(1)��������˵��: �������ݵĶ�ȡ��д�롣
(2)�������˼·: ����assign���rd����ʱ���½���ͨ��if���������жϣ���������д�븳ֵ�����������reset���ܣ�
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ��CPU�����ڶԴ����ݴ洢��Ԫ�Ĳ�����
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


//��������: ��������չ��Ԫ
/*(1)��������˵��: ��16bit����������Ϊ32bit����Ϊsign_extend��zero_extend���֡�
(2)�������˼·: ���ã�:�����������select�ж���չ���ͣ���������Ӧ������
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ������������λ����չ�������֮�������ȡ�
*/
module Ext (
    input select,
    input [15:0] imm,
    output [31:0] extend_i
);
    assign extend_i[15:0] = imm;
    assign extend_i[31:16] = select ? (imm[15] ? 16'hffff : 16'h0000) : 16'h0000;
endmodule


//��������: ѡ����
/*(1)��������˵��: ��a��b���������н���ѡ��
(2)�������˼·: ����?:�����������select�������ݵ�ѡ��
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ALU������B��ѡ����һ��PCֵ��ѡ��д��Ĵ������ݵ�ѡ��д���ַND��ѡ��
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


//��������: �޷��żӷ���
/*(1)��������˵��: ���a��b�ĺ͡�
(2)�������˼·: ֱ�������������������
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ����PC + 4��
*/
module Adder (
    input [31 : 0] a,
    input [31 : 0] b,
    output [31 : 0] sum
);
    assign sum = a + b;
endmodule


//��������: ������
/*(1)��������˵��: ����ֵa������λ��
(2)�������˼·: ����assignֱ����������
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: jumpָ��ʱ��address�Ĳ�����
*/
module SL2 (
    input [25 : 0] a,
    output [27 : 0] y
);
    assign y = {a, 2'b00};
endmodule


//���Ƶ�Ԫ
/*(1)��������˵��: ���ƻ����������ܵ�ʵ�֡�
(2)�������˼·: ͨ�����ͼ�ó����п����źţ������Ƶ�Ԫ�ֳ�������������������MainDec����op�õ���ALUop֮��Ŀ����źŵ�ֵ����AluDec����MainDec�еõ�����Ϣ��func�ۺϣ��õ�ALUop��
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: �����������������������ƻ����������ܵ�ʵ�֡�
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


//CPU��Ʒ
/*(1)��������˵��: ����CPU���в�����
(2)�������˼·: �������ͼ����������ÿ��������
(3)�������ڵ�����CPU����Щ�ط��ܹ��õ�: ���������������õ�����CPU��
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




