import sim_dct::*;

module tb_dct_1d();
   logic clk, rst, ena_in, ena_out;
   logic rdy_in, rdy_out;
   logic signed [7:0] a_in;
   logic signed [11:0] S_out;

   dct_1d DUT(.*);

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
      real S[8][8];
      real diff;
      for (int i = 0; i < 8; i++)
        S[i] = dct_approx(a[i]);

      rdy_in = 0;
      ena_in = 0;

      fork
         // Process to push things into the pipelinee
         begin
            #10;
            for (int row = 0; row < 8; row++) begin
               while (!rdy_out)
                 @(negedge clk);
               ena_in = 1;
               for (int col = 0; col < 8; col++) begin
                  a_in = a[row][col];
                  @(posedge clk);
               end
               ena_in = 0;
            end
            a_in = 'x;
         end

         // Process checking coefficients that come out
         begin
            // First row of coefficients takes 48 clocks to emerge.
            #100;
            rdy_in = 1;
            for (int row = 0; row < 8; row++)
              for (int col = 0; col < 8; col++) begin
                 while (!ena_out)
                   @(posedge clk);
                 diff = S[row][col] - S_out;
                 // 1% tolerance
                 assert (diff <= 2 && diff >= -2)
                   else $error("Computed S[%d][%d] = %f, got %d",
                               row, col, S[row][col], S_out);
                 @(posedge clk);
              end
         end
      join
   endtask // dct_test

   initial begin
      rst = 1;
      #2;
      rst = 0;
      dct_test(testblock);
      $stop;
   end
endmodule // tb_dct_1d
