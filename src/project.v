/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_logarithmic_afpm (
    input  wire [7:0] ui_in,    // 8-bit input
    output reg  [7:0] uo_out,   // 8-bit output
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path (not used)
    output wire [7:0] uio_oe,   // IOs: Enable path (not used)
    input  wire       ena,      // Enable signal
    input  wire       clk,      // Clock signal
    input  wire       rst_n     // Reset signal
);

    // State Encoding
    localparam IDLE       = 2'b00,
               COLLECT    = 2'b01,
               PROCESS    = 2'b10;

    reg [1:0] state;                // FSM state register
    reg [15:0] A, B;                // 16-bit registers for operands
    reg [15:0] result;              // 16-bit result register
    reg [1:0] byte_count;           // Counter to track byte collection
    reg        processing_done_flag; // Internal processing completion flag

    // Assign unused signals
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Prevent warnings for unused inputs
    wire _unused_ok = &{ena, clk, rst_n};

    // Declare wires for extracted fields
    wire [9:0] Ma, Mb;
    wire [4:0] Ea, Eb;
    wire       Sa, Sb;
    wire       Sout;
    wire [10:0] M1aout, M1bout, M1addout;
    wire        Ce;
    wire [4:0]  Eout;
    wire [9:0]  Mout;

    // Extract fields from operands A and B
    assign Ma = A[9:0];
    assign Ea = A[14:10];
    assign Sa = A[15];

    assign Mb = B[9:0];
    assign Eb = B[14:10];
    assign Sb = B[15];

    assign Sout = Sa ^ Sb;  // Sign of the result

    // Normalize mantissas (implicit leading 1)
    assign M1aout = {1'b1, Ma};
    assign M1bout = {1'b1, Mb};
    assign M1addout = M1aout + M1bout;

    // Compute carry for exponent adjustment
    assign Ce = M1addout[10];

    // Compute result exponent and mantissa
    assign Eout = Ea + Eb - 5'd15 + Ce;  // Exponent bias is 15 for 16-bit
    assign Mout = Ce ? M1addout[10:1] : M1addout[9:0];

    // FSM Implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic
            state <= IDLE;
            A <= 16'b0;
            B <= 16'b0;
            result <= 16'b0;
            byte_count <= 2'b0;
            processing_done_flag <= 1'b0; // Reset flag on reset
        end else if (ena) begin
            case (state)
                IDLE: begin
                    byte_count <= 2'b0;
                    processing_done_flag <= 1'b0; // Reset flag in IDLE state
                    state <= COLLECT;
                end
                COLLECT: begin
                    if (byte_count < 2) begin
                        A[byte_count*8 +: 8] <= ui_in;  // Collect 8 bits of operand A
                        B[byte_count*8 +: 8] <= uio_in; // Collect 8 bits of operand B
                        byte_count <= byte_count + 1;
                    end
                    if (byte_count == 2) begin
                        byte_count <= 2'b0;
                        state <= PROCESS;
                    end
                end
                PROCESS: begin
                    // Combine sign, exponent, and mantissa
                    result <= {Sout, Eout, Mout};
                    processing_done_flag <= 1'b1; // Flag processing as done
                    state <= IDLE;
                end
            endcase
        end
    end

    // Single driver for processing_done_flag using a D flip-flop
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            processing_done_flag <= 1'b0;  // Reset to 0 on reset
        else if (ena)
            processing_done_flag <= processing_done_flag; // No extra logic, simple register
    end

    // Output Result Byte by Byte
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uo_out <= 8'b0;
        end else if (processing_done_flag) begin
            uo_out <= result[byte_count*8 +: 8];
            byte_count <= byte_count + 1;
            if (byte_count == 1) begin
                processing_done_flag <= 1'b0; // Reset flag once processing is done
                byte_count <= 2'b0;
            end
        end
    end

endmodule
