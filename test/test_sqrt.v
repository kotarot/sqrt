////////////////////////////////
// テストベンチ for SQRT.v
////////////////////////////////

`timescale 1ns/1ps

module SQRT_TB;

	reg         CLK, RST; // input
	reg  [15:0] DATA_IN;  // input (16bit)
	wire [15:0] DATA_OUT; // output (16bit)

	// クロック周期は 100ns にする
	parameter T_CLK = 100;

	// 回路モジュール
	SQRT SQRT(.CLK(CLK), .RST(RST), .DATA_IN(DATA_IN), .DATA_OUT(DATA_OUT));

	// クロックの初期化・生成
	initial CLK = 1;
	always #(T_CLK/2)
		CLK <= ~CLK;

	// おまじない (ダンプファイルの生成)
	initial begin
		$dumpfile("rtl.dump");
		$dumpvars(0, SQRT_TB);
	end

	// シミュレーション本体
	initial begin
		$display("\n\n");
		$display("################################");
		$display("## SQRT Test Bench ...");
		$display("################################");
		$display("\n");

		// ================================
		// 入力信号と回路の初期化
		RST <= 1;
		DATA_IN <= 16'b0000000000000000;

		// 3クロック分(立上がり換算)待機
		repeat(3) @(posedge CLK);

		#20 // 20ns待機(入力するタイミングをずらす)
		RST <= 0;  // リセット解除

		// 1クロック分(立下り換算)待機
		repeat(1) @(negedge CLK);

		// [テスト1] 4
		// sqrt(4) = 2.0 (10.0) が正解
		// 計算結果 5回ループ: 0000 0010.0000 1000 -> 2.03125
		DATA_IN <= 16'b0000010000000000;

		// 30クロック周期待機
		#(T_CLK*30)

		$display("[TEST 1]");
		$display("Input:  0000010000000000");
		$display("Expect: 0000001000000000");
		$display("Output: %b", DATA_OUT);
		$display("\n");


		// ================================
		// 入力信号と回路の初期化
		RST <= 1;
		DATA_IN <= 16'b0000000000000000;

		// 3クロック分(立上がり換算)待機
		repeat(3) @(posedge CLK);

		#20 // 20ns待機(入力するタイミングをずらす)
		RST <= 0;  // リセット解除

		// 1クロック分(立下り換算)待機
		repeat(1) @(negedge CLK);

		// [テスト2] 30
		// sqrt(30) = 約5.48 (101.01111010) が正解
		// 計算結果 5回ループ: 0000 0101.1111 1001 -> 5.97265625
		DATA_IN <= 16'b0001111000000000;

		// 30クロック周期待機
		#(T_CLK*30)

		$display("[TEST 2]");
		$display("Input:  0001111000000000");
		$display("Expect: 0000010101111010");
		$display("Output: %b", DATA_OUT);
		$display("\n");


		// ================================
		// 入力信号と回路の初期化
		RST <= 1;
		DATA_IN <= 16'b0000000000000000;

		// 3クロック分(立上がり換算)待機
		repeat(3) @(posedge CLK);

		#20 // 20ns待機(入力するタイミングをずらす)
		RST <= 0;  // リセット解除

		// 1クロック分(立下り換算)待機
		repeat(1) @(negedge CLK);
		// [テスト3] 100
		// sqrt(100) = 10.0 (1010.0) が正解
		// 計算結果 5回ループ: 0000 1010.0110 0010 -> 10.3828125
		DATA_IN <= 16'b0110010000000000;
		// 30クロック周期待機
		#(T_CLK*30)

		$display("[TEST 3]");
		$display("Input:  0110010000000000");
		$display("Expect: 0000101000000000");
		$display("Output: %b", DATA_OUT);
		$display("\n");


		$finish;
	end

endmodule
