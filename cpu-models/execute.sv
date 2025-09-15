`timescale 1ns/1ps                          // Simulation time unit = 1 ns, precision = 1 ps

// Execute module: Implements the Arithmetic Logic Unit (ALU)
// Performs arithmetic, logic, shift, and comparison operations
module execute import yarp_pkg ::*;(
  input  logic    [31:0]  opr_a_i,          // First 32-bit operand input
  input  logic    [31:0]  opr_b_i,          // Second 32-bit operand input
  input  logic    [ 3:0]  alu_funct_i,      // ALU control function (selects operation)
  output logic    [31:0]  alu_res_o         // 32-bit ALU result (or address for load/store)
);

  // Internal signals for two's complement representation of inputs
  logic  [31:0]  twos_compl_a;              // Two's complement form of operand A
  logic  [31:0]  twos_compl_b;              // Two's complement form of operand B
  logic  [31:0]  alu_res;                   // Internal ALU result register

  // Compute two's complement of opr_a_i if negative, else keep as-is
  assign twos_compl_a = opr_a_i[31] ? ~opr_a_i + 32'h1 : opr_a_i;
  // Compute two's complement of opr_b_i if negative, else keep as-is
  assign twos_compl_b = opr_b_i[31] ? ~opr_b_i + 32'h1 : opr_b_i;

  // Combinational ALU operations (selected by alu_funct_i)
  always_comb 
  begin
    case(alu_funct_i)                       // Select operation based on function code
      OP_ADD  : alu_res = opr_a_i + opr_b_i;         // Addition
      OP_SUB  : alu_res = opr_a_i - opr_b_i;         // Subtraction
      OP_SLL  : alu_res = opr_a_i << opr_b_i[4:0];   // Logical shift left
      OP_SRL  : alu_res = opr_a_i >> opr_b_i[4:0];   // Logical shift right
      OP_SRA  : alu_res = $signed(opr_a_i) >>> opr_b_i[4:0]; // Arithmetic shift right (signed)
      OP_OR   : alu_res = opr_a_i | opr_b_i;         // Bitwise OR
      OP_AND  : alu_res = opr_a_i & opr_b_i;         // Bitwise AND
      OP_XOR  : alu_res = opr_a_i ^ opr_b_i;         // Bitwise XOR
      OP_SLTU : alu_res = {31'h0, opr_a_i < opr_b_i}; // Set Less Than Unsigned (1 if A < B)
      OP_SLT  : alu_res = {31'h0, twos_compl_a < twos_compl_b}; // Set Less Than Signed
      OP_SLLI : alu_res = opr_a_i << opr_b_i[4:0];   // Shift Left Logical Immediate
      OP_MUL  : alu_res = opr_a_i * opr_b_i;         // Multiplication
      default : alu_res = 32'h0;                     // Default case (output zero)
    endcase
  end

  // Assign final result to output
  assign alu_res_o = alu_res;

endmodule
