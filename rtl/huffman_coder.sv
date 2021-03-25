module huffman_coder(input logic clk, input logic rst,
                     input logic ena_in, output logic ena_out,
                     input logic rdy_in, output logic rdy_out,
                     input logic [9:0] in,
                     input logic signed [10:0] in_dc,
                     input logic [3:0] run, size,
                     input logic dc,
                     input logic flush,
                     output logic [15:0] out);

   typedef struct packed {
     logic [4:0] size;
     logic [15:0] code;
   } symbol;

   symbol ac_codes[16 * 11];
   initial $readmemb("ac_codes.bin", ac_codes);
   
   symbol dc_codes[12];
   initial $readmemb("dc_codes.bin", dc_codes);

   logic shift_ena;
   logic shift_rdy;
   logic shift_flush;
   logic [15:0] shift_code;
   logic [4:0] shift_size;
   
   code_shifter #(.WIDTH(16))
   SHIFTER(.ena_in(shift_ena),
           .ena_out(ena_out),
           .rdy_in(rdy_in),
           .rdy_out(shift_rdy),
           .flush(flush),
           .code(shift_code),
           .size(shift_size),
           .out(out),
           .*);
   
   logic signed [10:0] dc_prev;
   logic signed [10:0] dc_diff;
   logic [9:0] dc_val;
   logic [3:0] dc_size;
   
   ones_encoder #(.WIDTH(11))
   ONESENC(.in(dc_diff),
           .val(dc_val),
           .size(dc_size));

   logic busy;
   logic code_written;
   symbol code;
   symbol val;
   
   always_ff @(posedge clk)
     if (rst) begin
        dc_prev <= '0;
        busy <= '0;
        code_written <= '0;
     end else begin
        busy <= ena_in || (busy && !code_written);

        if (ena_in) begin
           if (dc) begin
              code <= dc_codes[dc_size];
              val <= '{{1'b0, dc_size}, dc_val};
              dc_prev <= in_dc;
           end else begin
              if (size == '0) begin
                 if (run == '0)       // eob
                   code <= '{5'd4, 16'b1010};
                 else if (run == '1)  // zrl
                   code <= '{5'd11, 16'b11111111001};
                 else
                   code <= 'x;
                 val <= '{5'b0, 16'b0};
              end else begin
                 code <= ac_codes[{size, run}];
                 val <= '{{1'b0, size}, {6'b0, in}};
              end // else: !if(size == '0)
           end // else: !if(dc)
        end // if (ena_in)

        if (shift_ena)
          code_written <= !code_written;
     end // else: !if(rst)
   
   always_comb begin
      rdy_out = !busy;
      shift_ena = busy && shift_rdy;
      dc_diff = in_dc - dc_prev;

      if (code_written)
        {shift_size, shift_code} = {val.size, val.code};
      else
        {shift_size, shift_code} = {code.size, code.code};
   end // always_comb
   
endmodule // huffman_coder
