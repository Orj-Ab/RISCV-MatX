`timescale 1ns/1ps                    // Set simulation timescale: time unit 1ns, precision 1ps

module decode                         // Start of decode module definition
  import yarp_pkg::*;                 // Import all definitions from yarp_pkg package (constants, parameters)
(
  // Input from instruction memory
  input  logic [31:0] instr_mem_instr_i,  // 32-bit instruction word from instruction memory

  // Control unit outputs - instruction decoding fields
  output logic [ 2:0] funct3_o,       // Function 3 field (bits 14:12) - specifies operation variant
  output logic [ 6:0] funct7_o,       // Function 7 field (bits 31:25) - additional operation specification
  output logic [ 6:0] op_o,           // Opcode field (bits 6:0) - primary operation identifier
  
  // Instruction type flags for control unit
  output logic        r_type_o,       // Register-register operations (ADD, SUB, etc.)
  output logic        j_type_o,       // Jump instructions (JAL)
  output logic        i_type_o,       // Immediate operations (ADDI, LOAD, etc.)
  output logic        u_type_o,       // Upper immediate operations (LUI, AUIPC)
  output logic        s_type_o,       // Store operations (SW, SB, etc.)
  output logic        b_type_o,       // Branch operations (BEQ, BNE, etc.)

  // Register file address outputs
  output logic [ 4:0] rs1_addr_o,     // Source register 1 address (bits 19:15)
  output logic [ 4:0] rs2_addr_o,     // Source register 2 address (bits 24:20)
  output logic [ 4:0] rd_addr_o,      // Destination register address (bits 11:7)

  // Immediate value for ALU operations
  output logic [31:0] instr_immed_o,  // Sign-extended immediate value based on instruction type

  // Vector instruction support signals
  output logic        is_vector_load_o,  // Vector load instruction flag
  output logic        is_vector_store_o, // Vector store instruction flag
  output logic        is_vector_mmul_o   // Vector matrix multiplication instruction flag
);

  // Internal signal declarations for instruction type detection
  logic        r_type;               // Internal R-type flag
  logic        i_type;               // Internal I-type flag
  logic        s_type;               // Internal S-type flag
  logic        b_type;               // Internal B-type flag
  logic        u_type;               // Internal U-type flag
  logic        j_type;               // Internal J-type flag
  logic        v_type_load;          // Internal vector load flag
  logic        v_type_store;         // Internal vector store flag
  logic        v_type_mmul;          // Internal vector matrix multiply flag

  logic [ 6:0] op;                   // Internal opcode storage
  
  // Immediate value calculations for different instruction formats
  logic [31:0] instr_imm;            // Final selected immediate value
  logic [31:0] i_type_imm;           // I-type immediate (sign-extended 12-bit)
  logic [31:0] s_type_imm;           // S-type immediate (sign-extended, split field)
  logic [31:0] b_type_imm;           // B-type immediate (sign-extended, for branches)
  logic [31:0] u_type_imm;           // U-type immediate (upper 20 bits)
  logic [31:0] j_type_imm;           // J-type immediate (sign-extended, for jumps)
  
  // Internal register address storage
  logic [ 4:0] rs1;                  // Internal source register 1 address
  logic [ 4:0] rs2;                  // Internal source register 2 address
  logic [ 4:0] rd;                   // Internal destination register address
  logic [ 2:0] funct3;               // Internal function 3 field
  logic [ 6:0] funct7;               // Internal function 7 field

  // Extract register addresses from instruction word
  assign rs1    = instr_mem_instr_i[19:15];  // Source register 1: bits 19-15
  assign rs2    = instr_mem_instr_i[24:20];  // Source register 2: bits 24-20
  assign rd     = instr_mem_instr_i[11: 7];  // Destination register: bits 11-7
  assign op     = instr_mem_instr_i[6 : 0];  // Opcode: bits 6-0

  // Extract function fields from instruction word
  assign funct3 = instr_mem_instr_i[14:12];  // Function 3: bits 14-12
  assign funct7 = instr_mem_instr_i[31:25];  // Function 7: bits 31-25
  
  
  // Immediate value extraction and sign extension for different instruction types

  // S-type: Store immediate (split into two parts: [31:25] and [11:7])
  assign s_type_imm = {{21{instr_mem_instr_i[31]}}, instr_mem_instr_i[30:25], instr_mem_instr_i[11:7]};
  
  // B-type: Branch immediate (reordered and shifted left by 1 for 2-byte alignment)
  assign b_type_imm = {{20{instr_mem_instr_i[31]}}, instr_mem_instr_i[7],
                       instr_mem_instr_i[30:25], instr_mem_instr_i[11:8], 1'b0};
  
  // U-type: Upper immediate (upper 20 bits, lower 12 bits zero)
  assign u_type_imm = {instr_mem_instr_i[31:12], 12'b0};
  
  // J-type: Jump immediate (reordered and shifted left by 1 for 2-byte alignment)
  assign j_type_imm = {{12{instr_mem_instr_i[31]}}, instr_mem_instr_i[19:12],
                       instr_mem_instr_i[20], instr_mem_instr_i[30:21], 1'b0};
  
  // I-type: Immediate value (sign-extended 12-bit immediate)
  assign i_type_imm = {{20{instr_mem_instr_i[31]}}, instr_mem_instr_i[31:20]};
  
  // Select appropriate immediate value based on instruction type
  assign instr_imm = (r_type | v_type_mmul ) ? 32'h0      :  // R-type and vector mmul: no immediate
 					           (i_type | v_type_load ) ? i_type_imm :  // I-type and vector load: I-type immediate
 					           (s_type | v_type_store) ? s_type_imm :  // S-type and vector store: S-type immediate
 					            b_type                 ? b_type_imm :  // B-type: branch immediate
 					            u_type                 ? u_type_imm :  // U-type: upper immediate
                                                       j_type_imm;   // J-type: jump immediate (default)

  // Combinational logic block for instruction type detection
  always_comb 
  begin
    // Initialize all instruction type flags to false
    r_type       = 1'b0;             // Reset R-type flag
    i_type       = 1'b0;             // Reset I-type flag
    s_type       = 1'b0;             // Reset S-type flag
    b_type       = 1'b0;             // Reset B-type flag
    u_type       = 1'b0;             // Reset U-type flag
    j_type       = 1'b0;             // Reset J-type flag
    v_type_load  = 1'b0;             // Reset vector load flag
    v_type_store = 1'b0;             // Reset vector store flag
    v_type_mmul  = 1'b0;             // Reset vector matrix multiply flag

    // Decode instruction type based on opcode (constants from yarp_pkg)
    case (op)
      R_TYPE                      :  r_type       = 1'b1;  // Register-register operations
      I_TYPE_0, I_TYPE_1, I_TYPE_2:  i_type       = 1'b1;  // Immediate operations (multiple opcodes)
      S_TYPE                      :  s_type       = 1'b1;  // Store operations
      B_TYPE                      :  b_type       = 1'b1;  // Branch operations
      U_TYPE_0, U_TYPE_1          :  u_type       = 1'b1;  // Upper immediate operations (LUI, AUIPC)
      J_TYPE                      :  j_type       = 1'b1;  // Jump operations
      V_TYPE_LOAD                 :  v_type_load  = 1'b1;  // Vector load operations
      V_TYPE_STORE                :  v_type_store = 1'b1;  // Vector store operations
      V_TYPE_MMUL                 :  v_type_mmul  = 1'b1;  // Vector matrix multiply operations
      default: ;                                            // Unknown opcode: all flags remain 0
    endcase
  end

  // Output assignments - connect internal signals to output ports
  assign rs1_addr_o        = rs1;           // Source register 1 address output
  assign rs2_addr_o        = rs2;           // Source register 2 address output
  assign rd_addr_o         = rd;            // Destination register address output
  assign op_o              = op;            // Opcode output
  assign funct3_o          = funct3;        // Function 3 field output
  assign funct7_o          = funct7;        // Function 7 field output
  assign r_type_o          = r_type;        // R-type flag output
  assign i_type_o          = i_type;        // I-type flag output
  assign s_type_o          = s_type;        // S-type flag output
  assign b_type_o          = b_type;        // B-type flag output
  assign u_type_o          = u_type;        // U-type flag output
  assign j_type_o          = j_type;        // J-type flag output
  assign is_vector_load_o  = v_type_load;   // Vector load flag output
  assign is_vector_store_o = v_type_store;  // Vector store flag output
  assign is_vector_mmul_o  = v_type_mmul;   // Vector matrix multiply flag output
  assign instr_immed_o     = instr_imm;     // Selected immediate value output

endmodule                                   // End of decode module