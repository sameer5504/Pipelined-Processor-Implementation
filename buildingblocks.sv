// Register File: 15 Register 32-Bits
// Two Output Busses
// One Input Bus
// One Debug Port used for simulation and testbench
module registerFile(input clk, input RegWr, input  [3:0]  Ra, Rb, Rd, input [31:0] BusW, output reg [31:0] BusA, BusB, input [3:0] debugAddr, output [31:0] debugDataOut);
  reg [31:0] register[14:0];  // Register File using array, each cell is 32 bits wide.
	initial
      register[0] = 0;  // Set Register 0 to 0
  always @(posedge clk)  // When the CLK positive edge arrives.
    if (RegWr && Rd < 15)  // If Write is enabled, and register is in range then write to the register
      register[Rd] <= BusW ;
  assign BusA = (Ra <15) ? register[Ra] : 32'b0 ; // Read First Register
  assign BusB = (Rb <15) ? register[Rb] : 32'b0 ; // Read Second Register
  assign debugDataOut = (debugAddr < 15) ? register[debugAddr] : 32'b0;  // Debug Port
endmodule

// N-Bit Register with Reset
module regN #(parameter WIDTH = 32)
              (input clk, reset,
               input [WIDTH-1:0] d, 
               output reg [WIDTH-1:0] q);
  always @(negedge clk, posedge reset)  // When Negative or Positive CLK Edge arrives, Set Output to input, or reset.
    if (reset) q <= 0;
    else       q <= d;
endmodule

// ALU capable of Bitwise OR, Addition, Subtraction and Comparison
module alu(
  input  [31:0] A, 
  input  [31:0] B,
  input  [1:0]  ALUOp,
  output reg [31:0] ALURes
);
  always @(*) begin  // Always Compute the output based on the input
    case (ALUOp)
      2'b00: ALURes = A | B;  // Bitwise Or
      2'b01: ALURes = A + B;  // Addition
      2'b10: ALURes = A - B;  // Subtraction
      2'b11:  // Comparison
        begin
          if ( A[31] == 0 && B[31] == 1)
            ALURes = 32'd1;
          else if ( A[31] == 1 && B[31] == 0)
            ALURes = -32'd1;
        else if (A > B)
          ALURes = 32'd1;
        else if (A == B)
          ALURes = 32'd0;
        else
          ALURes = -32'd1;
        end
      default: ALURes =32'hXXXXXXXX;
    endcase
  end
endmodule

// 2 to 1 Multiplexer
module mux2 # (parameter WIDTH = 32)
(input [WIDTH-1:0] d0, d1,
input s,
output [WIDTH-1:0] y);
  assign y = s ? d1 : d0;  // Set the output to one of the inputs based on the selection line
endmodule

// 4-to-1 Multiplexer
module mux4 #(parameter WIDTH = 32)
             (input  [WIDTH-1:0] d0, d1, d2, d3,
              input  [1:0]       s, 
              output [WIDTH-1:0] y);
  assign y = s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0);   // Set the output to one of the inputs based on the selection line
endmodule

// Sign-Extender, extends from 14 bits to 32 based either sign or zero based on the extOP input
module signext
  (input  [13:0]Imm,
   input    extOP,
   output [31:0] y);
   assign y = extOP ? {{(18){Imm[13]}}, Imm} : {{(18){1'b0}}, Imm};
endmodule

// N-Bit Register with Reset and Enable
module regenN #(parameter WIDTH = 32)
  (input clk, reset,
   input en,
   input [WIDTH-1:0] d, 
   output reg [WIDTH-1:0] q);
  always @(negedge clk, posedge reset) // When Negative or Positive CLK Edge arrives, Set Output to input, or reset.
    if (reset) q <= 0;
  else if (en) q <= d;
endmodule

// Adds two 32 Bits Inputs and Outputs the result
module adder32Bit( input [31:0] A, B, output [31:0] Res);
  assign Res = A + B;
endmodule

// Data Memory - 64 Words Memory that reads and writes
module dmem(
  input clk, MemRd, MemWr,
  input [31:0] address,
  input [31:0] DataIn,
  output reg [31:0] Dataout );
  reg  [31:0] RAM[63:0];  // 64 Word Memory
	always @(negedge clk) 
      if (MemWr)  // If Memory Write is enabled
			begin
      			RAM[address] <= DataIn;
			end
	always @(posedge MemRd)
      if (MemRd)  // If Memory Read is enabled
			Dataout <= {RAM[address]} ; 		
endmodule

// Instruction Memory - 64 Words, that writes the content using a file, and can be used to read instructions
module imem (input [31:0] PC,
             output [31:0] Inst);
  reg [31:0] RAM[63:0];
  initial
    begin
      $readmemh ("memfile.dat",RAM);
	end
  assign Inst = RAM[PC]; // Word 32-Bits
endmodule