////////////////////////////////
// 平方根演算回路
//
// Ver. 1 - 乗/除算器を16bit幅
////////////////////////////////

// [扱うデータ]
// データ幅は16bit
// 固定小数点で表す (整数部 8bit，小数部 8bit)
// 符号なしとする
//
// [例]
// http://www2u.biglobe.ne.jp/~yuichi/rest/cardinal.html
// 0.89 --> 0.11100011 (16'b0000000011100011)
// 0.22 --> 0.00111000 (16'b0000000000111000)
// 0.0  --> 0.0        (16'b0000000000000000)
// 1.0  --> 1.0        (16'b0000000100000000)
// 2.0  --> 10.0       (16'b0000001000000000)
// 3.0  --> 11.0       (16'b0000001100000000)
// 4.0  --> 100.0      (16'b0000010000000000)
// 5.0  --> 101.0      (16'b0000010100000000)
// 30.0 --> 11110.0    (16'b0001111000000000)

module SQRT(
	CLK, RST,
	DATA_IN,
	DATA_OUT
);

input			CLK, RST;
input [15:0]	DATA_IN;
output [15:0]	DATA_OUT;

wire			SEL_REG_0;
wire [1:0]		SEL_REG_1;
wire [1:0]		SEL_REG_2;
wire [1:0]		SEL_REG_3;

wire [1:0]		SEL_ADD_0;
wire [1:0]		SEL_ADD_1;

wire			CTRL;


DATAPATH DATAPATH(
	// Inputs
	CLK, RST,
	DATA_IN,
	SEL_REG_0,
	SEL_REG_1,
	SEL_REG_2,
	SEL_REG_3,
	SEL_ADD_0,
	SEL_ADD_1,
	// Outputs
	CTRL,
	DATA_OUT
);

CONTROLLER CONTROLLER(
	// Inputs
	CLK, RST,
	CTRL,
	// Outputs
	SEL_REG_0,
	SEL_REG_1,
	SEL_REG_2,
	SEL_REG_3,
	SEL_ADD_0,
	SEL_ADD_1
);

endmodule


////////////////////////////////
// Module: データパス
////////////////////////////////
module DATAPATH(
	CLK, RST, // クロックリセット
	DATA_IN,  // 入力データ

	IN_SEL_REG_0,  // レジスタ(#0)の入力側 MUX 選択信号
	IN_SEL_REG_1,  // レジスタ(#1)の入力側 MUX 選択信号
	IN_SEL_REG_2,  // レジスタ(#2)の入力側 MUX 選択信号
	IN_SEL_REG_3,  // レジスタ(#3)の入力側 MUX 選択信号

	IN_SEL_ADD_0, // 加算器の入力側ポート(左) MUX 選択信号
	IN_SEL_ADD_1, // 加算器の入力側ポート(右) MUX 選択信号

	CTRL, // コントロール信号 (比較器の結果)
	DATA_OUT  // 出力データ
);

input			CLK, RST;
input [15:0]	DATA_IN;

input			IN_SEL_REG_0;
input [1:0]		IN_SEL_REG_1;
input [1:0]		IN_SEL_REG_2;
input [1:0]		IN_SEL_REG_3;

input [1:0]		IN_SEL_ADD_0;
input [1:0]		IN_SEL_ADD_1;

output			CTRL;
output [15:0]	DATA_OUT;

// Registers
reg [15:0]		REG_0, REG_1, REG_2, REG_3;

// Wires
wire [15:0]		DATA_IN_MUL_0, DATA_IN_MUL_1, DATA_OUT_MUL;
wire [15:0]		DATA_IN_DIV_0, DATA_IN_DIV_1, DATA_OUT_DIV;
wire [15:0]		DATA_IN_ADD_0, DATA_IN_ADD_1, DATA_OUT_ADD;
wire [15:0]		DATA_IN_CMP_0, DATA_IN_CMP_1;
wire [15:0]		DATA_IN_SHIFT, DATA_OUT_SHIFT;


