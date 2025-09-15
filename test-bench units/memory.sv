`timescale 1ns/1ps
module memory (
    input  logic           clk,
    input  logic           reset_n,
    input  logic           data_mem_wr,
    input  logic [31:0]    data_mem_addr,
    input  logic [31:0]    data_mem_wr_data,
    input  logic           data_mem_req,
    input  logic [ 1:0]    data_mem_byte_en,
    output logic [31:0]    mem_rd_data,

    input  logic           is_vector_i,
    input  logic [127:0]   vec_data_wr_data_i [4], // 4 vectors each 128 bits
    output logic [127:0]   vec_mem_rd_data_o  [4]  // 4 vectors each 128 bits
);

    logic [127:0] memory_array [0:1023];
    int file;
    int word_idx;

    assign word_idx = data_mem_addr[31:4];

    // WRITE logic
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // optional reset
        end else if (data_mem_req && data_mem_wr && !is_vector_i) begin
            case (data_mem_byte_en)
                2'b00: memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] <= 
                        (memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] & 32'hFFFFFF00) |
                        {24'b0, data_mem_wr_data[7:0]};
                2'b01: memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] <= 
                        (memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] & 32'hFFFF0000) |
                        {16'b0, data_mem_wr_data[15:0]};
                2'b11: memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] <= data_mem_wr_data;
            endcase
        end else if (data_mem_req && data_mem_wr && is_vector_i) begin
            memory_array[word_idx    ] <= vec_data_wr_data_i[0];
            memory_array[word_idx + 1] <= vec_data_wr_data_i[1];
            memory_array[word_idx + 2] <= vec_data_wr_data_i[2];
            memory_array[word_idx + 3] <= vec_data_wr_data_i[3];
        end
    end

    // READ logic
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mem_rd_data <= 32'b0;
        end else if (data_mem_req && !data_mem_wr && !is_vector_i) begin
            mem_rd_data <= memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32];
        end else if (data_mem_req && !data_mem_wr && is_vector_i) begin
            vec_mem_rd_data_o[0] <= memory_array[word_idx    ];
            vec_mem_rd_data_o[1] <= memory_array[word_idx + 1];
            vec_mem_rd_data_o[2] <= memory_array[word_idx + 2];
            vec_mem_rd_data_o[3] <= memory_array[word_idx + 3];
        end
    end

    // ✅ Write memory to file at end of simulation
    initial begin
        wait (reset_n == 1);
        #2000; // Enough delay before simulation ends

        $display("📝 Writing memory to file...");
        file = $fopen("C:/Users/WAKED/Desktop/r32imv/mem.results", "w");
        if (file) begin
            for (int i = 0; i < 1024; i++) begin
                $fwrite(file, "Addr %03d: %0d %0d %0d %0d\n", i,
                    memory_array[i][127:96],
                    memory_array[i][95:64],
                    memory_array[i][63:32],
                    memory_array[i][31:0]);
            end
            $fclose(file);
            $display("✅ Memory dump complete: C:/Users/WAKED/Desktop/r32imv/mem.results");
        end else begin
            $fatal(2, "❌ Could not open C:/Users/WAKED/Desktop/r32imv/mem.results");
        end
    end

endmodule
