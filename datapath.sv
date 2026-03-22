// Datapath Connects components of each Step, with each other and with buffers connecting the stages

// Inputs : CLK, Reset

// Inputs from PC Control: PCSrc, DisablePC, Kill1

//Inputs from Main Control: WRegDst, RegDst, EX.RegWr, MEM.RegWr, WB.RegWr,ExtOp,EX.ALUSrc,EX.MemRd, MEM.MemRd,MEM.MemWr, MEM.WBdata

//Inputs from ALU Control: EX.ALUOp
//====

// Outputs: Opcode, RdLSB, CMPRes, Stall
module datapath( 
  input clk, reset,
  input [1:0]PCSrc,
  input DisablePC,
  input [1:0]Kill1,
  input WRegDst,RegDst,ExRegWr,MEMRegWr,WBRegWr,ExtOp,
  input [1:0]EXAluSrc,
  input EXMemRd,MEMMemRd,MEMMemWr,
  input [1:0]MEMWBData,
  input [1:0]ALUOp,
  output wire[5:0] Opcode,
  output wire RdLSB,
  output wire [1:0]CMPRes,
  output Stall,
  //Inputs/Outputs for testbench
  output [31:0] PC,
  output [31:0] IFIR,
  input [3:0] debugAddr,
  output [31:0] debugDataOut
);
//WIRES
  wire [31:0]MEMALURes;
  wire [31:0]DataIn;
  wire [31:0]MemDataOut;
  wire [31:0] RA2;
  wire [31:0] selectedOpB;
  wire [3:0] Rd2;
  wire [3:0] Rd3;
  wire [3:0] Rd1;
  wire [3:0] Rd4;
  wire [1:0] ForwardA;
  wire [1:0] ForwardB;
  wire [31:0] MUXTOPC;
  //wire [31:0] PC;
  wire [31:0] JTA;
  wire [31:0] BTA;
  wire [31:0] JRS;
  wire [31:0] IFNextPC;
  wire [31:0] SelectedInst;
  wire [31:0] DWInst;
  wire enablePC;
  wire enableIR;
  wire [31:0]IDIR;
  wire [3:0] IDRs;
  wire [3:0] IDRs2;
  wire [3:0] IDRd;
  wire [3:0] IDRt;
  wire [13:0] IDImm;
  wire [5:0] IDOP;
  wire [5:0] DWOP;
  wire [3:0] DWRD;
  wire [3:0] DWIM;
  wire [31:0] BusBOut; 
  wire [31:0] extRes;
  wire [31:0] IDNextPC;
  wire [31:0] BTARes;
  wire [31:0]EXALURes;
  wire [31:0]selectedWBData;
  wire [31:0]WBDataOut;
  wire [31:0]selectedAOut;
  wire [31:0]selectedBOut;
  wire [31:0] RA1;
  wire [31:0] operandB,operandImm, operandA;
  
// ForwardStall Module
  forwardStall forwardandstall(IDRs,IDRt,Rd2,Rd3,Rd4,WBRegWr,MEMRegWr,ExRegWr,EXMemRd,ForwardA,ForwardB,Stall);
  
