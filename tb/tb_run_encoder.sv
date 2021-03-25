module tb_run_encoder();

   logic clk;
   logic rst;

   logic ena_in;
   logic ena_out;

   logic rdy_in;
   logic rdy_out;

   logic signed [10:0] in;

   logic [9:0] out;
   logic signed [10:0] out_dc;
   logic [3:0] run;
   logic [3:0] size;
   logic dc;
   logic done;
   
   run_encoder DUT(.*);

   initial forever begin
      clk = '0; #1;
      clk = '1; #1;
   end

   localparam int quant_block[64] = '{
      0,  2, -2, -10, -11, -1,  1,  1,
      6,  3,  0,  1,  3, -1,  0,  0,
      0,  0, -1, -1,  0,  0,  1,  1,
      0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,
      0,  1,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0
   };

   typedef struct {
     int run;
     int size;
     logic [9:0] symbol;
   } run_output;

   localparam int expected_dc = 0;
   
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

   initial begin
      assign ena_in = rdy_out;
      rdy_in = '1;
      rst = '1;
      @(posedge clk) rst = '0;

      for (int i = 0; i < 64; i++) begin
         in = quant_block[i];
         while (!rdy_out)
           @(posedge clk);
         @(posedge clk);
      end

      assign ena_in = '0;
      @(posedge done);
      @(posedge clk);
      @(posedge clk);
      $stop;
   end

   initial begin
      int i;
      @(negedge done);
      while (i < 19 && !done) begin
         @(posedge clk);
         if (ena_out) begin
            if (dc)
              assert (out_dc === expected_dc)
                else $error("wrong dc");
              else begin
                 assert (runs[i].run === run && runs[i].size === size
                         && runs[i].symbol === out)
                   else $error("wrong: out: %03h (size %d), run %d", out, size, run);
                 i++;
              end
         end
      end

      assert (i == 19 && done)
        else $error("did not emit 19 codes");
   end
       
endmodule // tb_run_encoder
