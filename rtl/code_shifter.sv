// Inputs: 10000000001 1000001 <flush>
// Outputs: 1000000000110000 0100000000000000
module code_shifter
  #(parameter WIDTH=32)
   (input logic clk, input logic rst,
    input logic ena_in, output logic ena_out,
    input logic rdy_in, output logic rdy_out,
    input logic flush,
    input logic [WIDTH-1:0] code, input logic [$clog2(WIDTH):0] size,
    output logic [WIDTH-1:0] out);

   logic [$clog2(WIDTH)-1:0] fill;
   logic [$clog2(WIDTH):0] newfill;

   logic [WIDTH-1:0] leftover;

   logic [WIDTH-1:0] maskcode;

   always_ff @(posedge clk)
     if (rst || flush && ena_out) begin
        fill <= '0;
        leftover <= '0;
     end else begin
        if (ena_in) begin
           fill <= newfill[$clog2(WIDTH)-1:0];

           if (ena_out)
             leftover <= maskcode << WIDTH - newfill[$clog2(WIDTH)-1:0];
           else
             leftover <= out;
        end
     end

   always_comb begin
      newfill = fill + size;
      ena_out = rdy_in && ((ena_in && newfill[$clog2(WIDTH)]) || (out != '0 && flush));
      rdy_out = rdy_in;

      maskcode = code & ~('1 << size);
      
      if (flush)
        out = leftover;
      else begin
         if (fill + size > WIDTH)
           out = leftover | (maskcode >> fill + size - WIDTH);
         else
           out = leftover | (maskcode << WIDTH - fill - size);
      end
   end

endmodule // code_shifter
