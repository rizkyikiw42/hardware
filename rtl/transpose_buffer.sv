// Because we're connected to the next DCT module, we write 8 pixels
// when we get one rdy.
module transpose_buffer
  (input logic clk, input logic rst, 
   input logic ena_in, output logic ena_out,
   input logic rdy_in, output logic rdy_out,
   input logic [11:0] S_in, output logic [11:0] S_out);

   logic [6:0] waddr, raddr;
   logic wren, wbuf, rbuf;
   logic [2:0] xw, yw, xr, yr;

   // High when the output buffer contains a valid frame.  We will
   // write the output buffer (in 8 pixel column increments).
   logic outbuf_valid;

   // High when the input buffer is full.
   logic inbuf_full;

   // High when we've waited for the first read on the read buffer.
   logic delay;
   
   assign rbuf = ~wbuf;
   assign waddr = {wbuf, yw, xw};    // For writing in row-major order
   assign raddr = {rbuf, xr, yr} + 1;    // For reading in column-major order

   transpose_mem BUF(clk, S_in, S_out, raddr, waddr, wren);

   always_ff @(posedge clk)
     if (rst) begin
        wbuf <= '0;
        {inbuf_full, yw, xw} <= '0;
        {outbuf_valid, xr, yr} <= 7'b0111111;
        delay <= '0;
     end else begin
        if (ena_in)
          {inbuf_full, yw, xw} <= {inbuf_full, yw, xw} + 6'b1;

        if (ena_out)
          {outbuf_valid, xr, yr} <= {outbuf_valid, xr, yr} + 6'b1;

        delay <= outbuf_valid;
        
        if (inbuf_full && !outbuf_valid) begin
           outbuf_valid <= '1;
           inbuf_full <= '0;
           wbuf <= ~wbuf;
        end
     end

   always_comb begin
      rdy_out = !inbuf_full;
      // Enable the output when the output buffer has a frame in it.
      // The DCT's rdy output will go low after the first pixel, but
      // we need to output an entire column so we also output when the
      // row number is not zero.
      ena_out = outbuf_valid && delay && (rdy_in || yr != '0);
      wren = ena_in;
   end
       
endmodule // transpose_buffer
