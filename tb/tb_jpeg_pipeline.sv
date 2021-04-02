module tb_jpeg_pipeline();

   logic clk;
   logic rst;

   logic signed [7:0] in_pixel;
   logic [15:0] out_bits;

   logic ena_in;
   logic ena_out;

   logic rdy_in;
   logic rdy_out;

   jpeg_pipeline DUT(.*);

   initial forever begin
      clk = '0;
      #1;
      clk = '1;
      #1;
   end
   

   localparam int inblock[64] = '{
     -50, -54, -57, -57, -53, -47, -42, -40, 
     -56, -52, -50, -54, -56, -45, -21,  -1, 
     -46, -56, -56, -33,  -2,  10,  -4, -25, 
     -47, -20,   6,   7, -10, -17,  -3,  17, 
      -2, -15, -21,  -6,  19,  27,  11,  -9, 
     -10,  -3,   7,  13,   9,  -9, -32, -49, 
      18,  14,   3, -18, -44, -66, -81, -87, 
      10, -15, -46, -65, -70, -71, -77, -84
   };
   
   initial begin
      rst = '1;
      @(posedge clk) rst = '0;

      rdy_in = '1;
      
      for (int row = 0; row < 8; row++) begin
         while (!rdy_out)
           @(negedge clk);
         ena_in = 1;
         for (int col = 0; col < 8; col++) begin
            in_pixel = inblock[row * 8 + col];
            @(posedge clk);
         end
         ena_in = '0;
         in_pixel = 'x;
      end
   end
   
   always @(posedge clk)
     if (DUT.HUFF.ena_out)
       $display("huff out: %x", DUT.HUFF.out);

   always @(posedge clk)
     if (DUT.STUFF.ena_out)
       $display("stuff out: %x", DUT.STUFF.out);
   
endmodule // tb_jpeg_pipeline
