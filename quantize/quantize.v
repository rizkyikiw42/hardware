module quantize (input logic clk, input logic rst, input logic start, output logic done,
						output logic [7:0] q_addr, output logic [7:0] dct_addr,
						input logic [31:0] q_rddata, input logic [31:0] dct_rddata,
						output logic [7:0] out_addr, output logic [31:0] wrdata, output logic wren);
	
	parameter [3:0] num_ops = 8;

	logic [num_ops-1:0] sub_ops_start;
	logic [num_ops-1:0] sub_ops_done;
	enum {START, WAIT, DONE} state;

	genvar i;

	/*
	Figure out how to create parallelism without having multiple modules changing the same wires.
	Need to add arbiter for that, either here on in the top level module.
	*/
	generate
		for (i = 0; i < num_ops; i++) begin : parallel_runs
			q_sub u0 (clk, rst, sub_ops_start[i], sub_ops_done[i], i*num_ops, q_addr, dct_addr, q_rddata, dct_rddata, out_addr, wrdata, wren);
		end
	endgenerate

	always @(posedge clk) begin
		if (~rst) begin
			sub_ops_start <= 0;
			state <= START;
			done <= 0;
		end
		else begin
			case (state)
			START: begin
				done <= 0;
				if (start) begin
					sub_ops_start <= {num_ops{1'b1}};
					state <= WAIT;
				end
			end
			WAIT: begin
				sub_ops_start <= {num_ops{1'b0}};
				if (sub_ops_done == {num_ops{1'b1}})
					state <= DONE;
			end
			DONE: begin
				done <= 1;
				state <= START;
			end
			default: begin
				done <= done;
				state <= state;
			end
			
		end
	end
endmodule;