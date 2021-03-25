// All q-table entries are > 8, so the output can be 3 bits narrower
// than the input.
module quantizer(input logic clk, input logic rst,
                 input logic ena_in, output logic ena_out,
                 input logic rdy_in, output logic rdy_out,
                 input logic [14:0] in, output logic [10:0] out);

   logic [5:0] idx;
   logic [7:0] q;
   
   logic [9:0] q_table[64];
   initial $readmemh("q_table.hex", q_table);

   always_ff @(posedge clk)
     if (rst) begin
        idx <= '1;
        q <= q_table['0];
     end else if (ena_in) begin
        idx <= idx + 6'b1;
        q <= q_table[idx];
     end

   assign rdy_out = rdy_in;
   assign ena_out = ena_in;

   assign out = in / q;
   
endmodule // quantizer
