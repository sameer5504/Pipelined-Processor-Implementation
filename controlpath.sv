// Define Opcodes for easier use
`define OR 6'b000000
`define ADD 6'b000001
`define SUB 6'b000010
`define CMP 6'b000011
`define ORI 6'b000100
`define ADDI 6'b000101
`define LW 6'b000110
`define SW 6'b000111
`define LDW 6'b001000
`define SDW 6'b001001
`define BZ 6'b001010
`define BGZ 6'b001011
`define BLZ 6'b001100
`define JR 6'b001101
`define J 6'b001110
`define CLL 6'b001111

// Control Path Module
module controller(input  clk, reset,
                  output [1:0] Pcsrc,
                  output DisablePc,
                  output [1:0] kill1,
                  output WRegDst, RegDst, 
                  output EXRegWr, MEMRegWr, WBRegWr,
                  output ExtOp,
                  output [1:0] EXALUSrc, 
                  output EXMemRd,MEMMemRd,MEMMemWr,
                  output [1:0]MEMWBData,
                  output [1:0]EXALUOp,
                  input  [5:0] Opcode,
                  input RdLSB,
                  input [1:0] CMPRes,
                  input Stall
                 );
  
  // Intermediate Wires
  wire [5:0]EXOpcode;
  wire [1:0] WBData, ALUSrc, ALUOp, EXWBData;
  wire RegWr, MemRd,RegWrS,MemWrS, MemWr,EXMemWr;
  
  // Modules
  MainControlUnit MCU(Opcode,RegDst,WRegDst,RegWr,ExtOp,MemRd,MemWr,ALUSrc,ALUOp,WBData);
  ALUControlUnit ACU(Opcode,ALUOp);
  PCControlUnit PCU(Opcode,EXOpcode,CMPRes,RdLSB,Pcsrc,kill1,kill2,DisablePc);
  
  //Bubble Insertion MUX
  wire bubble;
  assign bubble = Stall | kill2;
  mux2 #(2) insertBubble({MemWr,RegWr},2'b00,bubble,{MemWrS,RegWrS});
  
  // Pipelining Control Signals
  
  // Instruction Decode -> Execution Buffers
  //ALUSrc,ALUOp, Opcode, MemRd, MemWr, WBData , RegWr
  regN #(10) IDTOEX(clk,reset,{ALUSrc,ALUOp,Opcode},{EXALUSrc,EXALUOp,EXOpcode});
  regN #(4) IDTOMEM(clk,reset,{MemRd,MemWrS,WBData},{EXMemRd,EXMemWr,EXWBData});
  regN #(1) IDTOWB(clk,reset,RegWrS,EXRegWr);
  
  // Execution -> Memory Buffers  
  // MemRd, MemWr, WBData, RegWr
  regN #(4) EXTOMEM(clk,reset,{EXMemRd,EXMemWr,EXWBData},{MEMMemRd,MEMMemWr,MEMWBData});
  regN #(1) EXTOWB(clk,reset,EXRegWr,MEMRegWr);
  
  // Memory -> Write Back Buffers  
  // RegWr
  regN #(1) MEMTOWB(clk,reset,MEMRegWr,WBRegWr);	 
endmodule

