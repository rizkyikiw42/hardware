// The core JPEG pipeline.  Another module, containing this one, will
// fetch the pixels and store the outputs.
module jpeg_pipeline(input logic clk, input logic rst_ext,
                     input logic [7:0] in_pixel, output logic [15:0] out_bits,
                     output logic [1:0] out_valid,
                     input logic done_image,
                     output logic done_block,
                     output logic done_flush,
                     input logic ena_in, output logic ena_out,
                     input logic rdy_in, output logic rdy_out);

   logic rst;
   logic rst_pipeline;
   assign rst = rst_ext || rst_pipeline;
   
   logic ena_dct, ena_quant, ena_zigzag, ena_runenc, ena_huff, ena_stuff;
   logic rdy_dct, rdy_quant, rdy_zigzag, rdy_runenc, rdy_huff, rdy_stuff;

   logic [7:0] in_dct;
   logic [14:0] in_quant;
   logic [10:0] in_zigzag;
   logic [10:0] in_runenc;
   logic [9:0] in_huff;
   logic [15:0] in_stuff;

   logic [10:0] in_dc_huff;
   logic [3:0] run_huff;
   logic [3:0] size_huff;
   logic dc_huff;
   
   enum logic [1:0] { BUSY, DONE, FLUSH_HUFF, FLUSH_STUFF } state;

   logic [3:0] waitcycles;
   
   assign rst_pipeline = state == FLUSH_STUFF && waitcycles == 4'd3;

   always_ff @(posedge clk)
     if (rst_ext) begin
        done_flush <= '0;
        state <= BUSY;
        waitcycles <= '0;
     end else begin
        case (state)
          BUSY: begin
             if (done_image)
               state <= DONE;
             done_flush <= '0;
          end

          DONE:
            if (waitcycles == 4'd3) begin
               state <= FLUSH_HUFF;
               waitcycles <= '0;
            end else begin
               waitcycles <= waitcycles + 4'd1;
            end

          FLUSH_HUFF:
            if (rdy_stuff)
              state <= FLUSH_STUFF;

          FLUSH_STUFF:
            if (rdy_in) begin
               state <= BUSY;
               done_flush <= '1;
            end

          default:;
        endcase // case (done_image)
     end

   row_buffer ROWBUF
     (.in(in_pixel),
      .out(in_dct),
      .ena_in(ena_in),
      .ena_out(ena_dct),
      .rdy_in(rdy_dct),
      .rdy_out(rdy_out),
      .*);
   
   dct_2d DCT
     (.in(in_dct),
      .out(in_quant),
      .ena_in(ena_dct),
      .ena_out(ena_quant),
      .rdy_in(rdy_quant),
      .rdy_out(rdy_dct),
      .*);

   quantizer QUANT
     (.in(in_quant),
      .out(in_zigzag),
      .ena_in(ena_quant),
      .ena_out(ena_zigzag),
      .rdy_in(rdy_zigzag),
      .rdy_out(rdy_quant),
      .*);
   
   zigzag ZIGZAG
     (.in(in_zigzag),
      .out(in_runenc),
      .ena_in(ena_zigzag),
      .ena_out(ena_runenc),
      .rdy_in(rdy_runenc),
      .rdy_out(rdy_zigzag),
      .*);

   run_encoder RUNENC
     (.in(in_runenc),
      .out(in_huff),
      .ena_in(ena_runenc),
      .ena_out(ena_huff),
      .rdy_in(rdy_huff),
      .rdy_out(rdy_runenc),
      .out_dc(in_dc_huff),
      .run(run_huff),
      .size(size_huff),
      .dc(dc_huff),
      .done(done_block),
      .*);

   huffman_coder HUFF
     (.in(in_huff),
      .out(in_stuff),
      .ena_in(ena_huff),
      .ena_out(ena_stuff),
      .rdy_in(rdy_stuff),
      .rdy_out(rdy_huff),
      .in_dc(in_dc_huff),
      .run(run_huff),
      .size(size_huff),
      .dc(dc_huff),
      .flush(state == FLUSH_HUFF),
      .*);

   byte_stuffer STUFF
     (.in(in_stuff),
      .out(out_bits),
      .ena_in(ena_stuff),
      .ena_out(ena_out),
      .rdy_in(rdy_in),
      .rdy_out(rdy_stuff),
      .flush(state == FLUSH_STUFF),
      .done(),
      .out_valid(out_valid),
      .*);
     
endmodule // jpeg_pipeline
