`timescale 1ps/1ps

import sim_dct::*;
module tb_dct_2d();
   logic clk, rst, ena_in, ena_out;
   logic rdy_in, rdy_out;
   logic signed [7:0] in;
   logic signed [14:0] out;


   dct_2d DUT(.*);

   localparam int testblock[8][8] = '{
     '{65,  84,  88,   74,   71,   84,   91,   86},
     '{89,  82,  80,   87,   91,   86,   76,   69},
     '{91,  80,  69,   62,   51,   37,   29,   28},
     '{41,  39,  26,    9,    6,   13,   11,    1},
     '{ 4,  -1,  -6,    2,   21,   25,   -3,  -38},
     '{ 0,  -2,  14,   38,   33,   -9,  -56,  -82},
     '{11,  19,  32,   30,   -9,  -61,  -83,  -77},
     '{49,  49,  29,  -15,  -61,  -81,  -73,  -58}
   };

   initial forever begin
      clk = 0; #1;
      clk = 1; #1;
   end

   task dct_test(input int a[8][8]);
      real S0[8][8];
      real S1[8][8];
      logic signed [14:0] outs[8][8];
      real diff;

      for (int i = 0; i < 8; i++)
        S0[i] = dct_approx(a[i]);

      for (int i = 0; i < 8; i++) begin
         int col[8];
         for (int j = 0; j < 8; j++)
           col[j] = S0[j][i];
         S1[i] = dct_approx(col);
      end

      rdy_in = 0;
      ena_in = 0;

      fork
         // Process to push things into the pipeline
         begin
            for (int row = 0; row < 8; row++) begin
              while (!rdy_out)
                @(negedge clk);
               ena_in = 1;
               for (int col = 0; col < 8; col++) begin
                  in = a[row][col];
                  @(posedge clk);
               end
               ena_in = '0;
               in = 'x;
            end
         end

         // Process checking coefficients that come out
         begin
            // First row of coefficients takes 48+64+48 clocks to emerge.
            rdy_in = 1;
            for (int col = 0; col < 8; col++)
              for (int row = 0; row < 8; row++) begin
                 while (!ena_out)
                   @(posedge clk);
                 outs[row][col] = out;
                 diff = S1[col][row] - out;
                 // 0.0001% tolerance
                 $display("%d, expected %d", out, outs[row][col]);
                 assert (diff <= 10 && diff >= -10)
                   else $error("Computed S[%d][%d] = %f, got %d",
                               row, col, S1[col][row], out);
                 @(posedge clk);
              end
         end
      join
   endtask // dct_test

   initial begin
      rst = 1;
      #2;;

      rst = 0;
      dct_test(testblock);
      $stop;
   end
endmodule
