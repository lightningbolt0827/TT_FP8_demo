`default_nettype none

module tt_um_logarithmic_afpm (
	input wire [7:0] ui_in,     // 8-bit input
	input wire [7:0] uio_in,    // IOs: Input path
	output reg [7:0] uo_out,    // 8-bit output
	output wire [7:0] uio_out,  // IOs: Output path (not used)
	output wire [7:0] uio_oe,   // IOs: Enable path (not used)
	input  wire       ena,      // Enable signal
	input  wire       clk,      // Clock signal
	input  wire       rst_n     // Reset signal
);
	
	// Assign unused signals
	assign uio_out = 8'b0;
	assign uio_oe  = 8'b0;
		
	wire _unused = &{ena, 1'b0};
	
	localparam  IDLE       = 4'b0000,
		    COLLECT    = 4'b0001,
		    PROCESS_1  = 4'b0011,
		    PROCESS_2  = 4'b0010,
		    PROCESS_3  = 4'b0110,
		    PROCESS_4  = 4'b0111,
		    PROCESS_5  = 4'b0101,
		    PROCESS_6  = 4'b0100,
		    OUTPUT     = 4'b1100;
	
	reg [3:0] state;                // FSM state register
	reg [15:0] A, B;                // 32-bit registers for operands
	reg [15:0] result;              // 32-bit result register
	reg [1:0] byte_count;           // Counter to track byte collection
	
	reg [10:0] Mout, M1aout, M1bout, M1addout;
	reg [4:0] Eout, Ea, Eb;
	reg Sout, Sa, Sb, Ce;
	reg [9:0] Ma, Mb;
	
	// FSM Implementation
	always @(posedge clk) 
	begin
		if (!rst_n) 
		begin
			// Reset logic
			state <= IDLE;
			A <= 16'b0;
			B <= 16'b0;
			result <= 16'b0;
			byte_count <= 0;
			uo_out <= 8'b0;
		end 
		else
		begin
			case (state)
				IDLE: begin
					byte_count <= 0;
					if (ui_in!=8'b0)   
						state <= COLLECT;	// Start signal detected (e.g., LSB=1)
				end
				COLLECT: begin 	
					A[byte_count*8 +: 8] <= ui_in; 		// Store 8 bits of operand A
					B[byte_count*8 +: 8] <= uio_in;		// Store 8 bits of operand B
					byte_count <= byte_count + 1;
					if(byte_count==1)
						state <= PROCESS_1;
				end
				PROCESS_1: begin	// Extract sign, exponent, and mantissa for computation
					byte_count <= 0;
					Ma[9:0] <= A[9:0];
					Ea[4:0] <= A[14:10];
					Sa <= A[15];
					Mb[9:0] <= B[9:0];
					Eb[5-1:0] <= B[14:10];
					Sb <= B[15];
					state <= PROCESS_2;
				end
				PROCESS_2: begin
					Sout <= Sa ^ Sb; 
					M1aout[10:0] <= Ma[9]?(Ma[8]?{1'b0,(Ma+(Ma>>5))}
					:{1'b0,(Ma+(Ma>>3))})
					:(Ma[8]?{1'b0,(Ma+(Ma>>2))}
					:{1'b0,(Ma+(Ma>>2)+(Ma>>4))});
					M1bout[10:0] <= Mb[9]?(Mb[8]?{1'b0,(Mb+(Mb>>5))}
					:{1'b0,Mb+(Mb>>3)})
					:(Mb[8]?{1'b0,(Mb+(Mb>>2))}
					:{1'b0,(Mb+(Mb>>2)+(Mb>>4))});
					state <= PROCESS_3;
				end
				PROCESS_3: begin
					M1addout[10:0] <= M1aout + M1bout;
					state <= PROCESS_4;
				end
				PROCESS_4: begin
					Ce <= M1addout[10];
					state <= PROCESS_5;
				end
				PROCESS_5: begin
					Eout <= Ea + Eb - 15 + {4'b0,Ce};
					Mout <= M1addout[9] ?
					{1'b0,(M1addout[9:0]+(M1addout[9:0]>>3)+(M1addout[9:0]>>5)+(M1addout[9:0]>>6))+(10'b1101 << 19):
					 ((M1addout[9:0]>>1)+(M1addout[9:0]>>2)+(M1addout[9:0]>>4))};
					state <= PROCESS_6;
				end
				PROCESS_6: begin
					result <= {Sout, Eout, Mout[9:0]};
					state <= OUTPUT;
				end
				OUTPUT: begin
					uo_out <= result[byte_count*8 +: 8];
					byte_count <= byte_count + 1;
					if(byte_count==1)
						state <= IDLE;
				end
				default: begin
					state<=IDLE;
				end
			endcase
		end
	end
endmodule
