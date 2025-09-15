package yarp_pkg;

  parameter int VECTOR_REG_WIDTH = 128;      // 128-bit vector width
  parameter int VECTOR_REG_COUNT = 32;        // 32 vector registers

  typedef enum logic[6:0] {
    R_TYPE       = 7'h33,
    I_TYPE_0     = 7'h03,
    I_TYPE_1     = 7'h13,
    I_TYPE_2     = 7'h67,
    S_TYPE       = 7'h23,
    B_TYPE       = 7'h63,
    U_TYPE_0     = 7'h37,
    U_TYPE_1     = 7'h17,
    J_TYPE       = 7'h6F,
    V_TYPE_LOAD  = 7'h07,
    V_TYPE_STORE = 7'h27,
    V_TYPE_MMUL  = 7'h73
  } riscv_op_t;

  // ALU Op Types
  typedef enum logic [3:0] {
    OP_ADD,
	  OP_SUB,
    OP_SLL,
    OP_SRL,
    OP_SRA,
    OP_OR,
    OP_AND,
    OP_XOR,
    OP_SLTU,
    OP_SLT,
	  OP_SLLI,
	  OP_MUL,
    MAT_ADD,
    MAT_MUL
  } alu_op_t;

  // VALU Op Types
  typedef enum logic {
    V_ADD,
	  V_MMUL
  } valu_op_t;  
  
  // Memory Access Width ,an enumerated type that specifies memory access sizes as 2-bit values: BYTE, HALF_WORD, and WORD
  typedef enum logic [1:0] {
    BYTE      = 2'b00,
	  HALF_WORD = 2'b01,
	  WORD      = 2'b11
	} mem_access_size_t;
	
	
	// the R type format
	// Formed using {funct7[5],funct7[0],funct3}
	typedef enum logic [4:0] {
	  ADD   =  5'h0,
	  SUB   =  5'h10,
	  SLL   =  5'h1,
	  SLT   =  5'h2,
	  SLTU  =  5'h3,
	  XOR   =  5'h4,
	  SRL   =  5'h5,
	  SRA   =  5'h15,
	  OR    =  5'h6,
	  AND   =  5'h7,
	  MUL   =  5'h8
	} r_type_t;
	
	
   // I Type
  // Formed using {opcode[4], funct3}
  typedef enum logic [3:0] {
    LB     =  4'h0,
    LH     =  4'h1,
    LW     =  4'h2,
    LBU    =  4'h4,
    LHU    =  4'h5,
    ADDI   =  4'h8,
    SLTI   =  4'ha,
    SLTIU  =  4'hb,
    XORI   =  4'hc,
    ORI    =  4'he,
    ANDI   =  4'hf,
    SLLI   =  4'h9,
    SRXI   =  4'hd
  } i_type_t;
  
  
   // S Type
  typedef enum logic [1:0] {
   SB = 2'h0,
   SH = 2'h1,
   SW = 2'h2
  } s_type_t;
   
   
   // B type
   typedef enum logic [2:0] {
   BEQ  = 3'h0,
   BNE  = 3'h1,
   BLT  = 3'h4,
   BGE  = 3'h5,
   BLTU = 3'h6,
   BGEU = 3'h7
  } b_type_t;
  
  
  // U type
   typedef enum logic [6:0] {
   AUIPC = 7'h17,
   LUI = 7'h37
  } u_type_t;
   
   
   // J type
   typedef enum logic[5:0] {
    JAL = 6'h3
  } j_type_t;
  
  
  // Control signals
  typedef struct packed {
  logic         pc_sel;
  logic         op1_sel;
  logic         op2_sel;
  logic         data_req;
  logic  [1:0]  data_byte;
  logic         data_wr;
  logic         zero_extnd;
  logic  [3:0]  alu_funct_sel;
  logic         valu_funct_sel;
  logic         rf_wr_en;
  logic         vrf_wr_en; //VRF enable
  logic  [1:0]  rf_wr_data_sel;
  logic  [1:0]  vrf_wr_data_sel;
  } control_t;
 
  // VRF Write Data Source Selection
 typedef enum logic[1:0] {
  VALU  = 2'b00, 
  VMEM  = 2'b01,
  VIMM  = 2'b10,
  VPC   = 2'b11
 } vrf_wr_data_src_t;

  // Register File Write Data Source Selection
 typedef enum logic[1:0] {
  ALU = 2'b00, 
  MEM = 2'b01,
  IMM = 2'b10,
  PC  = 2'b11
 } rf_wr_data_src_t;
 
endpackage