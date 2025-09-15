`timescale 1ns/1ps                 // Simulation time unit: 1 ns, precision: 1 ps

module memory (
    input  logic           clk,              // System clock
    input  logic           reset_n,          // Active-low reset
    input  logic           data_mem_wr,      // Write enable (1=write, 0=read)
    input  logic [31:0]    data_mem_addr,    // Memory address for access
    input  logic [31:0]    data_mem_wr_data, // Data to write (scalar mode)
    input  logic           data_mem_req,     // Memory request (valid access signal)
    input  logic [ 1:0]    data_mem_byte_en, // Byte enable for partial writes
    output logic [31:0]    mem_rd_data,      // Output for scalar read data

    input  logic           is_vector_i,      // Select between scalar (0) and vector (1) mode
    input  logic [127:0]   vec_data_wr_data_i [4], // Input vector data to write (4 × 128 bits)
    output logic [127:0]   vec_mem_rd_data_o  [4]  // Output vector data read (4 × 128 bits)
);

    // Memory storage: 1024 entries, each 128 bits wide
    logic [127:0] memory_array [0:1023];

    int file;      // File handle for dumping memory at the end
    int word_idx;  // Index for addressing memory entries

    // Map the upper address bits (31:4) to memory index
    assign word_idx = data_mem_addr[31:4];

    // ================================
    // WRITE Logic
    // ================================
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // On reset, memory can optionally be cleared (not implemented here)
        end else if (data_mem_req && data_mem_wr && !is_vector_i) begin
            // ----- Scalar write -----
            case (data_mem_byte_en)
                2'b00: // Write only 8 bits (byte)
                    memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] <= 
                        (memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] & 32'hFFFFFF00) |
                        {24'b0, data_mem_wr_data[7:0]};
                2'b01: // Write 16 bits (halfword)
                    memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] <= 
                        (memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] & 32'hFFFF0000) |
                        {16'b0, data_mem_wr_data[15:0]};
                2'b11: // Write full 32-bit word
                    memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32] <= data_mem_wr_data;
            endcase
        end else if (data_mem_req && data_mem_wr && is_vector_i) begin
            // ----- Vector write (4 × 128-bit) -----
            memory_array[word_idx    ] <= vec_data_wr_data_i[0];
            memory_array[word_idx + 1] <= vec_data_wr_data_i[1];
            memory_array[word_idx + 2] <= vec_data_wr_data_i[2];
            memory_array[word_idx + 3] <= vec_data_wr_data_i[3];
        end
    end

    // ================================
    // READ Logic
    // ================================
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mem_rd_data <= 32'b0; // Clear scalar read output on reset
        end else if (data_mem_req && !data_mem_wr && !is_vector_i) begin
            // ----- Scalar read -----
            mem_rd_data <= memory_array[data_mem_addr[11:4]][(data_mem_addr[3:2]*32) +: 32];
        end else if (data_mem_req && !data_mem_wr && is_vector_i) begin
            // ----- Vector read (fetch 4 × 128-bit words) -----
            vec_mem_rd_data_o[0] <= memory_array[word_idx    ];
            vec_mem_rd_data_o[1] <= memory_array[word_idx + 1];
            vec_mem_rd_data_o[2] <= memory_array[word_idx + 2];
            vec_mem_rd_data_o[3] <= memory_array[word_idx + 3];
        end
    end

    // ================================
    // MEMORY DUMP TO FILE (Simulation Only)
    // ================================
    initial begin
        wait (reset_n == 1);      // Wait until reset is released
        #2000;                    // Wait some time before dumping memory

        $display("📝 Writing memory to file...");
        file = $fopen("C:/Users/WAKED/Desktop/r32imv/mem.results", "w");
        if (file) begin
            // Write memory contents to file (all 1024 entries)
            for (int i = 0; i < 1024; i++) begin
                $fwrite(file, "Addr %03d: %0d %0d %0d %0d\n", i,
                    memory_array[i][127:96],  // Word 3
                    memory_array[i][95:64],   // Word 2
                    memory_array[i][63:32],   // Word 1
                    memory_array[i][31:0]);   // Word 0
            end
            $fclose(file);
            $display("✅ Memory dump complete: C:/Users/WAKED/Desktop/r32imv/mem.results");
        end else begin
            // Error if file cannot be opened
            $fatal(2, "❌ Could not open C:/Users/WAKED/Desktop/r32imv/mem.results");
        end
    end

endmodule
