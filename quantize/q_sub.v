module q_sub (input logic clk, input logic rst, input logic start, output logic done,
					input logic [7:0] base_addr,
					output logic [7:0] q_addr, output logic [7:0] dct_addr,
					input logic [31:0] q_rddata, input logic [31:0] dct_rddata,
					output logic [7:0] out_addr, output logic [31:0] wrdata, output logic wren);
	
endmodule