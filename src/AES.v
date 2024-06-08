module AES(clk, rst, din, key, dout, o_valid);
  input clk, rst;
  input [127:0] din;  // Data input
  input [127:0] key;  // Key input
  output reg [127:0] dout; // Data output
  output reg o_valid; // Data output valid

  reg [3:0] round_byte_cnt; // shows which byte should be read 
  reg [3:0] round_step;  // which column is processed
  reg [9:0] round_cnt;  // which round we are in, out of 10 rounds + initial round
 
  reg [7:0] rcon;
  reg [127:0] rkey, d_next;
  wire [127:0] rkey_next;

  wire [7:0] byte_data;
  wire [7:0] sbox_out; 
  wire [7:0] mc_en;
  wire [31:0] mc_out;
  wire ctrl; 
  wire [7:0] sc_out;
  reg [16:0] out_cnt;

  KeyExpantion keyexpantion(rkey, rkey_next, rcon);
  SBox subbyte(byte_data, sbox_out);
  mixcolumn mxclmn(clk, mc_en, sbox_out, mc_out);
  serial_converter sc(clk, ctrl, mc_out, sc_out);
  

  assign byte_data = byte_select(round_byte_cnt, round_step);
  assign mc_en = (round_byte_cnt[0] == 1) ? 8'h00 : 8'hFF;
  assign ctrl = (round_byte_cnt[0] == 1) ? 1 : 0;

  always @(posedge clk or posedge rst)
  begin
      if(rst)
      begin
	out_cnt <= 17'b0_0000_0000_0000_0000;
	round_cnt <= 10'b0000_0000_01;
	round_byte_cnt <= 4'b0000;
	round_step <= 4'b0001;
      end
      else  
      begin       
        byte_assignment();
	out_cnt <= {out_cnt[15:0], out_cnt[16]};  
	round_byte_cnt <= {round_byte_cnt[2:0], round_byte_cnt[3]};

	if(round_byte_cnt == 0)
	begin
	   d_next <= din ^ key;
	end

	if(round_byte_cnt[3])
        begin
	    round_step <= {round_step[2:0], round_step[3]};
	      
        end 
	 
	if(out_cnt[16])
	begin
	    addRoundKey();
	    d_next <= dout;
	    out_cnt <= (round_cnt[8] == 1) ? 17'b0_0000_0000_0000_0001 : 17'b0_0000_0000_0000_0000; // check for last round
	    round_byte_cnt <= 4'b0001;
	    round_step <= 4'b0001;
	    round_cnt <= {round_cnt[8:0], round_cnt[9]};
	end
	else if(out_cnt == 0 && ctrl && round_step[1])
        begin  
	    out_cnt <= 17'b0_0000_0000_0000_0001;
        end
         

      end 
  end


  always @(posedge clk or posedge rst)
  begin
      if(rst) 
      begin
	o_valid <= 0;
        rkey <= 128'h0;
	rcon <= 8'h01;
      end
      else 
      begin
         if(round_byte_cnt == 0)
	 begin
	   round_byte_cnt <= 4'b0001;
	   rkey <= key;
	 end
         else if(out_cnt[1])
	 begin
	   rkey <= rkey_next;
	   rcon <= xtime(rcon);
	 end
      end
   end


   function [7:0] xtime;
      input [7:0] x;
      xtime = (x[7]==1'b0)? {x[6:0],1'b0} : {x[6:0],1'b0} ^ 8'h1B;
   endfunction


  always @(posedge clk or posedge rst)
  begin
      if(rst) 
	o_valid <= 0;
      else 
	o_valid <= out_cnt[16] && round_cnt[9];
   end


  task addRoundKey;
  begin
      dout = rkey ^ dout;
  end
  endtask

  task byte_assignment;
  begin
    case(out_cnt)
	17'b0_0000_0000_0000_0001:
	    dout[127-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0000_0000_0010:
	    dout[119-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0000_0000_0100:
	    dout[111-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0000_0000_1000:
	    dout[103-:8] = (round_cnt[9]) ? sbox_out : sc_out; 	
	17'b0_0000_0000_0001_0000:
	    dout[95-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0000_0010_0000:
	    dout[87-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0000_0100_0000:
	    dout[79-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0000_1000_0000:
	    dout[71-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0001_0000_0000:
	    dout[63-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0010_0000_0000:
	    dout[55-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_0100_0000_0000:
	    dout[47-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0000_1000_0000_0000:
	    dout[39-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0001_0000_0000_0000:
	    dout[31-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0010_0000_0000_0000:
	    dout[23-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_0100_0000_0000_0000:
	    dout[15-:8] = (round_cnt[9]) ? sbox_out : sc_out; 
	17'b0_1000_0000_0000_0000:
	    dout[7-:8] = (round_cnt[9]) ? sbox_out : sc_out; 

    endcase


  end
  endtask


  
  // shift rows ==> Load bytes in this order
  function [7:0] byte_select;
  input [3:0] round_byte_cnt;
  input [3:0] round_step;
  begin
    case(round_step)
      4'b0001:
      begin
        if(round_byte_cnt == 4'b0001)
  	  byte_select = d_next[127-:8]; 
	else if(round_byte_cnt == 4'b0010)
  	  byte_select = d_next[87-:8]; 
 	else if(round_byte_cnt == 4'b0100)
  	  byte_select = d_next[47-:8];  
	else if(round_byte_cnt == 4'b1000)
  	  byte_select = d_next[7-:8]; 
      end 

      4'b0010:
      begin
        if(round_byte_cnt == 4'b0001)
  	  byte_select = d_next[95-:8];
	else if(round_byte_cnt == 4'b0010)
  	  byte_select = d_next[55-:8];
 	else if(round_byte_cnt == 4'b0100)
  	  byte_select = d_next[15-:8];
	else if(round_byte_cnt == 4'b1000)
  	  byte_select = d_next[103-:8];

      end 

      4'b0100:
      begin
        if(round_byte_cnt == 4'b0001)
  	  byte_select = d_next[63-:8];
	else if(round_byte_cnt == 4'b0010)
  	  byte_select = d_next[23-:8];
 	else if(round_byte_cnt == 4'b0100)
  	  byte_select = d_next[111-:8];
	else if(round_byte_cnt == 4'b1000)
  	  byte_select = d_next[71-:8];
      end 

      4'b1000:
      begin
        if(round_byte_cnt == 4'b0001)
  	  byte_select = d_next[31-:8];
	else if(round_byte_cnt == 4'b0010)
  	  byte_select = d_next[119-:8];
 	else if(round_byte_cnt == 4'b0100)
  	  byte_select = d_next[79-:8];
	else if(round_byte_cnt == 4'b1000)
  	  byte_select = d_next[39-:8];

      end 

    endcase

  end
  endfunction
  

endmodule

module KeyExpantion (kin, kout, rcon);
    input [127:0] kin;
    output [127:0] kout;
    input [7:0] rcon;
    wire [31:0] ws, wr, w0, w1, w2, w3;
    SubBytes SB0({kin[23:16], kin[15:8], kin[7:0], kin[31:24]}, ws);
    assign wr = {(ws[31:24] ^ rcon), ws[23:0]};

    assign w0 = wr ^ kin[127:96];
    assign w1 = w0 ^ kin[95:64];
    assign w2 = w1 ^ kin[63:32];
    assign w3 = w2 ^ kin[31:0];

    assign kout = {w0, w1, w2, w3};

endmodule

module serial_converter(clk, ctrl, din, dout); // ctrl = 1 when mixcolumn output is ready
    input clk, ctrl;
    input [31:0] din;
    output reg [7:0] dout;

    reg [7:0] reg1, reg2, reg3;

    always@(posedge clk)
    begin
	dout <= (ctrl == 1) ? din[31-:8] : reg1;
	reg1 <= (ctrl == 1) ? din[23-:8] : reg2;
	reg2 <= (ctrl == 1) ? din[15-:8] : reg3;
	reg3 <= din[7-:8];


    end
    

endmodule

module mixcolumn(clk, en, din, dout);
    input clk;
    input [7:0] din;
    input [7:0] en;
    output [31:0] dout;
    
    reg [7:0] reg0, reg1, reg2, reg3;
    wire [7:0] din02, din03;
    
    assign din02 = {din[6:4], din[3] ^ din[7], din[2] ^ din[7] , din[1], din[0] ^ din[7], din[7]}; // {02} din 
    assign din03 = {din[7] ^ din[6], din[6] ^ din[5], din[5] ^ din[4], din[4] ^ din[3] ^ din[7], din[3] ^ din[2] ^ din[7] , din[2] ^ din[1], din[1] ^ din[0] ^ din[7], din[0] ^ din[7]}; // {03} din 

    always @ (posedge clk)
    begin
        reg0 <= din ^ (reg1 & en);
        reg1 <= din ^ (reg2 & en);
        reg2 <= din03 ^ (reg3 & en);
        reg3 <= din02 ^ (reg0 & en);
    end

    assign dout = {reg0, reg1, reg2, reg3};
    
endmodule

module SubBytes (input [31:0] i, output [31:0] o);
	SBox sbox0(i[31-:8], o[31-:8]);
	SBox sbox1(i[23-:8], o[23-:8]);
	SBox sbox2(i[15-:8], o[15-:8]);
	SBox sbox3(i[7-:8], o[7-:8]);

endmodule

module SBox (input [7:0] in, output reg [7:0] out);
	always @(*) begin
		case (in)
			8'h00: out=8'h63;
			8'h01: out=8'h7c;
			8'h02: out=8'h77;
			8'h03: out=8'h7b;
			8'h04: out=8'hf2;
			8'h05: out=8'h6b;
			8'h06: out=8'h6f;
			8'h07: out=8'hc5;
			8'h08: out=8'h30;
			8'h09: out=8'h01;
			8'h0a: out=8'h67;
			8'h0b: out=8'h2b;
			8'h0c: out=8'hfe;
			8'h0d: out=8'hd7;
			8'h0e: out=8'hab;
			8'h0f: out=8'h76;
			8'h10: out=8'hca;
			8'h11: out=8'h82;
			8'h12: out=8'hc9;
			8'h13: out=8'h7d;
			8'h14: out=8'hfa;
			8'h15: out=8'h59;
			8'h16: out=8'h47;
			8'h17: out=8'hf0;
			8'h18: out=8'had;
			8'h19: out=8'hd4;
			8'h1a: out=8'ha2;
			8'h1b: out=8'haf;
			8'h1c: out=8'h9c;
			8'h1d: out=8'ha4;
			8'h1e: out=8'h72;
			8'h1f: out=8'hc0;
			8'h20: out=8'hb7;
			8'h21: out=8'hfd;
			8'h22: out=8'h93;
			8'h23: out=8'h26;
			8'h24: out=8'h36;
			8'h25: out=8'h3f;
			8'h26: out=8'hf7;
			8'h27: out=8'hcc;
			8'h28: out=8'h34;
			8'h29: out=8'ha5;
			8'h2a: out=8'he5;
			8'h2b: out=8'hf1;
			8'h2c: out=8'h71;
			8'h2d: out=8'hd8;
			8'h2e: out=8'h31;
			8'h2f: out=8'h15;
			8'h30: out=8'h04;
			8'h31: out=8'hc7;
			8'h32: out=8'h23;
			8'h33: out=8'hc3;
			8'h34: out=8'h18;
			8'h35: out=8'h96;
			8'h36: out=8'h05;
			8'h37: out=8'h9a;
			8'h38: out=8'h07;
			8'h39: out=8'h12;
			8'h3a: out=8'h80;
			8'h3b: out=8'he2;
			8'h3c: out=8'heb;
			8'h3d: out=8'h27;
			8'h3e: out=8'hb2;
			8'h3f: out=8'h75;
			8'h40: out=8'h09;
			8'h41: out=8'h83;
			8'h42: out=8'h2c;
			8'h43: out=8'h1a;
			8'h44: out=8'h1b;
			8'h45: out=8'h6e;
			8'h46: out=8'h5a;
			8'h47: out=8'ha0;
			8'h48: out=8'h52;
			8'h49: out=8'h3b;
			8'h4a: out=8'hd6;
			8'h4b: out=8'hb3;
			8'h4c: out=8'h29;
			8'h4d: out=8'he3;
			8'h4e: out=8'h2f;
			8'h4f: out=8'h84;
			8'h50: out=8'h53;
			8'h51: out=8'hd1;
			8'h52: out=8'h00;
			8'h53: out=8'hed;
			8'h54: out=8'h20;
			8'h55: out=8'hfc;
			8'h56: out=8'hb1;
			8'h57: out=8'h5b;
			8'h58: out=8'h6a;
			8'h59: out=8'hcb;
			8'h5a: out=8'hbe;
			8'h5b: out=8'h39;
			8'h5c: out=8'h4a;
			8'h5d: out=8'h4c;
			8'h5e: out=8'h58;
			8'h5f: out=8'hcf;
			8'h60: out=8'hd0;
			8'h61: out=8'hef;
			8'h62: out=8'haa;
			8'h63: out=8'hfb;
			8'h64: out=8'h43;
			8'h65: out=8'h4d;
			8'h66: out=8'h33;
			8'h67: out=8'h85;
			8'h68: out=8'h45;
			8'h69: out=8'hf9;
			8'h6a: out=8'h02;
			8'h6b: out=8'h7f;
			8'h6c: out=8'h50;
			8'h6d: out=8'h3c;
			8'h6e: out=8'h9f;
			8'h6f: out=8'ha8;
			8'h70: out=8'h51;
			8'h71: out=8'ha3;
			8'h72: out=8'h40;
			8'h73: out=8'h8f;
			8'h74: out=8'h92;
			8'h75: out=8'h9d;
			8'h76: out=8'h38;
			8'h77: out=8'hf5;
			8'h78: out=8'hbc;
			8'h79: out=8'hb6;
			8'h7a: out=8'hda;
			8'h7b: out=8'h21;
			8'h7c: out=8'h10;
			8'h7d: out=8'hff;
			8'h7e: out=8'hf3;
			8'h7f: out=8'hd2;
			8'h80: out=8'hcd;
			8'h81: out=8'h0c;
			8'h82: out=8'h13;
			8'h83: out=8'hec;
			8'h84: out=8'h5f;
			8'h85: out=8'h97;
			8'h86: out=8'h44;
			8'h87: out=8'h17;
			8'h88: out=8'hc4;
			8'h89: out=8'ha7;
			8'h8a: out=8'h7e;
			8'h8b: out=8'h3d;
			8'h8c: out=8'h64;
			8'h8d: out=8'h5d;
			8'h8e: out=8'h19;
			8'h8f: out=8'h73;
			8'h90: out=8'h60;
			8'h91: out=8'h81;
			8'h92: out=8'h4f;
			8'h93: out=8'hdc;
			8'h94: out=8'h22;
			8'h95: out=8'h2a;
			8'h96: out=8'h90;
			8'h97: out=8'h88;
			8'h98: out=8'h46;
			8'h99: out=8'hee;
			8'h9a: out=8'hb8;
			8'h9b: out=8'h14;
			8'h9c: out=8'hde;
			8'h9d: out=8'h5e;
			8'h9e: out=8'h0b;
			8'h9f: out=8'hdb;
			8'ha0: out=8'he0;
			8'ha1: out=8'h32;
			8'ha2: out=8'h3a;
			8'ha3: out=8'h0a;
			8'ha4: out=8'h49;
			8'ha5: out=8'h06;
			8'ha6: out=8'h24;
			8'ha7: out=8'h5c;
			8'ha8: out=8'hc2;
			8'ha9: out=8'hd3;
			8'haa: out=8'hac;
			8'hab: out=8'h62;
			8'hac: out=8'h91;
			8'had: out=8'h95;
			8'hae: out=8'he4;
			8'haf: out=8'h79;
			8'hb0: out=8'he7;
			8'hb1: out=8'hc8;
			8'hb2: out=8'h37;
			8'hb3: out=8'h6d;
			8'hb4: out=8'h8d;
			8'hb5: out=8'hd5;
			8'hb6: out=8'h4e;
			8'hb7: out=8'ha9;
			8'hb8: out=8'h6c;
			8'hb9: out=8'h56;
			8'hba: out=8'hf4;
			8'hbb: out=8'hea;
			8'hbc: out=8'h65;
			8'hbd: out=8'h7a;
			8'hbe: out=8'hae;
			8'hbf: out=8'h08;
			8'hc0: out=8'hba;
			8'hc1: out=8'h78;
			8'hc2: out=8'h25;
			8'hc3: out=8'h2e;
			8'hc4: out=8'h1c;
			8'hc5: out=8'ha6;
			8'hc6: out=8'hb4;
			8'hc7: out=8'hc6;
			8'hc8: out=8'he8;
			8'hc9: out=8'hdd;
			8'hca: out=8'h74;
			8'hcb: out=8'h1f;
			8'hcc: out=8'h4b;
			8'hcd: out=8'hbd;
			8'hce: out=8'h8b;
			8'hcf: out=8'h8a;
			8'hd0: out=8'h70;
			8'hd1: out=8'h3e;
			8'hd2: out=8'hb5;
			8'hd3: out=8'h66;
			8'hd4: out=8'h48;
			8'hd5: out=8'h03;
			8'hd6: out=8'hf6;
			8'hd7: out=8'h0e;
			8'hd8: out=8'h61;
			8'hd9: out=8'h35;
			8'hda: out=8'h57;
			8'hdb: out=8'hb9;
			8'hdc: out=8'h86;
			8'hdd: out=8'hc1;
			8'hde: out=8'h1d;
			8'hdf: out=8'h9e;
			8'he0: out=8'he1;
			8'he1: out=8'hf8;
			8'he2: out=8'h98;
			8'he3: out=8'h11;
			8'he4: out=8'h69;
			8'he5: out=8'hd9;
			8'he6: out=8'h8e;
			8'he7: out=8'h94;
			8'he8: out=8'h9b;
			8'he9: out=8'h1e;
			8'hea: out=8'h87;
			8'heb: out=8'he9;
			8'hec: out=8'hce;
			8'hed: out=8'h55;
			8'hee: out=8'h28;
			8'hef: out=8'hdf;
			8'hf0: out=8'h8c;
			8'hf1: out=8'ha1;
			8'hf2: out=8'h89;
			8'hf3: out=8'h0d;
			8'hf4: out=8'hbf;
			8'hf5: out=8'he6;
			8'hf6: out=8'h42;
			8'hf7: out=8'h68;
			8'hf8: out=8'h41;
			8'hf9: out=8'h99;
			8'hfa: out=8'h2d;
			8'hfb: out=8'h0f;
			8'hfc: out=8'hb0;
			8'hfd: out=8'h54;
			8'hfe: out=8'hbb;
			8'hff: out=8'h16;
		endcase
	end
endmodule