// -------------------------------- //
// Registers動作
// -------------------------------- //
always @(posedge CLK or posedge RST)
begin
	if(RST) begin
		REG_0 <= 16'd0;
		REG_1 <= 16'd0;
		REG_2 <= 16'd0;
		REG_3 <= 16'd0;
	end else begin
		REG_0 <= MUX_2_TO_1(DATA_IN, REG_0, IN_SEL_REG_0);
		REG_1 <= MUX_4_TO_1(REG_1, DATA_OUT_ADD, DATA_OUT_DIV, DATA_OUT_SHIFT, IN_SEL_REG_1);
		REG_2 <= MUX_3_TO_1(REG_1, DATA_OUT_MUL, DATA_OUT_ADD, IN_SEL_REG_2);
		REG_3 <= MUX_3_TO_1(16'b0000000000000000, REG_3, DATA_OUT_ADD, IN_SEL_REG_3);
	end
end


// -------------------------------- //
// FU's input
// -------------------------------- //

// 乗算器
assign DATA_IN_MUL_0 = 16'b0000000011100011; // これは 0.89
assign DATA_IN_MUL_1 = REG_0;
// 除算器
assign DATA_IN_DIV_0 = REG_0;
assign DATA_IN_DIV_1 = REG_1;
// 加算器
assign DATA_IN_ADD_0 = MUX_3_TO_1(16'b0000000000111000, 16'b0000000100000000, REG_2, IN_SEL_ADD_0); // これは 0.22 と 1
assign DATA_IN_ADD_1 = MUX_3_TO_1(REG_1, REG_2, REG_3, IN_SEL_ADD_1);
// 比較器
assign DATA_IN_CMP_0 = REG_3;
assign DATA_IN_CMP_1 = 16'b0000010100000000; // これは 5 (ループ回数 を指定する)
// シフト演算器
assign DATA_IN_SHIFT = REG_2;


// MUX (2-to-1) 選択信号は1bit
function [15:0] MUX_2_TO_1;
input [15:0]    IN_0;
input [15:0]    IN_1;
input           IN_SEL;
reg [15:0]      ANSWER;
begin
	if(IN_SEL==0)
		ANSWER = IN_0;
	else if(IN_SEL==1)
		ANSWER = IN_1;
	else
		ANSWER = 16'bxxxxxxxxxxxxxxxx;
	MUX_2_TO_1 = ANSWER;
end
endfunction

// MUX (3-to-1) 選択信号は2bit
function [15:0] MUX_3_TO_1;
input [15:0]    IN_0;
input [15:0]    IN_1;
input [15:0]    IN_2;
input [1:0]     IN_SEL;
reg [15:0]      ANSWER;
begin
	if(IN_SEL==0)
		ANSWER = IN_0;
	else if(IN_SEL==1)
		ANSWER = IN_1;
	else if(IN_SEL==2)
		ANSWER = IN_2;
	else
		ANSWER = 16'bxxxxxxxxxxxxxxxx;
	MUX_3_TO_1 = ANSWER;
end
endfunction

// MUX (4-to-1) 選択信号は2bit
function [15:0] MUX_4_TO_1;
input [15:0]    IN_0;
input [15:0]    IN_1;
input [15:0]    IN_2;
input [15:0]    IN_3;
input [1:0]     IN_SEL;
reg [15:0]      ANSWER;
begin
	if(IN_SEL==0)
		ANSWER = IN_0;
	else if(IN_SEL==1)
		ANSWER = IN_1;
	else if(IN_SEL==2)
		ANSWER = IN_2;
	else if(IN_SEL==3)
		ANSWER = IN_3;
	else
		ANSWER = 16'bxxxxxxxxxxxxxxxx;
	MUX_4_TO_1 = ANSWER;
end
endfunction


// -------------------------------- //
// FU's output
// -------------------------------- //

ADDER ADDER(DATA_IN_ADD_0, DATA_IN_ADD_1, DATA_OUT_ADD);
MULTIPLIER MULTIPLIER(DATA_IN_MUL_0, DATA_IN_MUL_1, DATA_OUT_MUL);
DIVIDER DIVIDER(DATA_IN_DIV_0, DATA_IN_DIV_1, DATA_OUT_DIV);
COMPARATOR COMPARATOR(DATA_IN_CMP_0, DATA_IN_CMP_1, CTRL);
SHIFTER SHIFTER(DATA_IN_SHIFT, DATA_OUT_SHIFT);

assign DATA_OUT = REG_1;

endmodule


////////////////////////////////
// Module: 演算器 - 加算器
////////////////////////////////
module ADDER(A, B, Y);
	input [15:0] A;
	input [15:0] B;
	output [15:0] Y;

	// 固定小数点の加算は整数と同じ
	// http://azskyetc.client.jp/paintprog/004_fixedarith.html
	assign Y = A + B;
endmodule

////////////////////////////////
// Module: 演算器 - 乗算器
////////////////////////////////
module MULTIPLIER(A, B, Y);
	input [15:0] A;
	input [15:0] B;
	output [15:0] Y;

	// 小数点以下の下位4bitを捨てて有効な部分を12bitにする
	// 乗算結果の小数部分のビット幅は、乗算前の小数部分のビットの和になる
	assign Y = {4'b0000, A[15:4]} * {4'b0000, B[15:4]};
endmodule

////////////////////////////////
// Module: 演算器 - 除算器
////////////////////////////////
module DIVIDER(A, B, Y);
	input [15:0] A;
	input [15:0] B;
	wire [23:0] T1, T2;
	output [15:0] Y;

	// 除算結果の小数部分のビット幅は、除算前の小数部分のビットの差になる？
	assign Y = A / {8'b00000000, B[15:8]};
endmodule

////////////////////////////////
// Module: 演算器 - 比較器
////////////////////////////////
module COMPARATOR(A, B, Y);
	input [15:0] A;
	input [15:0] B;
	output Y;

	assign Y = A < B;
	//always @(A or B) begin
	//	if (A < B)
	//		assign Y = 1'b1;
	//	else
	//		assign Y = 1'b0;
	//end
endmodule

////////////////////////////////
// Module: 演算器 - 1bit論理右シフト演算器
////////////////////////////////
module SHIFTER(A, Y);
	input [15:0] A;
	output [15:0] Y;

	assign Y = {1'b0, A[15:1]};
endmodule


////////////////////////////////
// Module: コントローラ
////////////////////////////////
module CONTROLLER(
	CLK, RST,
	CTRL,
	OUT_SEL_REG_0,
	OUT_SEL_REG_1,
	OUT_SEL_REG_2,
	OUT_SEL_REG_3,
	OUT_SEL_ADD_0,
	OUT_SEL_ADD_1
);

input			CLK, RST;
input			CTRL;
output			OUT_SEL_REG_0;
output [1:0]	OUT_SEL_REG_1;
output [1:0]	OUT_SEL_REG_2;
output [1:0]	OUT_SEL_REG_3;
output [1:0]	OUT_SEL_ADD_0;
output [1:0]	OUT_SEL_ADD_1;

reg		S0, S1, S2, S3, S4, S5, S6;

// state transition control
always @( posedge CLK or posedge RST ) begin
	if( RST )
		{S0, S1, S2, S3, S4, S5, S6} <= 7'b1000000;
	else begin
		if(S0) begin
			S0 <= 1'b0; S1 <= 1'b1;
		end else if(S1) begin
			S1 <= 1'b0; S2 <= 1'b1;
		end else if(S2) begin
			S2 <= 1'b0; S3 <= 1'b1;
		end else if(S3) begin
			S3 <= 1'b0; S4 <= 1'b1;
		end else if(S4) begin
			S4 <= 1'b0; S5 <= 1'b1;
		end else if(S5) begin
			S5 <= 1'b0;
			if(CTRL)
				S3 <= 1'b1;
			else
				S6 <= 1'b1;
		end else if(S6)
			S6 <= 1'b1;
		else begin
			{S0, S1, S2, S3, S4, S5, S6} <= 7'b1000000;
		end
	end
end

assign OUT_SEL_REG_0 = GET_SEL_REG_0(S0, S1, S2, S3, S4, S5, S6);
assign OUT_SEL_REG_1 = GET_SEL_REG_1(S0, S1, S2, S3, S4, S5, S6);
assign OUT_SEL_REG_2 = GET_SEL_REG_2(S0, S1, S2, S3, S4, S5, S6);
assign OUT_SEL_REG_3 = GET_SEL_REG_3(S0, S1, S2, S3, S4, S5, S6);
assign OUT_SEL_ADD_0 = GET_SEL_ADD_0(S0, S1, S2, S3, S4, S5, S6);
assign OUT_SEL_ADD_1 = GET_SEL_ADD_1(S0, S1, S2, S3, S4, S5, S6);

// character detection logic
function GET_SEL_REG_0;
	input	S0, S1, S2, S3, S4, S5, S6;
	reg		ANSWER;
	begin
		if(S0)
			ANSWER = 1'b0;
		else if(S1)
			ANSWER = 1'b1;
		else if(S2)
			ANSWER = 1'b1;
		else if(S3)
			ANSWER = 1'b1;
		else if(S4)
			ANSWER = 1'b1;
		else if(S5)
			ANSWER = 1'b1;
		else if(S6)
			ANSWER = 1'bx;
		else
			ANSWER = 1'bx;
		GET_SEL_REG_0 = ANSWER;
	end
endfunction

function [1:0] GET_SEL_REG_1;
	input		S0, S1, S2, S3, S4, S5, S6;
	reg [1:0]	ANSWER;
	begin
		if(S0)
			ANSWER = 2'bxx;
		else if(S1)
			ANSWER = 2'bxx;
		else if(S2)
			ANSWER = 2'b01;
		else if(S3)
			ANSWER = 2'b10;
		else if(S4)
			ANSWER = 2'bxx;
		else if(S5)
			ANSWER = 2'b11;
		else if(S6)
			ANSWER = 2'b00;
		else
			ANSWER = 2'bxx;
		GET_SEL_REG_1 = ANSWER;
	end
endfunction

function [1:0] GET_SEL_REG_2;
	input		S0, S1, S2, S3, S4, S5, S6;
	reg [1:0]	ANSWER;
	begin
		if(S0)
			ANSWER = 2'bxx;
		else if(S1)
			ANSWER = 2'b01;
		else if(S2)
			ANSWER = 2'bxx;
		else if(S3)
			ANSWER = 2'b00;
		else if(S4)
			ANSWER = 2'b10;
		else if(S5)
			ANSWER = 2'bxx;
		else if(S6)
			ANSWER = 2'bxx;
		else
			ANSWER = 2'bxx;
		GET_SEL_REG_2 = ANSWER;
	end
endfunction

function [1:0] GET_SEL_REG_3;
	input		S0, S1, S2, S3, S4, S5, S6;
	reg [1:0]	ANSWER;
	begin
		if(S0)
			ANSWER = 2'bxx;
		else if(S1)
			ANSWER = 2'bxx;
		else if(S2)
			ANSWER = 2'b00;
		else if(S3)
			ANSWER = 2'b10;
		else if(S4)
			ANSWER = 2'b01;
		else if(S5)
			ANSWER = 2'b01;
		else if(S6)
			ANSWER = 2'bxx;
		else
			ANSWER = 2'bxx;
		GET_SEL_REG_3 = ANSWER;
	end
endfunction

function [1:0] GET_SEL_ADD_0;
	input		S0, S1, S2, S3, S4, S5, S6;
	reg [1:0]	ANSWER;
	begin
		if(S0)
			ANSWER = 2'bxx;
		else if(S1)
			ANSWER = 2'bxx;
		else if(S2)
			ANSWER = 2'b00;
		else if(S3)
			ANSWER = 2'b01;
		else if(S4)
			ANSWER = 2'b10;
		else if(S5)
			ANSWER = 2'bxx;
		else if(S6)
			ANSWER = 2'bxx;
		else
			ANSWER = 2'bxx;
		GET_SEL_ADD_0 = ANSWER;
	end
endfunction

function [1:0] GET_SEL_ADD_1;
	input		S0, S1, S2, S3, S4, S5, S6;
	reg [1:0]	ANSWER;
	begin
		if(S0)
			ANSWER = 2'bxx;
		else if(S1)
			ANSWER = 2'bxx;
		else if(S2)
			ANSWER = 2'b01;
		else if(S3)
			ANSWER = 2'b10;
		else if(S4)
			ANSWER = 2'b00;
		else if(S5)
			ANSWER = 2'bxx;
		else if(S6)
			ANSWER = 2'bxx;
		else
			ANSWER = 2'bxx;
		GET_SEL_ADD_1 = ANSWER;
	end
endfunction

endmodule
