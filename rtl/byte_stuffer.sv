module byte_stuffer(input logic clk, input logic rst,
                    input logic ena_in, output logic ena_out,
                    input logic rdy_in, output logic rdy_out,
                    input logic flush, output logic done,
                    input logic [15:0] in, output logic [15:0] out);

   logic [15:0] leftover;
   logic [1:0] leftover_valid;

   always_ff @(posedge clk)
     if (rst) begin
        leftover_valid <= '0;
        done <= '0;
     end else if (ena_out) begin
        if (flush) begin
           if (leftover_valid[0] && leftover[7:0] == '1) begin
              leftover_valid <= 2'b10;
              leftover <= {8'b0, 8'bx};
           end else begin
              leftover_valid <= 2'b00;
              leftover <= 'x;
              done <= '1;
           end
        end else
          casez (leftover_valid)
            2'b00:
              if (in[15:8] == '1) begin
                 if (in[7:0] == '1) begin
                    leftover_valid <= 2'b11;
                    leftover <= {in[7:0], 8'b0};
                 end else begin
                    leftover_valid <= 2'b10;
                    leftover <= {in[7:0], 8'bx};
                 end
              end else begin
                 leftover_valid <= 2'b00;
                 leftover <= 'x;
              end
            
            2'b10:
              if (in[15:8] == '1) begin
                 leftover_valid <= 2'b11;
                 leftover <= {8'b0, in[7:0]};
              end else begin
                 if (in[7:0] == '1) begin
                    leftover_valid <= 2'b11;
                    leftover <= {in[7:0], 8'b0};
                 end else begin
                    leftover_valid <= 2'b10;
                    leftover <= {in[7:0], 8'bx};
                 end
              end

            2'b11: begin
               if (leftover[7:0] == '1) begin
                  leftover_valid <= 2'b10;
                  leftover <= {8'b0, 8'bx};
               end else begin
                  leftover_valid <= 2'b00;
                  leftover <= 'x;
               end
            end

            default: begin
               leftover_valid <= 'x;
               leftover <= 'x;
            end
          endcase // casez (leftover_valid)
     end else if (flush && !(|leftover_valid)) // if (ena_out)
       done <= '1;
   
   always_comb begin
      rdy_out = rdy_in && !(&leftover_valid);
      ena_out = rdy_in && (ena_in || &leftover_valid || (flush && |leftover_valid));
      
      // We will never have leftover 0xFF, since we'll put 0xFF 00
      // instead.  However, 0x12 FF may happen.
      if (flush) begin
         if (leftover_valid[0])
           out = leftover;
         else
           out = {leftover[15:8], 8'b0};
      end else begin 
         casez (leftover_valid)
           2'b00: 
             if (in[15:8] == '1)
               out = {in[15:8], 8'b0};
             else
               out = in;
           
           2'b10: out = {leftover[15:8], in[15:8]};
           2'b11: out = leftover;
           default: out = 'x;
         endcase // casez (leftover_valid)
      end
   end

endmodule // byte_stuffer
