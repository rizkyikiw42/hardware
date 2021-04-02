// The core JPEG pipeline.  Another module, containing this one, will
// fetch the pixels and store the outputs.
module jpeg_pipeline(input logic clk, input logic rst,
                     input logic [7:0] in_pixel, output logic [15:0] out_bits,
                     input logic ena_in, output logic ena_out,
                     input logic rdy_in, output logic rdy_out);

   logic ena_quant, ena_zigzag, ena_runenc, ena_huff, ena_stuff;
   logic rdy_quant, rdy_zigzag, rdy_runenc, rdy_huff, rdy_stuff;

   logic [14:0] in_quant;
   logic [10:0] in_zigzag;
   logic [10:0] in_runenc;
   logic [9:0] in_huff;
   logic [15:0] in_stuff;

   logic [10:0] in_dc_huff;
   logic [3:0] run_huff;
   logic [3:0] size_huff;
   logic dc_huff;
   
   dct_2d DCT
     (.in(in_pixel),
      .out(in_quant),
      .ena_in(ena_in),
      .ena_out(ena_quant),
      .rdy_in(rdy_quant),
      .rdy_out(rdy_out),
      .*);

   quantizer QUANT
     (.in(in_quant),
      .out(in_zigzag),
      .ena_in(ena_quant),
      .ena_out(ena_zigzag),
      .rdy_in(rdy_zigzag),
      .rdy_out(rdy_quant),
      .*);

   // row_buffer ROWBUF
   //   (.in(in_rowbuf),
   //    .out(in_runenc),
   //    .ena_in(ena_rowbuf),
   //    .ena_out(ena_runenc),
   //    .rdy_in(rdy_runenc),
   //    .rdy_out(rdy_rowbuf),
   //    .*);
   
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
      .done(),
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
      .flush('0),
      .*);

   byte_stuffer STUFF
     (.in(in_stuff),
      .out(out_bits),
      .ena_in(ena_stuff),
      .ena_out(ena_out),
      .rdy_in(rdy_in),
      .rdy_out(rdy_stuff),
      .flush('0),
      .done(),
      .*);
     
endmodule // jpeg_pipeline
