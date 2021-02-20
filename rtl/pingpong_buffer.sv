module pingpong_buffer
  #(parameter WIDTH=8)
   (input logic clk, rst, ena_in, shiftout,
    input logic [WIDTH-1:0] in,
    output logic [7:0] [WIDTH-1:0] out);
   logic [6:0] [WIDTH-1:0] tmp;
   vdffe #(WIDTH) SHIFTREG[6:0] (clk, rst, ena_in, {tmp[5:0], in}, tmp);
   vdffe #(8 * WIDTH) OUTREG(clk, rst, shiftout, {tmp, in}, out);
endmodule // pingpong_foo
