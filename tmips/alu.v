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
     4'b1100: aluout <= ~(srca | srcb);
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
   11
   alu alu1(opa, opb, aluc, res, zero);

   initial begin
      $dumpfile("alutest.vcd");
      $dumpvars(0, alutest);

      opa = 3; opb = -6; aluc = 0; #1
      aluc = 1; #1
      aluc = 2; #1
      aluc = 6; #1
      aluc = 7; #1
      aluc = 12; #1
      $finish;
   end
   

endmodule // alutest