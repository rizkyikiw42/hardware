module tb_zigzag();

   logic clk;
   logic rst;

   logic ena_in;
   logic ena_out;

   logic rdy_in;
   logic rdy_out;

   logic [10:0] in;
   logic [10:0] out;
   
   zigzag DUT(.*);

   initial forever begin
      clk = '0; #1;
      clk = '1; #1;
   end

   // Input order:
   //    0  8 16 24 32 40 48 56 
   //    1  9 17 25 33 41 49 57 
   //    2 10 18 26 34 42 50 58 
   //    3 11 19 27 35 43 51 59 
   //    4 12 20 28 36 44 52 60 
   //    5 13 21 29 37 45 53 61 
   //    6 14 22 30 38 46 54 62 
   //    7 15 23 31 39 47 55 63 
   
   // Output order:
   localparam int expected[64] = '{
     0,  8,  1,  2,  9,  16, 24, 17,
     10, 3,  4,  11, 18, 25, 32, 40,
     33, 26, 19, 12, 5,  6,  13, 20,
     27, 34, 41, 48, 56, 49, 42, 35,
     28, 21, 14, 7,  15, 22, 29, 36,
     43, 50, 57, 58, 51, 44, 37, 30,
     23, 31, 38, 45, 52, 59, 60, 53,
     46, 39, 47, 54, 61, 62, 55, 63
   };

   initial begin
      rst = '1;
      #2 rst = '0;

      assign ena_in = rdy_out;
      for (int i = 0; i < 64; i++) begin
         while (!rdy_out)
           @(negedge clk);
         in = 100 + i;
         @(posedge clk);
         in = 'x;
         @(negedge clk);
      end

      for (int i = 0; i < 64; i++) begin
         while (!rdy_out)
           @(negedge clk);
         in = 200 + i;
         @(posedge clk);
         in = 'x;
         @(negedge clk);
      end

      assign ena_in = '0;
   end

   initial begin
      #2;
      rdy_in = '1;
      for (int i = 0; i < 64; i++) begin
         while (!ena_out)
           @(posedge clk);
         assert (out === expected[i] + 100)
           else $error("got wrong output %d, expected %d", 
                       out, expected[i] + 100);
         @(posedge clk);
      end

      for (int i = 0; i < 64; i++) begin
         while (!ena_out)
           @(posedge clk);
         assert (out === expected[i] + 200)
           else $error("got wrong output %d, expected %d", 
                       out, expected[i] + 200);
         @(posedge clk);
      end

      rdy_in = '0;
      
      $stop;
   end
   
endmodule // tb_zigzag
