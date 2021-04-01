module tb_quantizer();

   logic clk;
   logic rst;

   logic ena_in;
   logic ena_out;

   logic rdy_in;
   logic rdy_out;

   logic [14:0] in;
   logic [10:0] out;

   quantizer DUT(.*);
   
   initial forever begin
      clk = '0;
      #1;
      clk = '1;
      #1;
   end
   
   initial begin
      rdy_in = '1;
      ena_in = '0;
      rst = '1;
      @(posedge clk);
      rst = '0;
      
      in = 15'd1200;
      ena_in = '1;
      @(posedge clk);
      ena_in = '0;
   end

endmodule // tb_quantizer
