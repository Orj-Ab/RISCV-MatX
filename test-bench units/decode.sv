`timescale 1ns/1ps

module decode 
  import yarp_pkg::*; 
(
  input  logic [31:0] instr_mem_instr_i,

  // Outputs to the control unit
  output logic [ 2:0] funct3_o,
  output logic [ 6:0] funct7_o,
  output logic [ 6:0] op_o,
  output logic        r_type_o,
  output logic        j_type_o,
  output logic        i_type_o,
  output logic        u_type_o,
  output logic        s_type_o,
  output logic        b_type_o, // also to the branch control

  // Outputs to the register file
  output logic [ 4:0] rs1_addr_o,
  output logic [ 4:0] rs2_addr_o,
  output logic [ 4:0] rd_addr_o,

  // Immediate output to the muxes (ALU)
  output logic [31:0] instr_immed_o,

  // Vector support signals
  output logic        is_vector_load_o,
  output logic        is_vector_store_o,
  output logic        is_vector_mmul_o
);

  // Internal wires and regs
  logic        r_type;
  logic        i_type;
  logic        s_type;
  logic        b_type;
  logic        u_type;
  logic        j_type;
  logic        v_type_load;
  logic        v_type_store;
  logic        v_type_mmul;

  logic [ 6:0] op;
  
  logic [31:0] instr_imm;
  logic [31:0] i_type_imm;
  logic [31:0] s_type_imm;
  logic [31:0] b_type_imm;
  logic [31:0] u_type_imm;
  logic [31:0] j_type_imm;
  
  logic [ 4:0] rs1;
  logic [ 4:0] rs2;
  logic [ 4:0] rd;
  logic [ 2:0] funct3;
  logic [ 6:0] funct7;

  assign rs1    = instr_mem_instr_i[19:15];
  assign rs2    = instr_mem_instr_i[24:20];
  assign rd     = instr_mem_instr_i[11: 7];
  assign op     = instr_mem_instr_i[6 : 0];

  assign funct3 = instr_mem_instr_i[14:12];
  assign funct7 = instr_mem_instr_i[31:25];
  
  
  // Decoding the 32 instruction bits

  assign s_type_imm = {{21{instr_mem_instr_i[31]}}, instr_mem_instr_i[30:25], instr_mem_instr_i[11:7]};
  assign b_type_imm = {{20{instr_mem_instr_i[31]}}, instr_mem_instr_i[7],
                       instr_mem_instr_i[30:25], instr_mem_instr_i[11:8], 1'b0};
  assign u_type_imm = {instr_mem_instr_i[31:12], 12'b0};
  assign j_type_imm = {{12{instr_mem_instr_i[31]}}, instr_mem_instr_i[19:12],
                       instr_mem_instr_i[20], instr_mem_instr_i[30:21], 1'b0};
  assign i_type_imm = {{20{instr_mem_instr_i[31]}}, instr_mem_instr_i[31:20]};
  
    // Immediate value selection based on instruction type
  assign instr_imm = (r_type | v_type_mmul ) ? 32'h0      :
 					           (i_type | v_type_load ) ? i_type_imm :
 					           (s_type | v_type_store) ? s_type_imm :
 					            b_type                 ? b_type_imm :
 					            u_type                 ? u_type_imm : j_type_imm;

  always_comb 
  begin
    // Reset all type flags
    r_type       = 1'b0;
    i_type       = 1'b0;
    s_type       = 1'b0;
    b_type       = 1'b0;
    u_type       = 1'b0;
    j_type       = 1'b0;
    v_type_load  = 1'b0;
    v_type_store = 1'b0;
    v_type_mmul  = 1'b0;

    // Determine the instruction type based on the opcode
    case (op)
      R_TYPE                      :  r_type       = 1'b1;
      I_TYPE_0, I_TYPE_1, I_TYPE_2:  i_type       = 1'b1;
      S_TYPE                      :  s_type       = 1'b1;
      B_TYPE                      :  b_type       = 1'b1;
      U_TYPE_0, U_TYPE_1          :  u_type       = 1'b1;
      J_TYPE                      :  j_type       = 1'b1;
      V_TYPE_LOAD                 :  v_type_load  = 1'b1;
      V_TYPE_STORE                :  v_type_store = 1'b1;
      V_TYPE_MMUL                 :  v_type_mmul  = 1'b1;
      default: ;
    endcase
  end

  assign rs1_addr_o        = rs1;
  assign rs2_addr_o        = rs2;
  assign rd_addr_o         = rd;
  assign op_o              = op;
  assign funct3_o          = funct3;
  assign funct7_o          = funct7;
  assign r_type_o          = r_type;
  assign i_type_o          = i_type;
  assign s_type_o          = s_type;
  assign b_type_o          = b_type;
  assign u_type_o          = u_type;
  assign j_type_o          = j_type;
  assign is_vector_load_o  = v_type_load;
  assign is_vector_store_o = v_type_store;
  assign is_vector_mmul_o  = v_type_mmul;
  assign instr_immed_o     = instr_imm;

endmodule
