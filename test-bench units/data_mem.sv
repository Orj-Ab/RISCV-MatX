`timescale 1ns/1ps

module data_mem 
    import yarp_pkg ::*; 
(
   input  logic          clk,                 // Added clock input for FF logic
   input  logic   [31:0] data_wr_data_i,
   input  logic          data_wr_i,
   input  logic          data_req_i,
   input  logic   [31:0] data_addr_i,
   input  logic   [ 1:0] data_byte_en_i,
   input  logic          data_zero_extnd_i,  // Zero extension enable
   input  logic          is_vector_i,

   output logic   [31:0] data_mem_rd_data_o,

   input  wire   [127:0] vec_data_wr_data_i [4], // Declared explicitly as 'wire'
   output logic  [127:0] vec_mem_rd_data_o  [4]  // 4 vectors each 128 bits
);
    int file; // File handle for writing memory contents
    logic [127:0] data_memory [0:31] = '{default: '0};

    int word_idx;    // 128-bit aligned index
    int slice_idx;   // Select 32-bit slice (0 to 3)

    assign word_idx   = data_addr_i[31:4];
    assign slice_idx  = data_addr_i[ 3:2];

    // Sequential Write Operations 
    always_ff @(posedge clk) begin
        if (data_req_i && data_wr_i) begin
            if (is_vector_i) begin
                // Vector write logic
                for (int i = 0; i < 4; i++) begin
                    data_memory[word_idx + i] <= vec_data_wr_data_i[i];
                end
            end else begin
                // Scalar write logic
                case (data_byte_en_i)
                    BYTE:      data_memory[word_idx][slice_idx*32 +: 8]  <= data_wr_data_i[7:0];
                    HALF_WORD: data_memory[word_idx][slice_idx*32 +: 16] <= data_wr_data_i[15:0];
                    default:   data_memory[word_idx][slice_idx*32 +: 32] <= data_wr_data_i;
                endcase
            end
        end
    end

    // Combinational Read Operations 
    always_comb begin
        if (data_req_i) begin
            if (is_vector_i) begin
                // Vector read logic
                for (int i = 0; i < 4; i++) begin
                    vec_mem_rd_data_o[i] = data_memory[word_idx + i];
                end
            end else begin
                // Scalar read logic
                logic [31:0] raw_data;
                raw_data = data_memory[word_idx][slice_idx*32 +: 32];

                // **Apply Zero/Sign Extension**
                case (data_byte_en_i)
                    BYTE: 
                        data_mem_rd_data_o = data_zero_extnd_i ? {24'b0, raw_data[7:0]} : 
                                                             {{24{raw_data[7]}}, raw_data[7:0]};
                    HALF_WORD: 
                        data_mem_rd_data_o = data_zero_extnd_i ? {16'b0, raw_data[15:0]} : 
                                                             {{16{raw_data[15]}}, raw_data[15:0]};
                    default: 
                        data_mem_rd_data_o = raw_data;
                endcase
            end
        end else begin
            data_mem_rd_data_o = 32'b0;
        end
    end

    // dump data_memory contents to file: data_mem.results
    final begin
        file = $fopen("data_mem.results", "w");
        if (file) begin
            for (int i = 0; i < 32; i++) begin
                $fwrite(file, "Addr %02d: %08h %08h %08h %08h\n", i,
                    data_memory[i][127:96],
                    data_memory[i][95:64],
                    data_memory[i][63:32],
                    data_memory[i][31:0]);
            end
            $fclose(file);
            $display("Memory contents written to data_mem.results");
        end else begin
            $fatal(2, "Could not open data_mem.results for writing.");
        end
    end


endmodule
