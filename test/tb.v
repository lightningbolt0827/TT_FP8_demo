`default_nettype none
`timescale 1ns / 1ps

/* This testbench instantiates the module and provides wires 
   for interaction, driven/tested by the cocotb test.py script.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  wire [7:0] ui_in;
  wire [7:0] uio_in;
  reg [7:0] ui_in_reg;
  reg [7:0] uio_in_reg;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Power and ground connections for gate-level testing
  `ifdef GL_TEST
  supply1 VPWR; // Define VPWR as a logic '1'
  supply0 VGND; // Define VGND as a logic '0'
  `endif

  // Instantiate the module under test (Replace tt_um_lightFP8 with your module name)
  tt_um_lightFP8 user_project (
      `ifdef GL_TEST
      .VPWR(VPWR), // Power
      .VGND(VGND), // Ground
      `endif
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  // Assign values to the wire-type inout signals
  assign ui_in = ui_in_reg;
  assign uio_in = uio_in_reg;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  
  end

  // Stimulus generation
  initial begin
    rst_n = 0;  
    ui_in_reg = 8'b00000000;
    uio_in_reg = 8'b00000000;
    #10;
    rst_n = 1;  
    ui_in_reg = 8'b00000011; // 3
    uio_in_reg = 8'b00000010; // 2
    #20; 
    ui_in_reg = 8'b00000001; // 1
    uio_in_reg = 8'b00000100; // 4
    #20; 
    ui_in_reg = 8'b00000101; // 5
    uio_in_reg = 8'b00000011; // 3
    #20;
    ui_in_reg = 8'b00000111; // 7
    uio_in_reg = 8'b00000010; // 2
    #20;
    ui_in_reg = 8'b00000010; // 2
    uio_in_reg = 8'b00010000; // 16
    #20;
    ui_in_reg = 8'b00000001; // 1
    uio_in_reg = 8'b00000001; // 1
    #20;
    #10;
    $stop;
  end

  // Monitor the signals during simulation
  initial begin
    $monitor("Time=%0d | ui_in=%b, uio_in=%b | uo_out=%b", $time, ui_in, uio_in, uo_out);
  end

endmodule
