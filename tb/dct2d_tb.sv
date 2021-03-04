`timescale 1ps/1ps

import sim_dct::*;
module dct2d_tb ();
  logic clk, rst, ena;
  logic [7:0] in;
  logic [14:0] out;

  dct2d dut (clk, rst, in, out, ena);

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
    real S_out[8][8];
    real diff;
    int count;
    for (int i = 0; i < 8; i++)
      S[i] = dct_approx(a[i]);

    // for (int i = 0; i < 8; i++)
    //   for (int j = 0; j < 8; j++)
    //     $display("%f", S[i][j]);

    // $display("\n\n\n\n");

    for (int i = 0; i < 8; i++) begin
      int in2[8];
      for (int j = 0; j <8; j++) begin
        in2[j] = S[j][i];
        // $display("%f", in2[j]);
      end
      S_out[i] = dct_approx(in2);
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
          count = 0;
          for (int row = 0; row < 8; row++)
            for (int col = 0; col < 8; col++) begin
                diff = S_out[row][col] - out;
                // 1% tolerance
                assert (diff <= 2 && diff >= -2)
                  else begin
                    $error("Computed S[%d][%d] = %f, got %d",
                              row, col, S_out[row][col], out);
                    count++;
                  end
                #2;
            end
          $display("Number of incorrect outputs = %d", count);
        end
    join
    ena = 0;
  endtask // dct_test

  initial begin
    rst = 1;
      #2;
      rst = 0;
      dct_test(testblock);
      $stop;
  end
endmodule