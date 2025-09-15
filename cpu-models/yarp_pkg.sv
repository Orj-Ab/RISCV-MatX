package yarp_pkg;   // Package definition, groups related parameters, types, and enums together

  // =============================================
  // Parameters
  // =============================================
  parameter int VECTOR_REG_WIDTH = 128;      // Defines vector register width (128 bits wide)
  parameter int VECTOR_REG_COUNT = 32;       // Defines total number of vector registers (32 registers)

  // =============================================
  // RISC-V Opcode Types
  // =============================================
  typedef enum logic[6:0] {
    R_TYPE       = 7'h33, // Standard R-type instructions
    I_TYPE_0     = 7'h03, // Load instructions
    I_TYPE_1     = 7'h13, // Immediate arithmetic/logical instructions
    I_TYPE_2     = 7'h67, // JALR (jump and link register)
    S_TYPE       = 7'h23, // Store instructions
    B_TYPE       = 7'h63, // Branch instructions
    U_TYPE_0     = 7'h37, // LUI (load upper immediate)
    U_TYPE_1     = 7'h17, // AUIPC (add upper immediate to PC)
    J_TYPE       = 7'h6F, // JAL (jump and link)
    V_TYPE_LOAD  = 7'h07, // Custom opcode: vector load
    V_TYPE_STORE = 7'h27, // Custom opcode: vector store
    V_TYPE_MMUL  = 7'h73  // Custom opcode: vector matrix multiplication
  } riscv_op_t;

  // =============================================
  // ALU Operation Types
  // =============================================
  typedef enum logic [3:0] {
    OP_ADD,   // Addition
    OP_SUB,   // Subtraction
    OP_SLL,   // Logical shift left
    OP_SRL,   // Logical shift right
    OP_SRA,   // Arithmetic shift right
    OP_OR,    // Bitwise OR
    OP_AND,   // Bitwise AND
    OP_XOR,   // Bitwise XOR
    OP_SLTU,  // Set less than (unsigned)
    OP_SLT,   // Set less than (signed)
    OP_SLLI,  // Shift left logical immediate
    OP_MUL,   // Multiply
    MAT_ADD,  // Custom: matrix addition
    MAT_MUL   // Custom: matrix multiplication
  } alu_op_t;

  // =============================================
  // VALU (Vector ALU) Operation Types
  // =============================================
  typedef enum logic {
    V_ADD,    // Vector addition
    V_MMUL    // Vector matrix multiplication
  } valu_op_t;  
  
  // =============================================
  // Memory Access Size
  // =============================================
  typedef enum logic [1:0] {
    BYTE      = 2'b00, // Byte (8-bit) access
    HALF_WORD = 2'b01, // Half-word (16-bit) access
    WORD      = 2'b11  // Word (32-bit) access
  } mem_access_size_t;
	
  // =============================================
  // R-type Instruction Encoding
  // =============================================
  // Encoded using {funct7[5], funct7[0], funct3}
  typedef enum logic [4:0] {
    ADD   = 5'h0,   // Addition
    SUB   = 5'h10,  // Subtraction
    SLL   = 5'h1,   // Shift left logical
    SLT   = 5'h2,   // Set less than (signed)
    SLTU  = 5'h3,   // Set less than (unsigned)
    XOR   = 5'h4,   // Bitwise XOR
    SRL   = 5'h5,   // Shift right logical
    SRA   = 5'h15,  // Shift right arithmetic
    OR    = 5'h6,   // Bitwise OR
    AND   = 5'h7,   // Bitwise AND
    MUL   = 5'h8    // Multiply
  } r_type_t;
	
  // =============================================
  // I-type Instruction Encoding
  // =============================================
  // Encoded using {opcode[4], funct3}
  typedef enum logic [3:0] {
    LB     = 4'h0, // Load byte
    LH     = 4'h1, // Load half word
    LW     = 4'h2, // Load word
    LBU    = 4'h4, // Load byte unsigned
    LHU    = 4'h5, // Load half word unsigned
    ADDI   = 4'h8, // Add immediate
    SLTI   = 4'ha, // Set less than immediate (signed)
    SLTIU  = 4'hb, // Set less than immediate (unsigned)
    XORI   = 4'hc, // XOR immediate
    ORI    = 4'he, // OR immediate
    ANDI   = 4'hf, // AND immediate
    SLLI   = 4'h9, // Shift left immediate
    SRXI   = 4'hd  // Shift right immediate (logical/arithmetic combined)
  } i_type_t;
  
  // =============================================
  // S-type Instruction Encoding
  // =============================================
  typedef enum logic [1:0] {
    SB = 2'h0, // Store byte
    SH = 2'h1, // Store half word
    SW = 2'h2  // Store word
  } s_type_t;
   
  // =============================================
  // B-type Instruction Encoding
  // =============================================
  typedef enum logic [2:0] {
    BEQ  = 3'h0, // Branch if equal
    BNE  = 3'h1, // Branch if not equal
    BLT  = 3'h4, // Branch if less than
    BGE  = 3'h5, // Branch if greater/equal
    BLTU = 3'h6, // Branch if less than (unsigned)
    BGEU = 3'h7  // Branch if greater/equal (unsigned)
  } b_type_t;
  
  // =============================================
  // U-type Instruction Encoding
  // =============================================
  typedef enum logic [6:0] {
    AUIPC = 7'h17, // Add upper immediate to PC
    LUI   = 7'h37  // Load upper immediate
  } u_type_t;
   
  // =============================================
  // J-type Instruction Encoding
  // =============================================
  typedef enum logic[5:0] {
    JAL = 6'h3 // Jump and link
  } j_type_t;
  
  // =============================================
  // Control Signals Struct
  // =============================================
  typedef struct packed {
    logic         pc_sel;           // Select next PC source
    logic         op1_sel;          // Select operand1 source
    logic         op2_sel;          // Select operand2 source
    logic         data_req;         // Memory request enable
    logic  [1:0]  data_byte;        // Memory access size (byte/halfword/word)
    logic         data_wr;          // Memory write enable
    logic         zero_extnd;       // Zero-extend loaded data
    logic  [3:0]  alu_funct_sel;    // ALU function selection
    logic         valu_funct_sel;   // Vector ALU function selection
    logic         rf_wr_en;         // Register file write enable
    logic         vrf_wr_en;        // Vector register file write enable
    logic  [1:0]  rf_wr_data_sel;   // Source for register file write-back
    logic  [1:0]  vrf_wr_data_sel;  // Source for vector register file write-back
  } control_t;
 
  // =============================================
  // VRF (Vector Register File) Write Data Source
  // =============================================
  typedef enum logic[1:0] {
    VALU  = 2'b00, // From Vector ALU
    VMEM  = 2'b01, // From Vector Memory
    VIMM  = 2'b10, // From Vector Immediate
    VPC   = 2'b11  // From PC
  } vrf_wr_data_src_t;

  // =============================================
  // RF (Scalar Register File) Write Data Source
  // =============================================
  typedef enum logic[1:0] {
    ALU = 2'b00, // From ALU
    MEM = 2'b01, // From memory
    IMM = 2'b10, // From immediate value
    PC  = 2'b11  // From PC
  } rf_wr_data_src_t;
 
endpackage
