`timescale 1ps/1ps

import sim_dct::*;
module tb_dct_2d();
   logic clk, rst, ena;
   logic signed [7:0] in;
   logic signed [14:0] out;

   dct_2d DUT(clk, rst, in, out, ena);

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
      real diff;

      for (int i = 0; i < 8; i++)
        S0[i] = dct_approx(a[i]);

      for (int i = 0; i < 8; i++) begin
         int col[8];
         for (int j = 0; j < 8; j++)
           col[j] = S0[j][i];
         S1[i] = dct_approx(col);
      end

      ena = 1; #2;
      fork
         // Process to push things into the pipelinee
         begin
            for (int row = 0; row < 8; row++)
              for (int col = 0; col < 8; col++) begin
                 in = a[row][col]; #2;
              end
            in = 'x;
         end

         // Process checking coefficients that come out
         begin
            // First row of coefficients takes 48+64+48 clocks to emerge.
            #96;#128;#96;#2;
            for (int col = 0; col < 8; col++)
              for (int row = 0; row < 8; row++) begin
                 diff = S1[col][row] - out;
                 // 0.0001% tolerance
                 assert (diff <= 10 && diff >= -10)
                   else $error("Computed S[%d][%d] = %f, got %d",
                               row, col, S1[col][row], out);
                 #2;
              end
         end
      join
      ena = 0;
   endtask // dct_test

   initial begin
      rst = 1;
      #2;;

      rst = 0;
      dct_test(testblock);
      $stop;
   end
endmodule
