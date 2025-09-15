`timescale 1ns/1ps                        // Simulation timescale: 1 ns, precision 1 ps

module data_mem 
    import yarp_pkg ::*;                  // Import constants/types from yarp_pkg
(
   input  logic          clk,             // Clock input for synchronous write operations
   input  logic   [31:0] data_wr_data_i, // Scalar data to write (32-bit)
   input  logic          data_wr_i,      // Write enable signal for scalar/word write
   input  logic          data_req_i,     // Request signal: read/write memory
   input  logic   [31:0] data_addr_i,    // Address for memory access
   input  logic   [ 1:0] data_byte_en_i, // Byte/half-word/word selection
   input  logic          data_zero_extnd_i, // Zero extension flag for loads
   input  logic          is_vector_i,    // Indicates vector operation

   output logic   [31:0] data_mem_rd_data_o, // Output for scalar read

   input  wire   [127:0] vec_data_wr_data_i [4], // Vector write input (4 vectors)
   output logic  [127:0] vec_mem_rd_data_o  [4]  // Vector read output (4 vectors)
);

    int file;                               // File handle for dumping memory contents
    logic [127:0] data_memory [0:31] = '{default: '0}; // 32 x 128-bit memory array

    int word_idx;                            // Index of 128-bit word
    int slice_idx;                           // Index of 32-bit slice within 128-bit word

    assign word_idx  = data_addr_i[31:4];    // Compute word index from address (aligned to 128 bits)
    assign slice_idx = data_addr_i[3:2];     // Compute which 32-bit slice to access

    // Sequential write logic
    always_ff @(posedge clk) begin
        if (data_req_i && data_wr_i) begin           // Only write if requested and write enable
            if (is_vector_i) begin                   // Vector write
                for (int i = 0; i < 4; i++) begin
                    data_memory[word_idx + i] <= vec_data_wr_data_i[i]; // Write each vector element
                end
            end else begin                            // Scalar write
                case (data_byte_en_i)
                    BYTE:      data_memory[word_idx][slice_idx*32 +: 8]  <= data_wr_data_i[7:0];   // Byte write
