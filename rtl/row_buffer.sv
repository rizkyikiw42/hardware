module row_buffer(input logic clk, input logic rst,
                  input logic ena_in, output logic ena_out,
                  input logic rdy_in, output logic rdy_out,
                  input logic [7:0] in, output logic [7:0] out);

   logic [2:0] idx;
   logic reading;
   logic [7:0] coefs[8];
   
   always_ff @(posedge clk)
     if (rst) begin
        idx <= '0;
        reading <= '1;
     end else begin
        if (ena_in) begin
           coefs[idx] <= in;
           idx <= idx + 3'b1;

           if (idx == '1) begin
              reading <= '0;
           end
        end

        if (ena_out) begin
           idx <= idx + 3'b1;

           if (idx == '1) begin
              reading <= '1;
           end
        end
     end
   
   always_comb begin
      rdy_out = reading;
      ena_out = !reading && (rdy_in || idx != '0);
      out = coefs[idx];
   end
   
endmodule // row_buffer
