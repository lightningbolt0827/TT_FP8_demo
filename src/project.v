/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
parameter SIGN_BITS = 1,           // Sign bit count (always 1 for IEEE 754)
parameter EXP_BITS = 8,           // Number of exponent bits
parameter MANTISSA_BITS = 23,     // Number of mantissa bits
parameter BIAS = (1 << (EXP_BITS - 1)) - 1 // Bias for the exponent
)(
//input  [(SIGN_BITS + EXP_BITS + MANTISSA_BITS - 1):0] A, // Input operand A
//input  [(SIGN_BITS + EXP_BITS + MANTISSA_BITS - 1):0] B, // Input operand B
//output [(SIGN_BITS + EXP_BITS + MANTISSA_BITS - 1):0] P // Product
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

// Internal signals
wire [MANTISSA_BITS-1:0] Mout;
wire [EXP_BITS-1:0] Eout;
wire Sout;

wire [MANTISSA_BITS-1:0] Ma = A[MANTISSA_BITS-1:0];
wire [EXP_BITS-1:0] Ea = A[(MANTISSA_BITS + EXP_BITS - 1):MANTISSA_BITS];
wire Sa = A[(SIGN_BITS + EXP_BITS + MANTISSA_BITS - 1)];

wire [MANTISSA_BITS-1:0] Mb = B[MANTISSA_BITS-1:0];
wire [EXP_BITS-1:0] Eb = B[(MANTISSA_BITS + EXP_BITS - 1):MANTISSA_BITS];
wire Sb = B[(SIGN_BITS + EXP_BITS + MANTISSA_BITS - 1)];

assign Sout = Sa ^ Sb;

wire [MANTISSA_BITS:0] M1aout = Ma[MANTISSA_BITS-1] ? {2'b11, Ma[MANTISSA_BITS-1:1]} : {1'b0, Ma};
wire [MANTISSA_BITS:0] M1bout = Mb[MANTISSA_BITS-1] ? {2'b11, Mb[MANTISSA_BITS-1:1]} : {1'b0, Mb};
wire [MANTISSA_BITS:0] M1addout = M1aout + M1bout;

wire N1, N2, N3, Ce;
nand (N1, Ma[MANTISSA_BITS-1], Mb[MANTISSA_BITS-1]);
nor  (N2, Ma[MANTISSA_BITS-1], Mb[MANTISSA_BITS-1]);
or   (N3, N2, M1addout[MANTISSA_BITS]);
nand (Ce, N1, N3);

assign Eout = Ea + Eb - BIAS - Ce;
assign Mout = M1addout[MANTISSA_BITS] ? {M1addout[MANTISSA_BITS-2:0], 1'b0} : M1addout[MANTISSA_BITS-1:0];
assign P = {Sout, Eout, Mout};
  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