// Main Control Unit
module MainControlUnit(input  [5:0] Opcode,
               output  RegDest,WRegDest, RegWr, ExtOp, MemRd, MemWr,
               output  [1:0] ALUSrc, ALUOp, WBdata);
  reg [9:0] Signals;
  assign {WRegDest, RegDest, RegWr,
          ExtOp, ALUSrc,
          MemRd, MemWr, WBdata} = Signals;
  always @(*)
    case({Opcode})  // Set Signals based on Opcode
      {`OR}: Signals <= 10'b001x010000; 
      {`ADD}: Signals <= 10'b001x010000; 
	  {`SUB}: Signals <= 10'b001x010000; 
	  {`CMP}: Signals <= 10'b001x010000; 
	  {`ORI}: Signals <= 10'b0x10000000; 
      {`ADDI}: Signals <= 10'b0x11000000; 
      {`LW}: Signals <= 10'b0111001001; 
      {`SW}: Signals <= 10'bx1010001xx; 
      {`LDW}: Signals <= 10'b0111001001; 
      {`SDW}: Signals <= 10'bx1010001xx; 
      {`BZ}: Signals <= 10'bxx011000xx; 
      {`BGZ}: Signals <= 10'bxx011000xx; 
      {`BLZ}: Signals <= 10'bxx011000xx; 
      {`JR}: Signals <= 10'bxx0xxx00xx;
      {`J}: Signals <= 10'bxx0xxx00xx;
      {`CLL}: Signals <= 10'b1x1xxx0010;
	  default: Signals <= 10'b0000000000; 
    endcase
endmodule

// ALU Control Unit
module ALUControlUnit(input	[5:0] Opcode,
				output reg	[1:0] ALUop);
  always @(*)
    case(Opcode)
      `OR: ALUop <= 2'b00; 
      `ADD: ALUop <= 2'b01;
	  `SUB: ALUop <= 2'b10;
	  `CMP: ALUop <= 2'b11;
	  `ORI: ALUop <= 2'b00;
	  `ADDI: ALUop <= 2'b01;
	  `LW: ALUop <= 2'b01;
	  `SW: ALUop <= 2'b01;
	  `LDW: ALUop <= 2'b01;
	  `SDW: ALUop <= 2'b01;
	  `BZ: ALUop <= 2'b11;
	  `BGZ: ALUop <= 2'b11;
	  `BLZ: ALUop <= 2'b11;
	  `JR: ALUop <= 2'bxx;
	  `J: ALUop <= 2'bxx;
	  `CLL: ALUop <= 2'bxx;
    endcase
endmodule

// PC Control Unit
module PCControlUnit (
    input  [5:0] Opcode, OpcodeEx,
    input  [1:0] CMPRes,
    input        RdLSB,
    output reg [1:0] Pcsrc,
    output reg [1:0] kill1,
    output reg       kill2,
    output reg       DisablePc
);
  always @(*) begin  // Conditional Logic for PC Control Generation
        if ( ((OpcodeEx == `BZ)   && (CMPRes == 2'b00)) ||
             ((OpcodeEx == `BLZ)  && (CMPRes == 2'b11)) ||
            ((OpcodeEx == `BGZ)  && (CMPRes == 2'b01)) ) begin  // Taken Branch
            Pcsrc     = 2'b10;
            kill1     = 2'b01;
            kill2     = 1'b1;
            DisablePc = 1'b0;
        end
    else if ((Opcode == `J) || (Opcode == `CLL)) begin  // Jump to Label
            Pcsrc     = 2'b01;
            kill1     = 2'b01;
            kill2     = 1'b0;
            DisablePc = 1'b0;
        end
    else if (Opcode == `JR) begin  // Jump to address in register
            Pcsrc     = 2'b11;
            kill1     = 2'b01;
            kill2     = 1'b0;
            DisablePc = 1'b0;
        end
    else if (((Opcode == `LDW) && (RdLSB == 1'b0)) || 
                 ((Opcode == `SDW) && (RdLSB == 1'b0))) begin  // Double Word Load/Store with even Rd 
            Pcsrc     = 2'b00;         
            kill1     = 2'b10;
            kill2     = 1'b0;
            DisablePc = 1'b1;
        end
    else if (((Opcode == `LDW) && (RdLSB == 1'b1)) || 
             ((Opcode == `SDW) && (RdLSB == 1'b1))) begin  // Double Word Load/Store with odd Rd
            Pcsrc     = 2'b00;
            kill1     = 2'b01;
            kill2     = 1'b1;
            DisablePc = 1'b0;
        end
    else begin  // Normal
            Pcsrc     = 2'b00;
            kill1     = 2'b00;
            kill2     = 1'b0;
            DisablePc = 1'b0;
        end
    end
endmodule