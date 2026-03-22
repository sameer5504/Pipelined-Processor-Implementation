module testbench;
  reg clk, reset;
  reg [3:0] debugAddr;
  wire [31:0] debugDataOut;
  wire [31:0] PC, IFIR;
  cpu cpuTest(clk, reset, PC, IFIR, debugAddr, debugDataOut);
  initial begin  // Initialize signals
    clk = 0;
    reset = 1;
    debugAddr = 4'd0;
    #20 reset = 0;  // Turn Off Reset
  end

  always begin  // Start Clock
    @(negedge reset);
    forever begin
      #10 clk = ~clk;
    end
  end

  always @(posedge clk) begin  // After Completion, Check Register Content
      begin
      #1000;
      debugAddr <= 4'd2;
        #5
        if (debugDataOut === 32'h00000002) begin
          $display("PASS: Register %d = %h - Forwarded Correctly ",debugAddr, debugDataOut);
      end
      else
        $display("FAIL: Register %d = %h -Not Forwarded Correctly (expected 0x00000002)",debugAddr ,debugDataOut);
        
      $stop;
    end
  end
  
  initial begin  // Generate Waveforms
    $dumpfile("waveform.vcd");
    $dumpvars(0, testbench);
  end
  
endmodule