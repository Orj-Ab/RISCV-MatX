`timescale 1ns/1ps

module tb_dual_memory;

    import yarp_pkg::*;

    logic         clk;
    logic         reset_n;

    logic         data_wr;
    logic         data_req;
    logic [31:0]  addr;
    logic [31:0]  wr_data;
    logic [1:0]   byte_en;
    logic         zero_ext;
    logic         is_vector;

    logic [31:0]        scalar_rd_mem, scalar_rd_data;
    logic [127:0]       vec_wr_data [4];
    logic [127:0]       vec_rd_mem  [4];
    logic [127:0]       vec_rd_data [4];

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        reset_n = 0;
        #20;
        reset_n = 1;
    end

    // Instantiate both memory modules
    memory u_memory (
        .clk(clk),
        .reset_n(reset_n),
        .data_mem_wr(data_wr),
        .data_mem_addr(addr),
        .data_mem_wr_data(wr_data),
        .data_mem_req(data_req),
        .data_mem_byte_en(byte_en),
        .mem_rd_data(scalar_rd_mem),
        .is_vector_i(is_vector),
        .vec_data_wr_data_i(vec_wr_data),
        .vec_mem_rd_data_o(vec_rd_mem)
    );

    data_mem u_data_mem (
        .clk(clk),
        .data_wr_i(data_wr),
        .data_req_i(data_req),
        .data_addr_i(addr),
        .data_wr_data_i(wr_data),
        .data_byte_en_i(byte_en),
        .data_zero_extnd_i(zero_ext),
        .is_vector_i(is_vector),
        .data_mem_rd_data_o(scalar_rd_data),
        .vec_data_wr_data_i(vec_wr_data),
        .vec_mem_rd_data_o(vec_rd_data)
    );

    // Test procedure
    initial begin
        wait (reset_n);

        // Test scalar write and read
        is_vector = 0;
        data_req  = 1;
        data_wr   = 1;
        addr      = 32'h00000010;
        wr_data   = 32'hDEADBEEF;
        byte_en   = 2'b11; // full word
        zero_ext  = 1;

        #10 data_wr = 0;

        #10; // Wait for read cycle
        $display("Scalar Read (MEM): 0x%08h", scalar_rd_mem);
        $display("Scalar Read (DMEM): 0x%08h", scalar_rd_data);

        // Test vector write
        is_vector = 1;
        data_wr   = 1;
        for (int i = 0; i < 4; i++) begin
            vec_wr_data[i] = 128'h1111_0000_0000_0000_0000_0000_0000_0000 + i;
        end
        addr = 32'h00000020;
        #10 data_wr = 0;

        #10 data_req = 1; // read vector back
        #10;

        $display("\nVector Memory Dump:");
        for (int i = 0; i < 4; i++) begin
            $display("MEM[%0d] = 0x%032h", i, vec_rd_mem[i]);
            $display("DMEM[%0d] = 0x%032h", i, vec_rd_data[i]);
        end

        #20;
        $finish;
    end

endmodule
