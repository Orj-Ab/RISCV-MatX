`timescale 1ns/1ps
module tb_valu;
  import yarp_pkg::*;
  localparam int ELEM_WIDTH = 32;
  localparam int VEC_COUNT  = 4;
  logic [ELEM_WIDTH*VEC_COUNT-1:0] vec_a [VEC_COUNT];
  logic [ELEM_WIDTH*VEC_COUNT-1:0] vec_b [VEC_COUNT];
  logic                            valu_op;
  logic [ELEM_WIDTH*VEC_COUNT-1:0] result [VEC_COUNT];
  valu #(
    .ELEM_WIDTH(ELEM_WIDTH),
    .VEC_COUNT(VEC_COUNT)
  ) dut (
    .vec_a(vec_a),
    .vec_b(vec_b),
    .valu_op(valu_op),
    .result(result)
  );
  function automatic logic [ELEM_WIDTH*VEC_COUNT-1:0] pack_vector(input logic [ELEM_WIDTH-1:0] data [VEC_COUNT]);
    logic [ELEM_WIDTH*VEC_COUNT-1:0] vec_packed;
    for (int i = 0; i < VEC_COUNT; i++)
      vec_packed[ELEM_WIDTH*(i+1)-1 -: ELEM_WIDTH] = data[i];
    return vec_packed;
  endfunction
  logic [ELEM_WIDTH-1:0] mat_a [VEC_COUNT][VEC_COUNT];
  logic [ELEM_WIDTH-1:0] mat_b [VEC_COUNT][VEC_COUNT];
  initial begin
    for (int i = 0; i < VEC_COUNT; i++) begin
      for (int j = 0; j < VEC_COUNT; j++) begin
        mat_a[i][j] = i + j;           // A: increasing values
        mat_b[i][j] = (i == j) ? 1 : 0; // B: identity matrix
      end
      vec_a[i] = pack_vector(mat_a[i]);
      vec_b[i] = pack_vector(mat_b[i]);
    end
    valu_op = V_ADD;
    #1;
    valu_op = V_MMUL;
    #1;
    $finish;
  end
endmodule
