module tb_byte_stuffer();

   logic clk;
   logic rst;

   logic ena_in;
   logic ena_out;

   logic rdy_in;
   logic rdy_out;

   logic [15:0] in;
   logic [15:0] out;

   logic flush;
   logic done;
   
   byte_stuffer DUT(.*);

   initial forever begin
      clk = '0; #1;
      clk = '1; #1;
   end
   
   initial begin
      rdy_in = '1;
      ena_in = '0;
      rst = '1;
      @(posedge clk) rst = '0;

      assign ena_in = rdy_out;

      in = 16'h1234;
      while (!rdy_out)
        @(negedge clk);
      @(posedge clk);

      in = 16'hffab;
      while (!rdy_out)
        @(negedge clk);
      @(posedge clk);

      in = 16'h1234;
      while (!rdy_out)
        @(negedge clk);
      @(posedge clk);

      in = 16'hff56;
      while (!rdy_out)
        @(negedge clk);
      @(posedge clk);

      in = 16'habff;
      while (!rdy_out)
        @(negedge clk);
      @(posedge clk);

      assign ena_in = '0;

      flush = '1;
      @(posedge done);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      $stop;
   end
   
   always @(posedge clk)
     if (ena_in)
       $display("in : %h", in);

   always @(posedge clk)
     if (ena_out)
       $display("out: %h", out);

endmodule // tb_byte_stuffer
