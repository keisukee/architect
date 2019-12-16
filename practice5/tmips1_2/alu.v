/*
 * From D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module alu(
    input [31:0] srca,
    input [31:0] srcb,
    input [3:0] alucontrol,
    output reg [31:0] aluout,
    output reg zero
    );

   always @ (*)
     begin
			case (alucontrol)
			  4'b0000: aluout <= srca & srcb;
			  4'b0001: aluout <= srca | srcb;
			  4'b0010: aluout <= srca + srcb;
			  4'b0110: aluout <= srca - srcb;
			  4'b0111: aluout <= (srca-srcb)>>31;
			endcase
			zero <= (srca == srcb) ? 1 : 0;
     end
	
endmodule




module alutest;

   reg [31:0] opa, opb;
   reg [3:0]  aluc;
   wire [31:0] res;
   wire        zero;
   
   alu alu1(opa, opb, aluc, res, zero);

   initial begin
      $dumpfile("alutest.vcd");
      $dumpvars(0, alutest);
      aluc = 2; #1
      opa = 3; opb = 1;   #1
      aluc = 6; opa = 4; opb = -2; #2
      $finish;
   end
   

endmodule // alutest

