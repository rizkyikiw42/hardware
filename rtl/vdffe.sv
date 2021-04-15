// Simple, modelsim-friendly D flip-flop with enable.
module vdffe
  #(parameter WIDTH=8)
   (input logic clk, rst, ena,
    input logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out);
   always_ff @(posedge clk)
     if (rst)
       out <= 0;
     else if (ena)
       out <= in;
endmodule // vdffe
