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
    localparam IDLE       = 2'b00;
    localparam COLLECT    = 2'b01;
    localparam PROCESS    = 2'b10;

    reg [1:0] state;                // FSM state register
    reg [15:0] A;                   // 16-bit register for operand A
    reg [15:0] B;                   // 16-bit register for operand B
    reg [15:0] result;              // 16-bit result register
    reg [1:0] byte_count;           // Counter to track byte collection
    reg        processing_done;     // Flag indicating completion of processing

    wire [9:0] Ma;                  // Mantissa of operand A
    wire [4:0] Ea;                  // Exponent of operand A
    wire       Sa;                  // Sign of operand A

    wire [9:0] Mb;                  // Mantissa of operand B
    wire [4:0] Eb;                  // Exponent of operand B
    wire       Sb;                  // Sign of operand B

    wire Sout;                      // Sign of the result
    wire [10:0] M1aout;             // Normalized mantissa of operand A
    wire [10:0] M1bout;             // Normalized mantissa of operand B
    wire [10:0] M1addout;           // Addition of normalized mantissas
    wire Ce;                        // Carry for exponent adjustment
    wire [4:0] Eout;                // Result exponent
    wire [9:0] Mout;                // Result mantissa

    // Assign unused signals
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

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
            A <= 16'b0000000000000000;
            B <= 16'b0000000000000000;
            result <= 16'b0000000000000000;
            byte_count <= 2'b00;
            processing_done <= 1'b0;
        end else if (ena) begin
            case (state)
                IDLE: begin
                    byte_count <= 2'b00;
                    processing_done <= 1'b0;
                    state <= COLLECT;
                end
                COLLECT: begin
                    if (byte_count < 2) begin
                        A[byte_count*8 +: 8] <= ui_in;  // Collect 8 bits of operand A from ui_in
                        B[byte_count*8 +: 8] <= uio_in; // Collect 8 bits of operand B from uio_in
                        byte_count <= byte_count + 1;
                    end
                    if (byte_count == 2) begin
                        byte_count <= 2'b00;
                        state <= PROCESS;
                    end
                end
                PROCESS: begin
                    // Combine sign, exponent, and mantissa
                    result <= {Sout, Eout, Mout};
                    processing_done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

    // Output Result Byte by Byte
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uo_out <= 8'b00000000;
            byte_count <= 2'b00;
        end else if (processing_done) begin
            uo_out <= result[byte_count*8 +: 8];
            byte_count <= byte_count + 1;
            if (byte_count == 1) begin
                processing_done <= 1'b0; // Ensure only one always block updates processing_done
                byte_count <= 2'b00;
            end
        end
    end

endmodule
