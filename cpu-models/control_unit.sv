`timescale 1ns/1ps                    // Set simulation timescale: time unit 1ns, precision 1ps

module control_unit                   // Start of control unit module definition
  import yarp_pkg::*;                 // Import all definitions from yarp_pkg package (constants, enums, types)
(  
  // Instruction type inputs from decode unit
  input   logic          is_j_type_i,        // Jump instruction type flag
  input   logic          is_i_type_i,        // Immediate instruction type flag
  input   logic          is_b_type_i,        // Branch instruction type flag
  input   logic          is_u_type_i,        // Upper immediate instruction type flag
  input   logic          is_r_type_i,        // Register-register instruction type flag
  input   logic          is_s_type_i,        // Store instruction type flag
  input   logic          is_vector_load_i,   // Vector load instruction flag
  input   logic          is_vector_store_i,  // Vector store instruction flag
  input   logic          is_vector_mmul_i,   // Vector matrix multiplication instruction flag

  // Instruction opcode and function field inputs from decode unit
  input   logic  [6:0]   instr_opcode_i,     // 7-bit opcode field from instruction
  input   logic  [2:0]   instr_funct3_i,     // 3-bit function field (specifies operation variant)
  input   logic          instr_funct7_bit5_i, // Bit 5 of funct7 field (used for operation selection)
  input   logic          instr_funct7_bit0_i, // Bit 0 of funct7 field (used for operation selection)

  // Control signal outputs to datapath components
  output  logic          pc_sel_o,           // Program counter source select (0: PC+4, 1: ALU result)
  output  logic          op1_sel_o,          // ALU operand 1 select (0: register, 1: PC)
  output  logic          op2_sel_o,          // ALU operand 2 select (0: register, 1: immediate)
  output  logic          data_req_o,         // Data memory request signal (enable memory access)
  output  logic          data_wr_o,          // Data memory write enable (0: read, 1: write)
  output  logic          zero_extnd_o,       // Zero extend control for load operations
  output  logic          rf_wr_en_o,         // Register file write enable
  output  logic   [1:0]  rf_wr_data_o,       // Register file write data source select
  output  logic          vrf_wr_en_o,        // Vector register file write enable
  output  logic   [1:0]  vrf_wr_data_o,      // Vector register file write data source select
  output  logic   [1:0]  data_byte_o,        // Data access size (00: byte, 01: half-word, 10: word)
  output  logic   [3:0]  alu_funct_o,        // ALU function select (specifies ALU operation)
  output  logic          valu_funct_o,       // Vector ALU function select
  
  // Pass-through outputs for vector instruction flags
  output  logic          is_vector_load_o,   // Vector load instruction output flag
  output  logic          is_vector_store_o,  // Vector store instruction output flag
  output  logic          is_vector_mmul_o    // Vector matrix multiplication output flag
);

  // Internal signal declarations
  logic [4:0] instr_funct_rtype;      // Combined function bits for R-type instructions
  logic [3:0] instr_funct_itype;      // Combined function bits for I-type instructions
  logic [3:0] instr_opc;              // Opcode bits (unused in current implementation)

  // Control structure instances for each instruction type
  control_t   r_type_controls;        // Control signals for R-type instructions
  control_t   s_type_controls;        // Control signals for S-type instructions
  control_t   u_type_controls;        // Control signals for U-type instructions
  control_t   b_type_controls;        // Control signals for B-type instructions
  control_t   j_type_controls;        // Control signals for J-type instructions
  control_t   i_type_controls;        // Control signals for I-type instructions
  control_t   vl_type_controls;       // Control signals for vector load instructions
  control_t   vs_type_controls;       // Control signals for vector store instructions
  control_t   vm_type_controls;       // Control signals for vector matrix multiply instructions
  control_t   controls;               // Final selected control signals

  // R-type instruction control logic
  // --------------------------------------------------------
  // Construct 5-bit function field for R-type instructions (combines funct7 bits + funct3)
  assign instr_funct_rtype = {instr_funct7_bit5_i ,instr_funct7_bit0_i, instr_funct3_i} ; 

  always_comb                         // Combinational logic block for R-type control generation
  begin
    r_type_controls                = '0;     // Initialize all R-type control signals to zero
    r_type_controls.rf_wr_en       = 1'b1 ;  // Enable register file write for R-type instructions
    r_type_controls.rf_wr_data_sel = ALU;    // Select ALU result as register write data source
      case (instr_funct_rtype)               // Decode specific R-type operation
        ADD    :  r_type_controls.alu_funct_sel = OP_ADD;   // Addition operation
        SUB    :  r_type_controls.alu_funct_sel = OP_SUB;   // Subtraction operation
        SLL    :  r_type_controls.alu_funct_sel = OP_SLL;   // Shift left logical
        SLT    :  r_type_controls.alu_funct_sel = OP_SLT;   // Set less than (signed)
        SLTU   :  r_type_controls.alu_funct_sel = OP_SLTU;  // Set less than unsigned
        XOR    :  r_type_controls.alu_funct_sel = OP_XOR;   // Exclusive OR
        SRL    :  r_type_controls.alu_funct_sel = OP_SRL;   // Shift right logical
        SRA    :  r_type_controls.alu_funct_sel = OP_SRA;   // Shift right arithmetic
        OR     :  r_type_controls.alu_funct_sel = OP_OR;    // Logical OR
        AND    :  r_type_controls.alu_funct_sel = OP_AND;   // Logical AND
        MUL    :  r_type_controls.alu_funct_sel = OP_MUL;   // Multiplication
        default:  r_type_controls.alu_funct_sel = OP_ADD;   // Default to addition
      endcase
  end

  // I-type instruction control logic
  // --------------------------------------------------------
  // Construct 4-bit function field for I-type instructions (opcode bit 4 + funct3)
  assign instr_funct_itype = {instr_opcode_i[4] , instr_funct3_i} ; 
  always_comb                         // Combinational logic block for I-type control generation
  begin
    i_type_controls          = '0;            // Initialize all I-type control signals to zero
    i_type_controls.rf_wr_en = 1'b1 ;        // Enable register file write for I-type instructions
    i_type_controls.op2_sel  = 1'b1;         // Select immediate as ALU operand 2

    case (instr_funct_itype)                 // Decode specific I-type operation
      // Load instructions - access memory and write result to register
      LB   :  {i_type_controls.data_req, i_type_controls.data_byte, i_type_controls.rf_wr_data_sel} = {1'b1, BYTE, MEM};              // Load byte (sign-extended)
      LH   :  {i_type_controls.data_req, i_type_controls.data_byte, i_type_controls.rf_wr_data_sel} = {1'b1, HALF_WORD,MEM};          // Load half-word (sign-extended)
      LW   :  {i_type_controls.data_req, i_type_controls.data_byte, i_type_controls.rf_wr_data_sel} = {1'b1, WORD, MEM};              // Load word
      LBU  :  {i_type_controls.data_req, i_type_controls.data_byte, i_type_controls.rf_wr_data_sel, i_type_controls.zero_extnd} = {1'b1, BYTE     ,MEM,1'b1};      // Load byte unsigned (zero-extended)
      LHU  :  {i_type_controls.data_req, i_type_controls.data_byte, i_type_controls.rf_wr_data_sel, i_type_controls.zero_extnd} = {1'b1, HALF_WORD,MEM,1'b1};      // Load half-word unsigned (zero-extended)
      // Immediate arithmetic instructions - perform ALU operation with immediate
      ADDI :   i_type_controls.alu_funct_sel = OP_ADD;     // Add immediate
      SLTI :   i_type_controls.alu_funct_sel = OP_SLT;     // Set less than immediate (signed)
      SLTIU:   i_type_controls.alu_funct_sel = OP_SLTU;    // Set less than immediate unsigned
      XORI :   i_type_controls.alu_funct_sel = OP_XOR;     // XOR immediate
      ORI  :   i_type_controls.alu_funct_sel = OP_OR;      // OR immediate
      ANDI :   i_type_controls.alu_funct_sel = OP_AND;     // AND immediate
      SLLI :   i_type_controls.alu_funct_sel = OP_SLL;     // Shift left logical immediate
      SRXI :   i_type_controls.alu_funct_sel = instr_funct7_bit5_i ? OP_SRA : OP_SRL;  // Shift right immediate (arithmetic or logical based on funct7[5])
      //default:  i_type_controls = '0;                    // Commented default case
    endcase
    // JALR (Jump and Link Register) special handling
    if ((instr_opcode_i == I_TYPE_2))         // Check if this is JALR instruction
    begin
      i_type_controls.rf_wr_data_sel  = PC;   // Write PC+4 to register (link address)
      i_type_controls.pc_sel          = 1'b1; // Select ALU result as new PC
      i_type_controls.alu_funct_sel   = OP_ADD; // Use ALU to compute jump target (rs1 + immediate)
    end
  end
  
  // VL-type (Vector Load) instruction control logic
  // --------------------------------------------------------
  always_comb                         // Combinational logic block for vector load control generation
  begin
    vl_type_controls                 = '0;     // Initialize all vector load control signals to zero
    vl_type_controls.vrf_wr_en       = 1'b1;   // Enable vector register file write
    vl_type_controls.op2_sel         = 1'b1;   // Select immediate as ALU operand 2 (for address calculation)
    vl_type_controls.data_req        = 1'b1;   // Request data memory access
    vl_type_controls.data_byte       = WORD;   // Access word-sized data
    vl_type_controls.vrf_wr_data_sel = MEM;    // Select memory data as vector register write source
    vl_type_controls.alu_funct_sel   = OP_ADD; // Use ALU addition for address calculation
  end

  // VS-type (Vector Store) instruction control logic
  // --------------------------------------------------------
  always_comb                         // Combinational logic block for vector store control generation
  begin
    vs_type_controls           = '0;           // Initialize all vector store control signals to zero
    vs_type_controls.data_req  = 1'b1;         // Request data memory access
    vs_type_controls.data_wr   = 1'b1;         // Enable memory write
    vs_type_controls.op2_sel   = 1'b1;         // Select immediate as ALU operand 2 (for address calculation)
    vs_type_controls.data_byte = WORD;         // Access word-sized data
  end

  // VM-type (Vector Matrix Multiply) instruction control logic
  // --------------------------------------------------------
  always_comb                         // Combinational logic block for vector matrix multiply control generation
  begin
    vm_type_controls                 = '0;     // Initialize all vector matrix multiply control signals to zero
    vm_type_controls.vrf_wr_en       = 1'b1;   // Enable vector register file write
    vm_type_controls.vrf_wr_data_sel = VALU;   // Select vector ALU result as write data source
    vm_type_controls.valu_funct_sel  = V_MMUL; // Select matrix multiplication function for vector ALU
  end

  // S-type (Store) instruction control logic
  // --------------------------------------------------------
  always_comb                         // Combinational logic block for store control generation
  begin
    s_type_controls          = '0;             // Initialize all store control signals to zero
    s_type_controls.data_req = 1'b1;           // Request data memory access
    s_type_controls.data_wr  = 1'b1;           // Enable memory write
    s_type_controls.op2_sel  = 1'b1;           // Select immediate as ALU operand 2 (for address calculation)
    case(instr_funct3_i)                      // Decode store size based on funct3
      SB     :  s_type_controls.data_byte = BYTE;      // Store byte
      SH     :  s_type_controls.data_byte = HALF_WORD; // Store half-word
      SW     :  s_type_controls.data_byte = WORD;      // Store word
      default:  s_type_controls = '0;                  // Invalid store instruction
    endcase
  end

  // B-type (Branch) instruction control logic
  // --------------------------------------------------------
  always_comb                         // Combinational logic block for branch control generation
  begin 
    b_type_controls               = '0;        // Initialize all branch control signals to zero
    b_type_controls.alu_funct_sel = OP_ADD;    // Use ALU addition to compute branch target address
    b_type_controls.op1_sel       = 1'b1;      // Select PC as ALU operand 1
    b_type_controls.op2_sel       = 1'b1;      // Select immediate as ALU operand 2
  end
 
  // U-type (Upper Immediate) instruction control logic
  // --------------------------------------------------------
  always_comb                         // Combinational logic block for upper immediate control generation
  begin
    u_type_controls = '0;                      // Initialize all upper immediate control signals to zero
    u_type_controls.rf_wr_en = 1'b1;           // Enable register file write
    case (instr_opcode_i)                     // Decode specific U-type operation
      AUIPC  : {u_type_controls.op2_sel, u_type_controls.op1_sel} = {1'b1, 1'b1};  // Add Upper Immediate to PC: use PC + immediate
      LUI    : u_type_controls.rf_wr_data_sel                     = IMM;            // Load Upper Immediate: write immediate directly to register
      default: u_type_controls                                    = '0;             // Invalid U-type instruction
    endcase
  end

  // J-type (Jump) instruction control logic
  // --------------------------------------------------------
  always_comb                         // Combinational logic block for jump control generation
  begin
    j_type_controls                 = '0;      // Initialize all jump control signals to zero
    j_type_controls.rf_wr_en        = 1'b1;    // Enable register file write (for link address)
    j_type_controls.rf_wr_data_sel  = PC;      // Write PC+4 to register (return address)
    j_type_controls.op2_sel         = 1'b1;    // Select immediate as ALU operand 2
    j_type_controls.op1_sel         = 1'b1;    // Select PC as ALU operand 1
    j_type_controls.pc_sel          = 1'b1;    // Select ALU result as new PC (jump target)
  end
  
  // Instruction type multiplexer - select appropriate control signals based on instruction type
  assign controls = is_vector_load_i  ? vl_type_controls :  // Vector load controls
                   is_vector_store_i ? vs_type_controls :   // Vector store controls
                   is_vector_mmul_i  ? vm_type_controls :   // Vector matrix multiply controls
                   is_r_type_i       ? r_type_controls  :   // R-type controls
                   is_i_type_i       ? i_type_controls  :   // I-type controls
                   is_b_type_i       ? b_type_controls  :   // B-type controls
                   is_u_type_i       ? u_type_controls  :   // U-type controls
                   is_s_type_i       ? s_type_controls  :   // S-type controls
                   is_j_type_i       ? j_type_controls  :   // J-type controls
                                       '0;                   // Default: all control signals off
								 
  // Output signal assignments - connect internal control structure to output ports
  // --------------------------------------------------------
  assign pc_sel_o          = controls.pc_sel;          // Program counter source select output
  assign op1_sel_o         = controls.op1_sel;         // ALU operand 1 select output
  assign op2_sel_o         = controls.op2_sel;         // ALU operand 2 select output
  assign data_req_o        = controls.data_req;        // Data memory request output
  assign data_wr_o         = controls.data_wr;         // Data memory write enable output
  assign zero_extnd_o      = controls.zero_extnd;      // Zero extend control output
  assign rf_wr_en_o        = controls.rf_wr_en;        // Register file write enable output
  assign vrf_wr_en_o       = controls.vrf_wr_en;       // Vector register file write enable output
  assign alu_funct_o       = controls.alu_funct_sel;   // ALU function select output
  assign valu_funct_o      = controls.valu_funct_sel;  // Vector ALU function select output
  assign rf_wr_data_o      = controls.rf_wr_data_sel;  // Register file write data select output
  assign vrf_wr_data_o     = controls.vrf_wr_data_sel; // Vector register file write data select output
  assign data_byte_o       = controls.data_byte;       // Data access size output

  // Pass-through assignments for vector instruction flags
  assign is_vector_load_o  = is_vector_load_i;         // Pass through vector load flag
  assign is_vector_store_o = is_vector_store_i;        // Pass through vector store flag
  assign is_vector_mmul_o  = is_vector_mmul_i;         // Pass through vector matrix multiply flag

endmodule                             // End of control unit module