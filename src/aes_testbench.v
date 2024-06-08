module aes_testbench;

	reg rst;
    	reg clk;
    	reg [127:0] key_in;
    	reg [127:0] d_in, correctData;
    	wire [127:0] d_out;
    	wire d_vld;
    	parameter CP = 20;

	integer keyFid, keyI, rxFid, rxI, txFid, txI;
	localparam total = 10;
	integer correct = 0;
	real point;
	
	AES test (clk, rst, d_in, key_in, d_out, d_vld);
	
	always #(CP/2) clk = ~clk;

	initial begin
		clk = 0;
		/*rst = 1;
		#(1.6*`period);
		rst = 0;*/
	end


	initial begin
		rxFid = $fopen ("plaintext.txt", "r");
		for (rxI = 0; rxI < total; rxI = rxI + 1) begin
			rst = 1;
			# 10;
			rst = 0;
			$fscanf (rxFid, "%h", d_in);
			wait(d_vld);
			# 10;
				
		end
		
	end

	

	initial begin
		keyFid = $fopen ("key.txt", "r");
		for (keyI = 0; keyI < total; keyI = keyI + 1) begin
			# 10;
			$fscanf (keyFid, "%h", key_in);
			wait(d_vld);
			# 10;
			
		end
	end

	initial begin
		txFid = $fopen ("ciphertext.txt", "r");
		for (txI = 0; txI < total; txI = txI + 1) begin
			wait(d_vld);
			rst = 1;
			# 10;
			rst = 0;
			$fscanf (txFid, "%h", correctData);				
			if (d_out == correctData)
			begin
			       $display ("Passed");
			       correct = correct + 1;
			end
			if(txI == total - 1)
			begin
				point = correct * 100 / total;
				$display ("grade: %f", point);
				$finish;
			end
			
		end
		
		
		
	end

endmodule

