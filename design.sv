`include "datapath.sv"
`include "controlpath.sv"
`include "buildingblocks.sv"

// CPU Module to connect data path with control path.
module cpu(input clk,reset,output [31:0]PC, IFIR, input [3:0]debugAddr, output [31:0] debugDataOut);
  wire [1:0]PCSrc;
  wire DisablePC;
  wire [1:0] Kill1;
  wire WRegDst,RegDst,ExRegWr,MemRegWr,WBRegWr,ExtOp;
  wire [1:0]EXAluSrc;
  wire EXMemRd,MEMMemRd,MEMMemWr;
  wire [1:0] MEMWBData,ALUOp;
  wire [5:0] Opcode;
  wire RdLSB;
  wire [1:0] CMPRes;
  wire Stall;
  datapath dp(clk,reset,PCSrc,DisablePC,Kill1,WRegDst,RegDst,
             ExRegWr,MemRegWr,WBRegWr,ExtOp,EXAluSrc,
             EXMemRd,MEMMemRd,MEMMemWr,MEMWBData,ALUOp,
              Opcode,RdLSB,CMPRes,Stall,PC,IFIR,debugAddr,debugDataOut);  // Data Path
  controller cr(clk,reset,PCSrc,DisablePC,Kill1,WRegDst,RegDst,
             ExRegWr,MemRegWr,WBRegWr,ExtOp,EXAluSrc,
             EXMemRd,MEMMemRd,MEMMemWr,MEMWBData,ALUOp,
                Opcode,RdLSB,CMPRes,Stall);  // Control Path
endmodule