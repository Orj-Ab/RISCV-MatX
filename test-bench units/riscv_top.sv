// `timescale 1ns/1ps

module riscv_top 
	import yarp_pkg::*; 
# (    	
  parameter RESET_PC = 32'h0
) (
	input  logic clk,
	input  logic reset_n
);

	// internal signals

	// Instruction memory interface
	logic             instr_mem_req;
	logic   [31:0]    instr_addr;

	logic   [31:0]    instr; 
	logic   [31:0]    pc_q;
	logic   [31:0]    instr_instr;

	logic   [ 4:0]    rs1;
	logic   [ 4:0]    rs2;
	logic   [ 4:0]    rd;

	logic   [31:0]    rs1_data;
	logic   [31:0]    rs2_data;
	logic   [31:0]    wr_data;

	logic   [31:0]    alu_opr_a;
	logic   [31:0]    alu_opr_b;
	logic   [ 3:0]    alu_func;
	logic   [31:0]    alu_res;

	logic             r_type;
	logic             i_type; 
	logic             s_type; 
	logic             b_type; 
	logic             u_type; 
	logic             j_type;

	logic   [ 6:0]    opcode;
	logic   [ 6:0]    funct7;
	logic   [ 2:0]    funct3;
	logic   [31:0]    imm;

	logic             branch_taken; 
	logic             zero_extnd; 
	logic             data_req; 
	logic             data_wr; 
	logic             pc_sel; 
	logic             op1_sel; 
	logic             op2_sel; 
	logic             rf_wr_en;

	logic   [31:0]    mem_rd_data;
	logic   [31:0]    mem_rd_data_from_mem;
	logic   [31:0]    mem_rd_data_final;
	logic   [ 1:0]    rf_wr_data_sel; 
	logic   [ 1:0]    vrf_wr_data_sel; 
	logic   [ 1:0]    data_byte;
	logic   [31:0]    next_seq_pc; 
	logic   [31:0]    next_pc;
	logic             reset_seen_q; 

	// vector supportred signals
	logic            is_vector_load;
	logic            is_vector_store;
	logic            is_vector_mmul;
	logic            is_vector_load_o;
	logic            is_vector_store_o;
	logic            is_vector_mmul_o;
	logic            vrf_wr_en;
	logic 			 valu_funct;
    logic [127:0]    vec_data_addr_i     [4];
    logic [127:0]    v_rs1_data          [4];
    logic [127:0]    v_rs2_data          [4];
	logic [127:0]    v_mem_rd_data       [4];
	logic [127:0]    v_wr_data           [4];
	logic [127:0]    v_mem_rd_data_final [4];

   
  	// program counter (pc) logic 
    assign next_seq_pc = pc_q + 32'h4;
    assign next_pc     = (branch_taken | pc_sel) ? {alu_res[31:1],1'b0} : next_seq_pc;

  	// register file
	assign wr_data     = (rf_wr_data_sel == ALU) ? alu_res :
					     (rf_wr_data_sel == MEM) ? mem_rd_data_final :
					     (rf_wr_data_sel == IMM) ? imm :
					    						   next_seq_pc; 
  	// ALU operand mux
	assign alu_opr_a   = op1_sel ? pc_q : rs1_data;
	assign alu_opr_b   = op2_sel ? imm  : rs2_data;

    // Connect internal wires to top module ports
	assign  instr_mem_req_o      = instr_mem_req;
	assign  instr_mem_addr_o     = instr_addr;
	assign  instr_mem_rd_data_i  = instr_instr;
	assign  data_mem_rd_data_i   = mem_rd_data;
	assign  data_mem_addr_o      = alu_res;
	assign  data_mem_byte_en_o   = data_byte;
	assign  data_mem_wr_o        = data_wr;
	assign  data_mem_req_o       = data_req;

  	// instruction memory
    instruction_memory u_yarp_instruction_memory (
		.instr_mem_req_i    (instr_mem_req),
		.instr_mem_addr_i   (instr_addr   ),
		.instr_mem_rd_data_o(instr_instr  )
	);
	
    // instruction fetch
    fetch u_yarp_fetch (
		.clk                (clk          ),
		.reset_n            (reset_n      ),
		.instr_mem_rd_data_i(instr_instr  ),
		.instr_mem_req_o    (instr_mem_req), 
		.instr_mem_addr_o   (instr_addr   ),
		.pc_q_i             (pc_q         ),
		.instr_mem_instr_o  (instr        )		 
	);
	
	// Instruction Decode
	decode u_yarp_decode (
		.instr_mem_instr_i(instr          ),
		.funct3_o         (funct3         ),
		.funct7_o         (funct7         ),
		.op_o             (opcode         ),
		.r_type_o         (r_type         ),
		.j_type_o         (j_type         ),
		.i_type_o         (i_type         ),
		.u_type_o         (u_type         ),
		.s_type_o         (s_type         ),
		.b_type_o         (b_type         ),
		.rs1_addr_o       (rs1            ),
		.rs2_addr_o       (rs2            ),
		.rd_addr_o        (rd             ),
		.instr_immed_o    (imm            ),
		.is_vector_load_o (is_vector_load ),
		.is_vector_store_o(is_vector_store),
		.is_vector_mmul_o (is_vector_mmul )
	);

	// register file
	register_file  u_yarp_register_file (
		.clk       (clk     ),
		.reset_n   (reset_n ),
		.wr_en_i   (rf_wr_en),
		.rs1_addr_i(rs1     ),
		.rs2_addr_i(rs2     ),
		.rd_addr_i (rd      ),
		.wr_data_i (wr_data ),
		.rs1_data_o(rs1_data),
		.rs2_data_o(rs2_data)
	);

	// vector register file
	v_regfile  u_yarp_v_register_file (
		.clk     (clk       ),
		.reset_n (reset_n   ),
		.wen     (vrf_wr_en ),
		.rd_addr (rd        ),
		.rd_data (v_wr_data ), //coming from data_mem/valu
		.rs1_addr(rs1       ),
		.rs2_addr(rs2       ),
		.rs1_data(v_rs1_data),
		.rs2_data(v_rs2_data)
	);
	
	// Control Unit
	control_unit u_yarp_control_unit (
		.instr_opcode_i      (opcode           ),
		.instr_funct3_i      (funct3           ),
		.instr_funct7_bit5_i (funct7[5]        ),
		.instr_funct7_bit0_i (funct7[0]        ),
		.is_j_type_i         (j_type           ),
		.is_i_type_i         (i_type           ),
		.is_r_type_i         (r_type           ),
		.is_b_type_i         (b_type           ),
		.is_u_type_i         (u_type           ),
		.is_s_type_i         (s_type           ),
		.is_vector_load_i    (is_vector_load   ),
		.is_vector_store_i   (is_vector_store  ),
		.is_vector_mmul_i    (is_vector_mmul   ),
		.pc_sel_o            (pc_sel           ),
		.op1_sel_o           (op1_sel          ),
		.op2_sel_o           (op2_sel          ),
		.data_req_o          (data_req         ),
		.data_wr_o           (data_wr          ),
		.zero_extnd_o        (zero_extnd       ),
		.rf_wr_en_o          (rf_wr_en         ),
		.rf_wr_data_o        (rf_wr_data_sel   ),
		.vrf_wr_data_o       (vrf_wr_data_sel  ),
		.alu_funct_o         (alu_func         ),
		.data_byte_o         (data_byte        ),
		.valu_funct_o        (valu_funct       ),
		.is_vector_load_o    (is_vector_load_o ),
		.is_vector_store_o   (is_vector_store_o),
		.is_vector_mmul_o    (is_vector_mmul_o ),
		.vrf_wr_en_o         (vrf_wr_en        )
	);
	
    // Branch Control	
	branch_control u_yarp_branch_control (
		.is_b_type_clt_i  (b_type      ),
		.instr_func3_clt_i(funct3      ),
		.opr_a_i          (rs1_data    ),
		.opr_b_i          (rs2_data    ),
		.branch_taken_o   (branch_taken)
    );

    // Execute Unit	
	execute u_yarp_execute (
		.opr_a_i    (alu_opr_a),
		.opr_b_i    (alu_opr_b),
		.alu_funct_i(alu_func ),
		.alu_res_o  (alu_res  )
	);

	//Vector ALU
	valu u_yarp_v_alu (
		.vec_a  (v_rs1_data     ),
		.vec_b  (v_rs2_data     ),
        .valu_op(valu_funct     ),
		.result (vec_data_addr_i)
	);
	
	// check inputs and outputs with between data memory and memory so we can add them properly to the top
	// --------------------------------------------------------
    // Data Memory (Internal)
    // --------------------------------------------------------
    data_mem u_yarp_data_mem (
		.clk              (clk              ),
		.data_mem_rd_data_o(mem_rd_data_final),
		.data_zero_extnd_i (zero_extnd       ),
		.data_byte_en_i    (data_byte        ),
		.data_addr_i       (alu_res          ),
		.data_req_i        (data_req         ),
		.data_wr_i         (data_wr          ),
		.data_wr_data_i    (rs2_data         ),
		.is_vector_i	   (is_vector_load_o | is_vector_store_o),
		.vec_data_wr_data_i(v_rs2_data       ),
		.vec_mem_rd_data_o (v_mem_rd_data    )
	);
	
	// --------------------------------------------------------
    // Data Memory (Internal)
    // --------------------------------------------------------
    memory u_yarp_memory (
		.clk                 (clk      			  ),
		.reset_n             (reset_n  			  ),
		.data_mem_wr         (data_wr  			  ),
		.data_mem_addr       (alu_res  			  ),
		.data_mem_wr_data    (rs2_data 			  ),
		.data_mem_req        (data_req 			  ),
		.data_mem_byte_en    (data_byte			  ),
		.mem_rd_data         (mem_rd_data_from_mem),
		.is_vector_i         (is_vector_load_o | is_vector_store_o),
		.vec_data_wr_data_i  (v_rs2_data          ),
		.vec_mem_rd_data_o   (v_mem_rd_data_final )
    );

	// posedge block	
	always_comb 
	begin
		for (int i = 0; i < 4; i++) 
		begin
			v_wr_data[i] = (vrf_wr_data_sel == VALU) ? vec_data_addr_i[i] :
						   (vrf_wr_data_sel == VMEM) ? v_mem_rd_data  [i] :'0;
		end
	end

  	// Capture reset state
    always_ff @ (posedge clk or negedge reset_n) 
	begin
		if(!reset_n) 
		begin
			reset_seen_q <= 1'b0;
		end 
		else 
		begin 
			reset_seen_q <= 1'b1;
		end
    end

    always_ff @ (posedge clk or negedge reset_n) 
	begin
		if(!reset_n) 
		begin
	     	pc_q         <= RESET_PC;
		end 
		else if (reset_seen_q) 
		begin 
		    pc_q         <= next_pc;
		end
    end
	    
endmodule
	   
	   
 