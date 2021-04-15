// Accepts WIDTH pixels serially, then on the final clock cycle makes
// them all available at once on the parallel output.  They are kept
// available until the next row is completely pushed in.
module pingpong_buffer
  #(parameter WIDTH=8)
   (input logic clk, rst, ena_in, shiftout,
    input logic [WIDTH-1:0] in,
    output logic [7:0] [WIDTH-1:0] out);
   logic [6:0] [WIDTH-1:0] tmp;
   vdffe #(WIDTH) SHIFTREG[6:0] (clk, rst, ena_in, {in, tmp[6:1]}, tmp);
   vdffe #(8 * WIDTH) OUTREG(clk, rst, shiftout, {in, tmp}, out);
endmodule // pingpong_foo
