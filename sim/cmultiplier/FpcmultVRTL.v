`ifndef FIXED_POINT_ITERATIVE_COMPLEX_MULTIPLIER
`define FIXED_POINT_ITERATIVE_COMPLEX_MULTIPLIER
`include "./fixedpt-iterative-multiplier/sim/multiplier/FpmultVRTL.v"

module FpcmultVRTL
# (
	parameter n = 32, // bit width
	parameter d = 16 // number of decimal bits
) (
	input logic clk,
	input logic reset,
	input logic recv_val,
	output logic recv_rdy,
	output logic send_val,
	input logic send_rdy,
	input logic [n-1:0] ar,
	input logic [n-1:0] ac,
	input logic [n-1:0] br,
	input logic [n-1:0] bc,
	output logic [n-1:0] cr,
	output logic [n-1:0] cc
);
	// performs c = a * b on complex a and b

	// cr = (ar * br) - (ac * bc)
	// cc = (ar * bc) + (br * ac) = (ar + ac)(br + bc) - (ac * bc) - (ar * br)

	logic [n-1:0] arbr, acbc, ab, a, b; // temporary values
	logic arbr_rdy, acbc_rdy, ab_rdy, sab_rdy;
	logic m1_recv_rdy, m2_recv_rdy, m3_recv_rdy;
	reg [n-1:0] act, art, bct, brt;

	FpmultVRTL #(.n(n), .d(d), .sign(1)) m1 ( // ar * br
		.clk(clk),
		.reset(reset),
		.a(art),
		.b(brt),
		.c(arbr),
		.recv_val(sab_rdy),
		.recv_rdy(m1_recv_rdy),
		.send_val(arbr_rdy),
		.send_rdy(1'b1)
	);

	FpmultVRTL #(.n(n), .d(d), .sign(1)) m2 ( // ac * bc
		.clk(clk),
		.reset(reset),
		.a(act),
		.b(bct),
		.c(acbc),
		.recv_val(sab_rdy),
		.recv_rdy(m2_recv_rdy),
		.send_val(acbc_rdy),
		.send_rdy(1'b1)
	);

	FpmultVRTL #(.n(n), .d(d), .sign(1)) m3 ( // (ar + ac) * (br + bc)
		.clk(clk),
		.reset(reset),
		.a(a),
		.b(b),
		.c(ab),
		.recv_val(sab_rdy),
		.recv_rdy(m3_recv_rdy),
		.send_val(ab_rdy),
		.send_rdy(1'b1)
	);

	assign cr = arbr - acbc;
	assign cc = ab - arbr - acbc;

	always @(posedge clk) begin
		if (reset) begin
		  recv_rdy <= 1;
		  send_val <= 0;
		  sab_rdy <= 0;
		end else if (recv_val & recv_rdy) begin 
			sab_rdy <= 1;
			a <= ar + ac;
			b <= br + bc;
			act <= ac;
			art <= ar;
			bct <= bc;
			brt <= br;
			recv_rdy <= 0;
			send_val <= 0;
		end else if (sab_rdy) begin
			sab_rdy <= 0;
		end else if (~sab_rdy & ~send_val & arbr_rdy & acbc_rdy & ab_rdy) begin // all multipliers are done!
			send_val <= 1;
		end else if (~recv_rdy & send_val & send_rdy) begin
			recv_rdy <= 1;
		end
	end


endmodule

`endif
