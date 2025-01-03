/*
 * Couo_outyright (c) 2024 Your Nui_inme
 * Suo_outDX-License-Identifier: Apache-2.0
 */

`default_nettype none
module tt_um_lightFP8 #(
parameter SIGN_BITS = 1,           // Sign bit count (always 1 for IEEE 754)
parameter EXP_BITS = 4,           // Number of exponent bits
parameter MANTISSA_BITS = 3,     // Number of mantissa bits
parameter BIAS = (1 << (EXP_BITS - 1)) - 1 // Bias for the exponent
)(
        input wire [7:0] ui_in, // Input operand ui_in
        output wire [7:0] uo_out // Product
        input wire [7:0] uio_in, // Input operand uio_in
        output wire [7:0] uio_out,  // IOs: Output path
        output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
        input  wire       ena,      // always 1 when the design is powered, so you can ignore it
        input  wire       clk,      // clock
        input  wire       rst_n     // reset_n - low to reset
        
);
// All output pins must be assigned. If not used, assign to 0.
//assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
assign uio_out = 0;
assign uio_oe  = 0;

// List all unused inputs to prevent warnings
wire _unused = &{ena, clk, rst_n, 1'b0};
    
        
// Internal signals
wire [MANTISSA_BITS-1:0] Mout;
wire [EXP_BITS-1:0] Eout;
wire Sout;

wire [MANTISSA_BITS-1:0] Ma = ui_in[MANTISSA_BITS-1:0];
wire [EXP_BITS-1:0] Ea = ui_in[(MANTISSA_BITS + EXP_BITS - 1):MANTISSA_BITS];
wire Sa = ui_in[(SIGN_BITS + EXP_BITS + MANTISSA_BITS - 1)];

wire [MANTISSA_BITS-1:0] Mb = uio_in[MANTISSA_BITS-1:0];
wire [EXP_BITS-1:0] Eb = uio_in[(MANTISSA_BITS + EXP_BITS - 1):MANTISSA_BITS];
wire Sb = uio_in[(SIGN_BITS + EXP_BITS + MANTISSA_BITS - 1)];

assign Sout = Sa ^ Sb;

wire [MANTISSA_BITS:0] M1aout = Ma[MANTISSA_BITS-1] ? {2'b11, Ma[MANTISSA_BITS-1:1]} : {1'b0, Ma};
wire [MANTISSA_BITS:0] M1bout = Mb[MANTISSA_BITS-1] ? {2'b11, Mb[MANTISSA_BITS-1:1]} : {1'b0, Mb};
wire [MANTISSA_BITS:0] M1addout = M1aout + M1bout;

wire N1, N2, N3, Ce;

assign N1 = ~(Ma[MANTISSA_BITS-1] & Mb[MANTISSA_BITS-1]);
assign N2 = ~(Ma[MANTISSA_BITS-1] | Mb[MANTISSA_BITS-1]);
assign N3 = ~((~N2) & (~M1addout[MANTISSA_BITS]));
assign Ce = ~(N1 & N3);

assign Eout = Ea + Eb - BIAS +Ce;
assign Mout = M1addout[MANTISSA_BITS] ? {M1addout[MANTISSA_BITS-2:0], 1'b0} : M1addout[MANTISSA_BITS-1:0];
assign uo_out = {Sout, Eout, Mout};

endmodule
