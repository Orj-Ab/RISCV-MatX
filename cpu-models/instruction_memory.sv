`timescale 1ns/1ps
// Defines the time unit and precision for simulation: 1 nanosecond unit, 1 picosecond precision

module instruction_memory (
    input  logic         instr_mem_req_i,       // Input signal: high when instruction memory is being accessed
    input  logic [31:0]  instr_mem_addr_i,      // 32-bit input address to read instruction from
    output logic [31:0]  instr_mem_rd_data_o    // 32-bit output: instruction read from memory
);

    // Memory declaration: 496 words (0..495), each 32 bits wide
    logic [31:0] memory  [0:495]; 
    
    initial 
    begin 
        // Load instructions from external hex file into memory at simulation start
        $readmemh("C:/Users/WAKED/Desktop/r32imv/MA.txt", memory);
    end

    // Always block triggered whenever inputs change (combinational logic)
    always_ff @(*) 
    begin
        if (instr_mem_req_i) 
        begin
            // Output the instruction at the requested address
            // Using instr_mem_addr_i[31:2] to convert byte address to word index
            instr_mem_rd_data_o <= memory[instr_mem_addr_i[31:2]];
        end  
    end

endmodule
