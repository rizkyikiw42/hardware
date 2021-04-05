module tb_jpeg();

   logic clk;
   logic rst;

   logic [2:0] s_address;

   logic s_read;
   logic s_write;

   logic [31:0] s_readdata;
   logic [31:0] s_writedata;

   logic m_waitrequest;

   logic [30:0] m_address;

   logic m_read;
   logic m_write;

   logic [15:0] m_readdata;
   logic [15:0] m_writedata;
   logic [1:0] m_byteenable;
   
   logic irq;

   jpeg DUT(.*);
   
   initial forever begin
      clk = '0;
      #1;
      clk = '1;
      #1;
   end

   initial begin
      s_read = '0;
      s_write = '0;
      s_address = 'x;
      s_writedata = 'x;

      rst = '1;
      @(posedge clk) rst = '0;

      #10; @(posedge clk);
      
      s_address = 0;
      // Little endian width
      s_writedata = 32'h40000000;
      s_write = 1;
      @(posedge clk);

      s_address = 1;
      // Little endian height
      s_writedata = 32'h40000000;
      s_write = 1;
      @(posedge clk);

      s_address = 2;
      // Little endian
      s_writedata = 32'h00000000;
      s_write = 1;
      @(posedge clk);

      s_address = 3;
      // Little endian
      s_writedata = 32'h00000010;
      s_write = 1;
      @(posedge clk);

      // Start
      s_address = 5;
      // Little endian
      s_writedata = 32'h01000000;
      s_write = 1;
      @(posedge clk);

      s_write = 0;

      @(posedge irq);
      $stop;
   end

   // Image is 64 x 64
   logic [7:0] source_mem[64*64*2];
   logic [7:0] dest_mem[64*64*2];
   
   initial begin
      m_readdata = 'x;
      m_waitrequest = 1;

      $readmemh("testimg.yuyv.hex", source_mem);
      
      forever begin
         @(posedge clk);
         m_waitrequest = 1;
         m_readdata = 'x;
         
         if (m_read) begin
            for (int waitcycles = $urandom % 10; waitcycles > 0; waitcycles--)
              @(posedge clk);
            m_waitrequest = 0;
            $display("read %x", m_address);
            if (m_address < (32'h10000000 >> 1))
              m_readdata = {source_mem[2*m_address], source_mem[2*m_address + 1]};
            else
              $error("tried to read from dst");
            @(posedge clk);
            m_waitrequest = 1;
         end else if (m_write) begin
            for (int waitcycles = $urandom % 10; waitcycles > 0; waitcycles--)
              @(posedge clk);
            m_waitrequest = 0;
            $display("write %x %x", m_address, m_writedata);
            if (m_address >= (32'h10000000 >> 1)) begin
               if (m_byteenable[1])
                 dest_mem[2*m_address[15:0]] = m_writedata[15:8];
               if (m_byteenable[0])
                 dest_mem[2*m_address[15:0] + 1] = m_writedata[7:0];
            end else
              $error("tried to write to src");
            @(posedge clk);
            m_waitrequest = 1;
         end
      end
   end

   // always @(posedge clk)
   //   if (DUT.PIPE.RUNENC.ena_out)
   //     $display("out: %b %d %d %b %d",
   //              DUT.PIPE.RUNENC.dc,
   //              signed'(DUT.PIPE.RUNENC.out_dc),
   //              DUT.PIPE.RUNENC.run,
   //              DUT.PIPE.RUNENC.out,
   //              DUT.PIPE.RUNENC.size);

   // always @(posedge clk)
   //   if (DUT.PIPE.HUFF.shift_ena)
   //     $display("huff: %b %d", DUT.PIPE.HUFF.shift_code, DUT.PIPE.HUFF.shift_size);
   
   // always @(posedge clk)
   //   if (DUT.PIPE.STUFF.ena_in)
   //     $display("stuff in: %x", DUT.PIPE.STUFF.in);

endmodule // tb_jpeg
