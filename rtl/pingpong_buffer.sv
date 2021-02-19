module pingpong_buffer
  #(parameter DEPTH=8, parameter WIDTH=8)
   (input logic clk, rst, ena_in, rdy_in,
                   input logic [WIDTH-1:0] in,
                   output logic ena_out, rdy_out,
                   output logic [WIDTH-1:0] out[DEPTH]);
   logic [$clog2(DEPTH)-1:0] state;
   logic [WIDTH-1:0] shiftreg[DEPTH-1];

   always_ff @(posedge clk)
     if (rst)
       state <= 0;
     else if (ena_in) begin
        if (state == DEPTH - 1) begin
           state <= 0;
           out[DEPTH-1] <= in;
           out[0:DEPTH-2] <= shiftreg;
        end else
          state <= state + 1;

        shiftreg[DEPTH-2] <= in;
        for (int i = DEPTH-3; i >= 0; i--)
          shiftreg[i] <= shiftreg[i + 1];
     end

   always_comb begin
      rdy_out = rdy_in;
      ena_out = ena_in;
   end
endmodule // pingpong_buffer
