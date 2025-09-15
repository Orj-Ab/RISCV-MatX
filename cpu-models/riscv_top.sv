`timescale 1ns/1ps
module riscv_top
  import yarp_pkg::*; 
# (    	
  parameter RESET_PC = 32'h0       // Initial program counter value
) (
	input  logic clk,                // System clock
	input  logic reset_n             // Active-low asynchronous reset
);

	// -------------------------------
	// Internal signals for datapath
	// -------------------------------
	logic             instr_mem_req; // Instruction memory request
	logic   [31:0]    instr_addr;    // Instruction memory address
	logic   [31:0]    instr;         // Current fetched instruction
	logic   [31:0]    pc_q;          // Current PC value
	logic   [31:0]    instr_instr;   // Instruction memory output
	logic   [ 4:0]    rs1, rs2, rd;  // Register addresses
	logic   [31:0]    rs1_data, rs2_data, wr_data; // Register data and write-back
	logic   [31:0]    alu_opr_a, alu_opr_b;        // ALU operands
	logic   [ 3:0]    alu_func;                   // ALU function select
	logic   [31:0]    alu_res;                    // ALU result
	logic             r_type,i_type,s_type,b_type,u_type,j_type; // Instruction type flags
	logic   [ 6:0]    opcode;                     // Instruction opcode
	logic   [ 6:0]    funct7;                     // funct7 field
	logic   [ 2:0]    funct3;                     // funct3 field
	logic   [31:0]    imm;                        // Immediate value
	logic             branch_taken;               // Branch decision
	logic             zero_extnd;                 // Load zero extension
	logic             data_req, data_wr;          // Data memory request & write enable
	logic             pc_sel, op1_sel, op2_sel;   // ALU and PC mux selects
	logic             rf_wr_en;                   // Register file write enable
	logic   [31:0]    mem_rd_data, mem_rd_data_from_mem, mem_rd_data_final; // Memory outputs
	logic   [ 1:0]    rf_wr_data_sel, vrf_wr_data_sel; // Write-back source select
	logic   [ 1:0]    data_byte;                  // Memory access size
	logic   [31:0]    next_seq_pc, next_pc;       // Next PC values
	logic             reset_seen_q;               // Tracks reset completion

	// Vector signals
	logic             is_vector_load, is_vector_store, is_vector_mmul; // Instruction flags
	logic             is_vector_load_o, is_vector_store_o, is_vector_mmul_o; // Output flags
	logic             vrf_wr_en;                  // Vector register file write enable
	logic             valu_funct;                 // Vector ALU operation
	logic [127:0]     vec_data_addr_i[4];         // Vector ALU output
	logic [127:0]     v_rs1_data[4], v_rs2_data[4]; // Vector register inputs
	logic [127:0]     v_mem_rd_data[4];          // Vector memory outputs
	logic [127:0]     v_wr_data[4];              // Vector register write-back
	logic [127:0]     v_mem_rd_data_final[4];    // Final vector memory read

	// -------------------------------
	// Program counter logic
	// -------------------------------
	assign next_seq_pc = pc_q + 32'h4;            // Sequential PC increment
	assign next_pc     = (branch_taken | pc_sel) ? {alu_res[31:1],1'b0} : next_seq_pc; // Branch or jump

	// -------------------------------
	// Write-back selection
	// -------------------------------
	assign wr_data = (rf_wr_data_sel == ALU) ? alu_res :
	                 (rf_wr_data_sel == MEM) ? mem_rd_data_final :
	                 (rf_wr_data_sel == IMM) ? imm :
	                                           next_seq_pc;

	// ALU operand selection
	assign alu_opr_a = op1_sel ? pc_q : rs1_data;
	assign alu_opr_b = op2_sel ? imm  : rs2_data;

	// Connect to memory ports
	assign instr_mem_req_o      = instr_mem_req;
	assign instr_mem_addr_o     = instr_addr;
	assign instr_mem_rd_data_i  = instr_instr;
	assign data_mem_rd_data_i   = mem_rd_data;
	assign data_mem_addr_o      = alu_res;
	assign data_mem_byte_en_o   = data_byte;
	assign data_mem_wr_o        = data_wr;
	assign data_mem_req_o       = data_req;

	// -------------------------------
	// Module instantiations
	// -------------------------------
	instruction_memory u_yarp_instruction_memory (...); // Fetches instructions
	fetch u_yarp_fetch (...);                            // Instruction fetch logic
	decode u_yarp_decode (...);                          // Instruction decoding
	register_file u_yarp_register_file (...);           // Scalar register file
	v_regfile u_yarp_v_register_file (...);             // Vector register file
	control_unit u_yarp_control_unit (...);             // Generates control signals
	branch_control u_yarp_branch_control (...);         // Branch decision logic
	execute u_yarp_execute (...);                        // ALU execution
	valu u_yarp_v_alu (...);                             // Vector ALU
	data_mem u_yarp_data_mem (...);                     // Vector/scalar data memory
	memory u_yarp_memory (...);                         // Internal scalar/vector memory

	// Vector write-back mux
	always_comb begin
		for (int i = 0; i < 4; i++) begin
			v_wr_data[i] = (vrf_wr_data_sel == VALU) ? vec_data_addr_i[i] :
			               (vrf_wr_data_sel == VMEM) ? v_mem_rd_data[i] : '0;
		end
	end

	// -------------------------------
	// Reset logic
	// -------------------------------
	always_ff @(posedge clk or negedge reset_n) begin
		if(!reset_n) reset_seen_q <= 1'b0;
		else          reset_seen_q <= 1'b1;
	end

	always_ff @(posedge clk or negedge reset_n) begin
		if(!reset_n)        pc_q <= RESET_PC;
		else if(reset_seen_q) pc_q <= next_pc;
	end

endmodule
