module ones_encoder
  #(parameter WIDTH=8)
   (input logic signed [WIDTH-1:0] in,
    output logic [WIDTH-2:0] val,
    output logic [$clog2(WIDTH)-1:0] size);

   logic signed [WIDTH-2:0] in_abs;

   always_comb begin
      if (in >= 0) begin
         in_abs = in;
         val = in_abs;
      end else begin
         in_abs = -in;
         val = ~in_abs;
      end

      for (size = WIDTH-1; size > 0; size--)
        if (in_abs[size-1])
          break;
   end

endmodule // ones_encoder
