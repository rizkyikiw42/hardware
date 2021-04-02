module tb_transpose_buffer();

   logic clk;
   logic rst;
   
   logic ena_in;
   logic ena_out;

   logic rdy_in;
   logic rdy_out;

   logic [11:0] S_in;
   logic [11:0] S_out;
   
   transpose_buffer DUT(.*);

   initial forever begin
      clk = '0; #1;
      clk = '1; #1;
   end

   initial begin
      rst = '1;
      @(posedge clk) rst = '0;
      
      assign ena_in = rdy_out;
      for (int i = 0; i < 64; i++) begin
         while (!rdy_out)
           @(negedge clk);
         S_in = 100 + i;
         @(posedge clk);
         S_in = 'x;
         @(negedge clk);
      end

      for (int i = 0; i < 64; i++) begin
         while (!rdy_out)
           @(negedge clk);
         S_in = 200 + i;
         @(posedge clk);
         S_in = 'x;
         @(negedge clk);
      end
      
      for (int i = 0; i < 64; i++) begin
         while (!rdy_out)
           @(negedge clk);
         S_in = 300 + i;
         @(posedge clk);
         S_in = 'x;
         @(negedge clk);
      end

      assign ena_in = '0;
   end

   initial begin
      int outs[64];
      for (int row = 0; row < 8; row++) begin
         for (int col = 0; col < 8; col++)
           outs[row + col*8] = row*8 + col;
      end
      
      #2;
      for (int i = 0; i < 64; i++) begin
         while (!ena_out)
           @(posedge clk);
         assert (S_out === outs[i] + 100)
           else $error("got wrong output %d", S_out);
         @(posedge clk);
      end

      for (int i = 0; i < 64; i++) begin
         while (!ena_out)
           @(posedge clk);
         assert (S_out === outs[i] + 200)
           else $error("got wrong output %d", S_out);
         @(posedge clk);
      end

      for (int i = 0; i < 64; i++) begin
         while (!ena_out)
           @(posedge clk);
         assert (S_out === outs[i] + 300)
           else $error("got wrong output %d", S_out);
         @(posedge clk);
      end

      $stop;
   end
   
   initial begin
      rdy_in = '0;
      #20 rdy_in = '1;
      #233 rdy_in = '0;
      #23 rdy_in = '1;
   end
   
endmodule // tb_transpose_buffer
