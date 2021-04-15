// Accepts, in zigzag order, the coefficients in a block.  Produces
// "runs" consisting of how many zeroes (other than for the DC
// coefficient) preceded this nonzero coefficient.
module run_encoder(input logic clk, input logic rst,
                   input logic ena_in, output logic ena_out,
                   input logic rdy_in, output logic rdy_out,
                   input logic signed [10:0] in,
                   output logic [9:0] out,
                   output logic signed [10:0] out_dc,
                   output logic [3:0] run, size,
                   output logic dc,
                   output logic done);

   logic [6:0] idx;             // Number of coefs processed
   logic [5:0] count;           // Number of zeros in this run
   logic signed [10:0] in_prev; // Saved recent nonzero coef
   logic signed [10:0] in_cur;
   logic zrl;                   // Last ena_out we put a ZRL

   logic [9:0] ones_out;
   logic [3:0] ones_size;

   ones_encoder #(.WIDTH(11))
   ONESENC(.in(in_cur),
           .val(ones_out),
           .size(ones_size));
   
   always_ff @(posedge clk)
     if (rst || done) begin
        idx <= '0;
        count <= '0;
        zrl <= '0;
     end else begin
        if (ena_in) begin
           in_prev <= in_cur;
           idx <= idx + 6'b1;
           if (in == '0 && !dc)
             count <= count + 6'b1;
        end

        if (ena_out) begin
           if (count < 6'h10) begin
              count <= '0;
              zrl <= '0;
           end else begin
              count <= count - 6'h10;
              zrl <= '1;
           end
        end
     end

   always_comb begin
      // Allow the DC coefficient through without encoding.
      dc = idx == '0;
      done = idx == 7'b1000000;
      out_dc = in;
      
      // Enable the output when we receive a nonzero input (or the
      // first input, regardless), or we've just emitted a ZRL, or
      // we've completed the block and want to emit an EOB.
      ena_out = rdy_in &&
        (ena_in && (in != '0 || dc) 
        || zrl 
        || done && count != '0);
      rdy_out = !done && rdy_in && !zrl;
      
      if (zrl)
        in_cur = in_prev;
      else
        in_cur = in;

      out = ones_out;
      size = ones_size;

      if (done && count != '0) begin
         run = 4'h0;
         out = 'x;
         size = 4'h0;
      end else if (count >= 6'h10) begin
         run = 4'hf;
         out = 'x;
         size = 4'h0;
      end else
        run = count[3:0];
   end

endmodule // run_encoder
