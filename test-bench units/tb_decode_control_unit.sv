`timescale 1ns/1ps

module tb_decode_control_unit;

  import yarp_pkg::*;
  logic [31:0] instr;
  logic [6:0]  op;
  logic [2:0]  funct3;
  logic [6:0]  funct7;
  logic [4:0]  rs1, rs2, rd;
  logic        r_type, i_type, s_type, b_type, u_type, j_type;
  logic        is_vector_load, is_vector_store, is_vector_mmul;
  logic        pc_sel_o, op1_sel_o, op2_sel_o;
  logic        data_req_o, data_wr_o, zero_extnd_o;
  logic        rf_wr_en_o, vrf_wr_en_o;
  logic [1:0]  rf_wr_data_o, vrf_wr_data_o, data_byte_o;
  logic [3:0]  alu_funct_o;
  logic        valu_funct_o;
  logic        is_vector_load_o, is_vector_store_o, is_vector_mmul_o;
  logic funct7_bit5, funct7_bit0;
  assign funct7_bit5 = funct7[5];
  assign funct7_bit0 = funct7[0];
  decode decode_inst (
    .instr_mem_instr_i(instr),
    .funct3_o(funct3),
    .funct7_o(funct7),
    .op_o(op),
    .r_type_o(r_type),
    .i_type_o(i_type),
    .s_type_o(s_type),
    .b_type_o(b_type),
    .u_type_o(u_type),
    .j_type_o(j_type),
    .rs1_addr_o(rs1),
    .rs2_addr_o(rs2),
    .rd_addr_o(rd),
    .instr_immed_o(), // unused
    .is_vector_load_o(is_vector_load),
    .is_vector_store_o(is_vector_store),
    .is_vector_mmul_o(is_vector_mmul)
  );
  control_unit control_inst ( // Make sure your module is defined with capital "C"
    .is_j_type_i(j_type),
    .is_i_type_i(i_type),
    .is_b_type_i(b_type),
    .is_u_type_i(u_type),
    .is_r_type_i(r_type),
    .is_s_type_i(s_type),
    .is_vector_load_i(is_vector_load),
    .is_vector_store_i(is_vector_store),
    .is_vector_mmul_i(is_vector_mmul),
    .instr_opcode_i(op),
    .instr_funct3_i(funct3),
    .instr_funct7_bit5_i(funct7_bit5),
    .instr_funct7_bit0_i(funct7_bit0),
    .pc_sel_o(pc_sel_o),
    .op1_sel_o(op1_sel_o),
    .op2_sel_o(op2_sel_o),
    .data_req_o(data_req_o),
    .data_wr_o(data_wr_o),
    .zero_extnd_o(zero_extnd_o),
    .rf_wr_en_o(rf_wr_en_o),
    .vrf_wr_en_o(vrf_wr_en_o),
    .rf_wr_data_o(rf_wr_data_o),
    .vrf_wr_data_o(vrf_wr_data_o),
    .data_byte_o(data_byte_o),
    .alu_funct_o(alu_funct_o),
    .valu_funct_o(valu_funct_o),
    .is_vector_load_o(is_vector_load_o),
    .is_vector_store_o(is_vector_store_o),
    .is_vector_mmul_o(is_vector_mmul_o)
  );
  initial begin
    instr = 32'h002081b3; #1;
    instr = 32'h00410283; #1;
    instr = 32'h00412023; #1;
    instr = 32'h0000006f; #1;
    instr = 32'h00000073; #1;
  end
endmodule
