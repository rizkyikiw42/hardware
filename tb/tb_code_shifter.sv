module tb_code_shifter();

   logic clk;
   logic rst;

   logic ena_in;
   logic ena_out;

   logic rdy_in;
   logic rdy_out;

   logic flush;

   logic [15:0] code;
   logic [4:0] size;

   logic [15:0] out;

   code_shifter #(.WIDTH(16)) DUT(.*);

   initial forever begin
      clk = '0; #1;
      clk = '1; #1;
   end


   initial begin
      flush = '0;
      rdy_in = '1;
      rst = '1;
      @(posedge clk) rst = '0;

      ena_in = '1;
      code = 16'b10000000001;
      size = 5'd11;
      @(posedge clk);

      code = 16'b1000001;
      size = 5'd7;
      @(posedge clk);

      code = 16'b1010101010101011;
      size = 5'd16;
      @(posedge clk);

      ena_in = '0;
      flush = '1;
      @(posedge clk);
      flush = '0;
      
      code = 16'b1010101010101011;
      ena_in = '1;
      @(posedge clk);
      ena_in = '0;

      $stop;
   end

   always @(posedge clk)
     if (ena_out)
       $display("%b", out);

   // 1000000000110000
   // 0110101010101010
   // 11

   // 1000000000110000
   // 0110101010101010
   // 1100000000000000

endmodule // tb_code_shifter
