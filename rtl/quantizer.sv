// All q-table entries are > 8, so the output can be 3 bits narrower
// than the input.
//
// On one ena_in, the preceding module must provide an entire 8
// pixels.  We provide individual ena_outs for every ena_in.
module quantizer(input logic clk, input logic rst,
                 input logic ena_in, output logic ena_out,
                 input logic rdy_in, output logic rdy_out,
                 input logic signed [14:0] in, output logic signed [10:0] out);

   logic [5:0] idx;
   logic signed [11:0] q;
   logic signed [11:0] out_full;
   
   logic signed [11:0] q_table[64];
   initial $readmemh("q_table.hex", q_table);

   always_ff @(posedge clk)
     if (rst) begin
        idx <= 6'b1;
        q <= {3'b0, q_table['0]};
     end else if (ena_out) begin
        idx <= idx + 6'b1;
        q <= {3'b0, q_table[idx]};
     end

   assign rdy_out = rdy_in;
   assign ena_out = rdy_in && (ena_in || idx[2:0] != 3'b1);

   // This implements away-from-zero rounding.
   assign out_full = (in * 2) / q;
   assign out = out_full[11:1] + (!out_full[11] & out_full[0]);

endmodule // quantizer
