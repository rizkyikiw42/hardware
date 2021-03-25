module tb_huffman_coder();

   logic clk;
   logic rst;

   logic ena_in;
   logic ena_out;
   logic rdy_in;
   logic rdy_out;

   logic [9:0] in;
   logic signed [10:0] in_dc;
   logic [3:0] run, size;
   logic dc;
   logic flush;

   logic [15:0] out;

   huffman_coder DUT(.*);

   typedef struct {
     int run;
     int size;
     logic [9:0] symbol;
   } run_output;

   localparam int dc_coef = -14;

   localparam run_output runs[19] = '{
     '{ 0, 2, 10'h002 },
     '{ 0, 2, 10'h3fd },
     '{ 0, 4, 10'h3f5 },
     '{ 0, 4, 10'h3f4 },
     '{ 0, 1, 10'h3fe },
     '{ 0, 1, 10'h001 },
     '{ 0, 1, 10'h001 },
     '{ 0, 3, 10'h006 },
     '{ 0, 2, 10'h003 },
     '{ 1, 1, 10'h001 },
     '{ 0, 2, 10'h003 },
     '{ 0, 1, 10'h3fe },
     '{ 4, 1, 10'h3fe },
     '{ 0, 1, 10'h3fe },
     '{ 2, 1, 10'h001 },
     '{ 0, 1, 10'h001 },
     '{ 15, 0, 'x },
     '{ 9, 1, 10'h001 },
     '{ 0, 0, 'x }
   };

   localparam int block_dc = -14;

   localparam logic [15:0] outbits[7] = '{
     16'b1010001011001011,
     16'b0110101101101000,
     16'b0000100110011001,
     16'b1111001011100011,
     16'b1011000011100100,
     16'b1111111110011111,
     16'b1100111010000000
   };
   
   initial forever begin
      clk = '0; #1;
      clk = '1; #1;
   end
   
   initial begin
      rdy_in = '1;
      dc = '0;
      flush = '0;
      ena_in = '0;
      rst = '1;
      @(posedge clk) rst = '0;

      assign ena_in = rdy_out;

      dc = '1;
      in_dc = block_dc;
      @(posedge clk);
      dc = '0;
      in_dc = 'x;

      for (int i = 0; i < 19; i++) begin
         in = 'x;
         size = 'x;
         run = 'x;
         @(posedge rdy_out);
         in = runs[i].symbol;
         size = runs[i].size;
         run = runs[i].run;
         @(posedge clk);
      end
      
      @(posedge rdy_out);
      flush = '1;
      @(posedge clk);
      flush = '0;
   end

   initial begin
      int i;
      #2;
      for (i = 0; i < 7; i++) begin
         while (!ena_out)
           @(posedge clk);
         if (ena_out)
           assert (outbits[i] === out)
             else $error("expected output %b, got %b", 
                         outbits[i], out);
         @(posedge clk);
      end

      assert (i == 7)
        else $error("expected 7 16-bit outputs");
      
      $stop;
   end
   
   // always @(posedge clk)
   //   if (ena_out)
   //     $display("out: %b", out);

   // always @(posedge clk)
   //   if (DUT.shift_ena)
   //     $display("shifted: %b (%d)", DUT.shift_code, DUT.shift_size);

endmodule // tb_huffman_coder
