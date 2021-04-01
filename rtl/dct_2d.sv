// On one ena_in, the user must provide an entire row of 8 pixels.  On
// out ena_out, the next module must accept an entire row of 8
// coefficients.
module dct_2d(input logic clk, input logic rst,
              input logic [7:0] in, output logic [14:0] out,
              input logic ena_in, output logic ena_out,
              input logic rdy_in, output logic rdy_out);

   logic ena_trb;
   logic rdy_trb;
   logic ena_s1;
   logic rdy_s1;
   
   logic [11:0] in_trb;
   logic [11:0] in_s1;
   
   dct_1d #(.STAGE(0)) DCT0 (clk, rst, ena_in, ena_trb, rdy_trb, rdy_out, in, in_trb);
   transpose_buffer TRB (clk, rst, ena_trb, ena_s1, rdy_s1, rdy_trb, in_trb, in_s1);
   dct_1d #(.STAGE(1)) DCT1 (clk, rst, ena_s1, ena_out, rdy_in, rdy_s1, in_s1, out);

endmodule // dct_2d
