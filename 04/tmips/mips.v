/*
 * From D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module mips(
    input  clk,
    input  reset,
    output [31:0] pc,
    input  [31:0] instr,
    output memwrite,
    output [31:0] aluout,
    output [31:0] writedata,
    input  [31:0] readdata
    );

   wire 	  memtoreg, branch, alusrc, regdst, regwrite, jump, zero;
   wire [1:0] 	  immtype;
 	  
   wire [3:0] 	  alucontrol;
	
   controller ctl(instr[31:26], instr[5:0], zero, memtoreg, memwrite, pcsrc,
		  alusrc, regdst, immtype, regwrite, jump, alucontrol);
   datapath dp(clk, reset, memtoreg, pcsrc, alusrc, regdst, immtype, regwrite,
	       jump, alucontrol, zero, pc, instr, aluout, writedata, readdata);
					
endmodule