// Fetch Logic  
  mux4 #(32) PCSelection(IFNextPC,JTA,BTA,JRS,PCSrc,MUXTOPC);
  assign enablePC = !DisablePC;
  regenN #(32) PCRegister(clk,reset,enablePC,MUXTOPC,PC);
  adder32Bit PcPlusOne(PC,32'H00000001,IFNextPC);
  imem IRMemory(PC,IFIR);
  mux4 #(32) IRMux(IFIR,32'H00000000,DWInst,32'H00000000,Kill1,SelectedInst);
  
// Buffers Between Instruction Fetch and Instruction Decode
  regN #(32) NPC(clk,reset,IFNextPC,IDNextPC);
  assign enableIR = !Stall;
  regenN #(32) IR(clk,reset,enableIR,SelectedInst,IDIR);
  
// Decode Logic
  assign IDOP = IDIR[31:26];
  assign Opcode = IDOP;
  assign IDRd = IDIR[25:22]; 
  assign RdLSB = IDRd[0];
  assign IDRt = IDIR[17:14];
  assign IDRs = IDIR[21:18];
  assign IDImm = IDIR[13:0];
  assign DWOP = IDOP - 6'b000010;
  assign DWRD = IDRd + 4'b0001;
  assign DWIM = IDImm + 4'b0001;
  assign DWInst = {DWOP,DWRD,IDRs,IDRt,DWIM};
  assign JTA = {IDNextPC[31:14],IDImm}; 
  mux2 #(4) MuxWriteReg(IDRd,4'HE,WRegDst,Rd1);
  mux2 #(4) MuxSourceReg(IDRt,IDRd,RegDst,IDRs2);
  registerFile regfile(clk,WBRegWr,IDRs,IDRs2,Rd4,WBDataOut,JRS,BusBOut,debugAddr,debugDataOut);
  signext extender(IDImm,ExtOp,extRes);
  adder32Bit PCPLUSIMM(IDNextPC,extRes,BTARes);
  mux4 #(32) forwardAMux(JRS,EXALURes,selectedWBData,WBDataOut,ForwardA,selectedAOut);
  mux4 #(32) forwardBMux(BusBOut,EXALURes,selectedWBData,WBDataOut,ForwardB,selectedBOut);
  
// Buffers Between Instruction Decode and Execution
  regN #(32) BTABuffer(clk,reset,BTARes,BTA);
  regN #(32) BusABuffer(clk,reset,selectedAOut,operandA);
  regN #(32) BusImmBuffer(clk,reset,extRes,operandImm);
  regN #(32) BusBBuffer(clk,reset,selectedBOut,operandB);
  regN #(4)  Rd2Buffer(clk,reset,Rd1,Rd2);
  regN #(32)  RA1Buffer(clk,reset,IDNextPC,RA1);
// Execution Logic
  alu ALUUNIT(operandA,selectedOpB,ALUOp,EXALURes);
  assign CMPRes = EXALURes[1:0];
  mux4 #(32) aluoperandbmux(operandImm,operandB,32'H00000000,32'H00000000,EXAluSrc,selectedOpB);
  
// Buffers Between Execution and Memory
  regN #(32) ALUResBuffer(clk,reset,EXALURes,MEMALURes);
  regN #(32) DataInBuffer(clk,reset,operandB,DataIn);
  regN #(4)  Rd3Buffer(clk,reset,Rd2,Rd3);
  regN #(32)  RA2Buffer(clk,reset,RA1,RA2);
  
// Memory Logic
  dmem DataMemory(clk,MEMMemRd,MEMMemWr,MEMALURes,DataIn,MemDataOut);
  mux4 #(32) wbdatamux(MEMALURes,MemDataOut,RA2,32'H00000000,MEMWBData,selectedWBData);
    
// Buffers Between Memory and Write-Back
  regN #(32) WBDataBuffer(clk,reset,selectedWBData,WBDataOut);
  regN #(4)  Rd4Buffer(clk,reset,Rd3,Rd4);
endmodule

// Forward & Stall Unit
// Inputs: Rs,Rt, WBRegWr, MEMRegWr, EXRegWr, Rd2, Rd3, Rd4, EXMemRd
// Outputs: Forward A, Forward B, Stall
module forwardStall(
  input [3:0] Rs, Rt, Rd2, Rd3, Rd4,
  input WBRegWr, MemRegWr, ExRegWr, ExMemRd,
  output reg [1:0] ForwardA, ForwardB,
  output reg Stall
);
  always @(*) begin
    // ForwardA logic
    if ((Rs == Rd2) && ExRegWr)
      ForwardA = 2'b01;
    else if ((Rs == Rd3) && MemRegWr) 
      ForwardA = 2'b10;
    else if ((Rs == Rd4) && WBRegWr)
      ForwardA = 2'b11;
    else
      ForwardA = 2'b00;
    // ForwardB logic
    if ((Rt == Rd2) && ExRegWr)
      ForwardB = 2'b01;
    else if ((Rt == Rd3) && MemRegWr) 
      ForwardB = 2'b10;
    else if ((Rt == Rd4) && WBRegWr)
      ForwardB = 2'b11;
    else
      ForwardB = 2'b00;
    // Stall logic
    if ((ExMemRd == 1'b1) && (ForwardA == 2'b01 || ForwardB == 2'b01))
      Stall = 1'b1;
    else
      Stall = 1'b0;
  end
endmodule