/*
 * From D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module maindec(
    input [5:0] op,
    output memtoreg,
    output memwrite,
    output branch,
    output alusrc,
    output regdst,
    output [1:0] immtype,
    output regwrite,
    output jump,
    output [2:0] aluop
    );

   reg [11:0] 	 controls;
	
   assign { regwrite, immtype, regdst, alusrc, branch, memwrite,
	    memtoreg, jump, aluop } = controls;
				
   always @ (*)
     case (op)
       6'b000000: controls <= 12'b100100000100; //Rtype
       6'b100011: controls <= 12'b100010010000; //LW
       6'b101011: controls <= 12'b000010100000; //SW
       6'b000100: controls <= 12'b000001000001; //BEQ
       6'b001000: controls <= 12'b100010000000; //ADDI
       6'b001111: controls <= 12'b110010000011; //LUI
       6'b001101: controls <= 12'b101010000011; //ORI
       6'b000010: controls <= 12'b000000001000; //J
       default:   controls <= 12'bxxxxxxxxxxxx; //???
     endcase

endmodule

module aludec(
    input [5:0] funct,
    input [2:0] aluop,
    output reg [3:0] alucontrol
    );

   always @ (*)
     case (aluop)
        3'b000: alucontrol <= 4'b0010; // addition
        3'b001: alucontrol <= 4'b0110; // subtraction
        3'b011: alucontrol <= 4'b0001; // or
        default: case (funct) // Rtype (aluop is 100)
          6'b100000: alucontrol <= 4'b0010; //ADD
          6'b100010: alucontrol <= 4'b0110; //SUB
          6'b100100: alucontrol <= 4'b0000; //AND
          6'b100101: alucontrol <= 4'b0001; //OR
          6'b101010: alucontrol <= 4'b0111; //SLT
          default:   alucontrol <= 4'bxxxx; //???
        endcase
     endcase
endmodule

module controller(
    input [5:0] op,
    input [5:0] funct,
    input zero,
    output memtoreg,
    output memwrite,
    output pcsrc,
    output alusrc,
    output regdst,
    output [1:0] immtype, 
    output regwrite,
    output jump,
    output [3:0] alucontrol
    );

   wire [2:0] 	 aluop;
   wire 	 branch;
	
   maindec md (op, memtoreg, memwrite, branch, alusrc,
	       regdst, immtype, regwrite, jump, aluop);
   aludec ad (funct, aluop, alucontrol);
	
   assign pcsrc = branch & zero;
endmodule

module testcont;
   reg [5:0] op;
   reg [5:0] funct;
   reg 	     zero;
   wire      memtoreg, memwrite, pcsrc, alusrc, regdst, regwrite, jump;
   wire [1:0] immtype;
   wire [3:0] alucontrol;

   controller ctl(op, funct, zero, memtoreg, memwrite, pcsrc,
		  alusrc, regdst, immtype, regwrite, jump, alucontrol);

   initial begin
      $dumpfile("testcont.vcd");
      $dumpvars(0, testcont);
      zero = 0; op = 0; funct = 'h20; #1
      op = 'h2b #1
      op = 'h04 #1
      op = 'h08 #1
      op = 'h02 #1
      $finish;
   end
endmodule // testcont
