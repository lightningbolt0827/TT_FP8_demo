`default_nettype none

module tt_um_logarithmic_afpm (
    input wire [7:0] ui_in,    // 8-bit input
    input wire [7:0] uio_in,   // IOs: Input path
    output reg [7:0] uo_out,   // 8-bit output
    output wire [7:0] uio_out,  // IOs: Output path (not used)
    output wire [7:0] uio_oe,   // IOs: Enable path (not used)
    input  wire       ena,      // Enable signal
    input  wire       clk,      // Clock signal
    input  wire       rst_n     // Reset signal
);

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;
    wire _unused = &{ena, 1'b0};
    
   localparam IDLE       = 4'b0000,
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
    reg processing_done;            // Flag indicating completion of processing
    
	reg [10:0] Mout;
	reg [5-1:0] Eout;
	reg Sout;
	reg [10-1:0] Ma;
	reg [5-1:0] Ea;
	reg Sa;
	reg [10-1:0] Mb;
	reg [5-1:0] Eb;
	reg Sb;
	reg [10:0] M1aout;
	reg [10:0] M1bout;
	reg [10:0] M1addout;
	reg N1, N2, N3, Ce;

    // Assign unused signals
    //assign uio_out = 0;
    //assign uio_oe  = 0;

    // FSM Implementation
always @(posedge clk) 
	begin
	if (!rst_n) 
		begin
			// Reset logic
			state <= IDLE;
			A <= 16'bx;
			B <= 16'bx;
			result <= 16'bx;
			byte_count <= 0;
			processing_done <= 0;
			uo_out <= 8'bx;
        	end 
        else
        	begin
		case (state)
		IDLE: begin
		    byte_count <= 0;
		    processing_done <= 0;
		    if (ui_in!=8'b0) 
		    begin  // Start signal detected (e.g., LSB=1)
			state <= COLLECT;
		    end
		end
		COLLECT: begin 	
		    A[byte_count*8 +: 8] <= ui_in;  // Store 8 bits of operand A
		    B[byte_count*8 +: 8] <= uio_in;  // Store 8 bits of operand B
		    byte_count <= byte_count + 1;
		    if(byte_count==1)
		    begin
		        state <= PROCESS_1;
		    end
		end
		PROCESS_1: begin
			byte_count <= 0;
			Ma[10-1:0] <= A[10-1:0];
			Ea[5-1:0] <= A[(10 + 5 - 1):10];
			Sa <= A[(1 + 5 + 10 - 1)];
			Mb[10-1:0] <= B[10-1:0];
			Eb[5-1:0] <= B[(10 + 5 - 1):10];
			Sb <= B[(1 + 5 + 10 - 1)];
			state <= PROCESS_2;
		end
		PROCESS_2: begin
			Sout <= Sa ^ Sb;
		    // Extract sign, exponent, and mantissa for computation
			M1aout[10:0] <= Ma[10-1]?(Ma[10-2]?{(Ma+(Ma>>5))}
			:{(Ma+(Ma>>3))})
			:(Ma[10-2]?{(Ma+(Ma>>2))}
			:{(Ma+(Ma>>2)+(Ma>>4))});
			M1bout[10:0] <= Mb[10-1]?(Mb[10-2]?{(Mb+(Mb>>5))}
			:{Mb+(Mb>>3)})
			:(Mb[10-2]?{(Mb+(Mb>>2))}
			:{(Mb+(Mb>>2)+(Mb>>4))});
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
			Eout <= Ea + Eb - 15 + Ce;
			Mout <= M1addout[10-1] ?
			(M1addout[10-1:0]+(M1addout[10-1:0]>>3)+(M1addout[10-1:0]>>5)+(M1addout[10-1:0]>>6))+(10'b1101 << 19):
			((M1addout[10-1:0]>>1)+(M1addout[10-1:0]>>2)+(M1addout[10-1:0]>>4));
			state <= PROCESS_6;
		end
		PROCESS_6: begin
			result <= {Sout, Eout, Mout[10-1:0]};
			processing_done <= 1;
			state <= OUTPUT;
		end
		OUTPUT: begin
			uo_out <= result[byte_count*8 +: 8];
			byte_count <= byte_count + 1;
		    	if(byte_count==1)
		    	begin
		             state <= IDLE;
		             processing_done <= 0;		             
			end
		end
    		endcase
    		end
        end
endmodule
