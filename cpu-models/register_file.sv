`timescale 1ns/1ps                    // Set time units to nanoseconds with picosecond precision

module register_file (
  input  logic        clk,         // Clock signal for synchronous operations
  input  logic        reset_n,     // Active-low asynchronous reset signal
  input  logic        wr_en_i,     // Write enable input - allows writing to register file
  input  logic [4:0]  rs1_addr_i,  // Read address for source register 1 (5 bits = 32 registers)
  input  logic [4:0]  rs2_addr_i,  // Read address for source register 2 (5 bits = 32 registers)
  input  logic [4:0]  rd_addr_i,   // Write address for destination register
  input  logic [31:0] wr_data_i,   // 32-bit data to be written to destination register
  output logic [31:0] rs1_data_o,  // 32-bit data output from source register 1
  output logic [31:0] rs2_data_o   // 32-bit data output from source register 2
  );
  
  logic [31:0] reg_file [0:31];     // Array of 32 registers, each 32 bits wide
  
  // Synchronous write logic with asynchronous reset
  always_ff @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin              // When reset is asserted (active-low)
	  for (int i=0; i < 32 ; i++) begin  // Loop through all 32 registers
	      reg_file [i] <= 32'b0;    // Initialize each register to zero
		end
	end else if (wr_en_i && (rd_addr_i != 5'b0)) begin  // If write enabled and not writing to register 0
        reg_file[rd_addr_i] <= wr_data_i;  // Write data to the addressed register
	end
   end  
    
   // Asynchronous read operations - combinational logic
   assign rs1_data_o = reg_file[rs1_addr_i];  // Continuously output data from rs1 address
   assign rs2_data_o = reg_file[rs2_addr_i];  // Continuously output data from rs2 address
	  
endmodule