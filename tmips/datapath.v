/*
 * From D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module adder(
    input  [31:0] a, b,
    output [31:0] y);

   assign y = a + b;
endmodule

module sl2 (
    input  [31:0] a,
    output [31:0] y);
				
   assign y = {a[29:00], 2'b00};
endmodule

module signext (
    input  [15:0] a,
    output [31:0] y);
					
   assign y = {{16{a[15]}}, a};
endmodule

module zeroext (
    input  [15:0] a,
    output [31:0] y);
					
   assign y = {16'b0, a};
endmodule

module sethi (
    input  [15:0] a,
    output [31:0] y);
					
   assign y = {a, 16'b0};
endmodule

// immtype:
//  - 00 signext
//  - 01 zeroext
//  - 10 sethi
module immext (
    input  [1:0] immtype,
    input  [15:0] a,
    output [31:0] y);

   wire [31:0] ysignext;
   wire [31:0] yzeroext;
   wire [31:0] ysethi;

   signext  se(a, ysignext);
   zeroext  ze(a, yzeroext);
   sethi    sh(a, ysethi);

   assign y = immtype[1] ? ysethi
	      : (immtype[0] ? yzeroext : ysignext);
   
endmodule

module flopr # (parameter WIDTH = 8)
   (input	clk, reset,
    input	[WIDTH-1:0] d,
    output reg [WIDTH-1:0]  q);
					
   always @ (posedge clk, posedge reset)
     if (reset) q <= 0;
     else	q <= d;
endmodule

module mux2 # (parameter WIDTH = 8)
   (input  [WIDTH-1:0] d0, d1,
    input  s,
    output [WIDTH-1:0] y);
				
   assign y = s ? d1 : d0;
endmodule

module regfile(
    input clk,
    input we3,
    input [4:0] ra1,
    input [4:0] ra2,
    input [4:0] wa3,
    input [31:0] wd3,
    output [31:0] rd1,
    output [31:0] rd2
    );

   reg [31:0] 	  rf[31:0];
	
   // 3-port register file
   always @ (posedge clk)
     if (we3) rf[wa3] <= wd3;
		
   assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
   assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule

module datapath(
    input  clk,
    input  reset,
    input  memtoreg,
    input  pcsrc,
    input  alusrc,
    input  regdst,
    input  [1:0] immtype,
    input  regwrite,
    input  jump,
    input  [3:0] alucontrol,
    output zero,
    output [31:0] pc,
    input  [31:0] instr,
    output [31:0] aluout,
    output [31:0] writedata,
    input  [31:0] readdata
    );

   wire [4:0] 	 writereg;
   wire [31:0] 	 pcnext, pcnextbr, pcplus4, pcbranch;
   wire [31:0] 	 immextv, signimmsh;
   wire [31:0] 	 srca, srcb;
   wire [31:0] 	 result;
	
   // for next PC
   flopr #(32)	pcreg(clk, reset, pcnext, pc);
   adder	pcadd1 (pc, 32'b100, pcplus4);
   sl2		immsh(immextv, signimmsh);
   adder	pcadd2(pcplus4, signimmsh, pcbranch);
   mux2 #(32)   pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
   mux2 #(32)   pcmux(pcnextbr, {pcplus4[31:28], instr[25:0], 2'b00},
		      jump, pcnext);
							
   // reg-file logic
   regfile	rf(clk, regwrite, instr[25:21], instr[20:16], writereg,
		   result, srca, writedata);
   mux2 #(5)	wrmux(instr[20:16], instr[15:11], regdst, writereg);
   mux2 #(32)	resmux(aluout, readdata, memtoreg, result);
   immext	ie(immtype, instr[15:0], immextv);
	
   // ALU logic
   mux2 #(32) srcbmux(writedata, immextv, alusrc, srcb);
   alu alu(srca, srcb, alucontrol, aluout, zero);
endmodule
