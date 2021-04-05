module tb_jpeg_pipeline();

   logic clk;
   logic rst_ext;

   logic signed [7:0] in_pixel;
   logic [15:0] out_bits;
   logic [1:0] out_valid;
   
   logic ena_in;
   logic ena_out;

   logic rdy_in;
   logic rdy_out;

   logic done_image;
   logic done_block;
   logic done_flush;
   
   jpeg_pipeline DUT(.*);

   initial forever begin
      clk = '0;
      #1;
      clk = '1;
      #1;
   end
   

   localparam int inblock[4][64] = '{
     '{
       -50, -54, -57, -57, -53, -47, -42, -40, 
       -56, -52, -50, -54, -56, -45, -21,  -1, 
       -46, -56, -56, -33,  -2,  10,  -4, -25, 
       -47, -20,   6,   7, -10, -17,  -3,  17, 
        -2, -15, -21,  -6,  19,  27,  11,  -9, 
       -10,  -3,   7,  13,   9,  -9, -32, -49, 
        18,  14,   3, -18, -44, -66, -81, -87, 
        10, -15, -46, -65, -70, -71, -77, -84 
     },
     '{
        -8,  -2,  -1,  -6,  -6,   0,   2,  -1, 
       -16, -11,  -3,   9,  20,  17,  -9, -37, 
       -16,  14,  36,  21, -18, -50, -59, -57, 
        12,   9,  -7, -35, -65, -80, -79, -73, 
       -19, -49, -81, -87, -72, -57, -53, -57, 
       -79, -86, -85, -74, -61, -53, -50, -47, 
       -79, -82, -76, -61, -52, -57, -68, -75, 
       -76, -73, -65, -60, -67, -77, -77, -69 
     },
     '{
       -59, -67, -78, -86, -86, -79, -68, -61, 
       -84, -79, -71, -63, -59, -59, -61, -63, 
       -73, -66, -56, -50, -51, -59, -70, -77, 
       -45, -48, -54, -61, -69, -75, -79, -81, 
       -55, -61, -69, -75, -78, -77, -73, -70, 
       -81, -79, -76, -73, -72, -71, -71, -71, 
       -80, -77, -73, -70, -69, -71, -74, -76, 
       -68, -70, -73, -75, -75, -73, -70, -68 
     },
     '{
       -58, -59, -63, -70, -76, -79, -77, -74, 
       -71, -70, -70, -72, -75, -75, -72, -69, 
       -76, -74, -73, -74, -75, -76, -73, -70, 
       -72, -71, -71, -74, -77, -76, -73, -70, 
       -74, -73, -72, -72, -71, -65, -57, -51, 
       -78, -75, -70, -64, -57, -47, -35, -27, 
       -68, -62, -54, -48, -42, -37, -30, -26, 
       -48, -43, -36, -33, -34, -37, -39, -40
     }
   };

   initial begin
      rst_ext = '1;
      @(posedge clk) rst_ext = '0;

      rdy_in = '1;
      done_image = '0;
      
      for (int block = 0; block < 4; block++) begin
         for (int row = 0; row < 8; row++) begin
            for (int col = 0; col < 8; col++) begin
               @(negedge clk);
               while (!rdy_out)
                 @(negedge clk);
               ena_in = 1;
               in_pixel = inblock[block][row * 8 + col];
               @(posedge clk);
               ena_in = '0;
               in_pixel = 'x;
            end
         end // for (int row = 0; row < 8; row++)
      end // for (int block = 0; block < 4; block++)
   end

   initial begin
      #10;
      
      for (int i = 0; i < 4; i++) begin
         while (!done_block)
           @(posedge clk);
         @(posedge clk);
      end

      done_image = 1'b1;
      @(posedge clk) done_image = 1'b0;
      while (!done_flush)
        @(negedge clk);
      @(posedge clk);
      $stop;
   end
   
   always @(posedge clk)
     if (ena_out)
       $display("out: %x", out_bits);

   // always @(posedge clk)
   //   if (DUT.HUFF.ena_out)
   //     $display("huff  out: %x", DUT.HUFF.out);

   // always @(posedge clk)
   //   if (DUT.RUNENC.ena_out) begin
   //      if (DUT.RUNENC.dc)
   //        $display("%t run dc : %d", $time, DUT.RUNENC.out_dc);
   //      else
   //        $display("%t run out: %d %b %d", $time, DUT.RUNENC.run, DUT.RUNENC.out, DUT.RUNENC.size);
   //   end

   // always @(posedge clk)
   //   if (DUT.HUFF.shift_ena)
   //     $display("shift: %d %b", DUT.HUFF.shift_size, DUT.HUFF.shift_code);       
   
   // always @(posedge clk)
   //   if (DUT.ZIGZAG.ena_out)
   //     $display("%t zig: %d", $time, signed'(DUT.ZIGZAG.out));

   // always @(posedge clk)
   //   if (DUT.QUANT.ena_out)
   //     $display("%t quant: %d", $time, DUT.QUANT.out);

   // always @(posedge clk)
   //   if (DUT.DCT.ena_out)
   //     $display("%t dct: %d", $time, signed'(DUT.DCT.out));

endmodule // tb_jpeg_pipeline
