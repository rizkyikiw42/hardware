`timescale 1ps / 1ps

module tb_trb ();

  logic [11:0] in, out;
  logic clk, rst, ena_in;
  logic [7:0] i;

  transpose_buffer dut (clk, rst, ena_in, in, out);

  initial begin
    clk = 0;
    // #10;
    forever #5 clk = ~clk;
  end

  initial begin
    ena_in = 0;
    rst = 1;
    #10;
    rst = 0;

    ena_in = 1;
    for (i = 1; i <= 192; i++) begin
      @(posedge clk) in = i;
    end

  end
endmodule // tb_trb
