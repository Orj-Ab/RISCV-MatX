`timescale 1ns/1ps

module valu 
  import yarp_pkg ::*;
# (
  parameter ELEM_WIDTH = 32,
  parameter VEC_COUNT  = 4
) (
  input  logic [ELEM_WIDTH*VEC_COUNT-1:0] vec_a [VEC_COUNT],  // 4 packed 128-bit vectors (each with 4 elements)
  input  logic [ELEM_WIDTH*VEC_COUNT-1:0] vec_b [VEC_COUNT],  // 4 packed 128-bit vectors
  input  logic                            valu_op,            // Operation selector

  output logic [ELEM_WIDTH*VEC_COUNT-1:0] result [VEC_COUNT]  // 4 packed 128-bit result vectors
);

  // Local unpacked arrays for element-wise access
  logic [ELEM_WIDTH-1:0] a_unpacked   [VEC_COUNT][VEC_COUNT];
  logic [ELEM_WIDTH-1:0] b_unpacked   [VEC_COUNT][VEC_COUNT];
  logic [ELEM_WIDTH-1:0] res_unpacked [VEC_COUNT][VEC_COUNT];

  // Unpack input vectors
  always_comb 
  begin
    for (int i = 0; i < VEC_COUNT; i++) 
    begin
      for (int j = 0; j < VEC_COUNT; j++) 
      begin
        a_unpacked[i][j] = vec_a[i][ELEM_WIDTH*(j+1)-1 -: ELEM_WIDTH];
        b_unpacked[i][j] = vec_b[i][ELEM_WIDTH*(j+1)-1 -: ELEM_WIDTH];
      end
    end
  end

  // Perform operation
  always_comb 
  begin
    // Default: zero output
    for (int i = 0; i < VEC_COUNT; i++) 
    begin
      for (int j = 0; j < VEC_COUNT; j++) 
      begin
        res_unpacked[i][j] = '0;
      end
    end

    case (valu_op)
      V_ADD: 
      begin  // V_ADD -- Element-wise addition
        for (int i = 0; i < VEC_COUNT; i++) 
        begin
          for (int j = 0; j < VEC_COUNT; j++) 
          begin
            res_unpacked[i][j] = a_unpacked[i][j] + b_unpacked[i][j];
          end
        end
      end

      V_MMUL: 
      begin  // Dot product: res[i][j] = sum over k of A[i][k] * B[k][j]
        for (int i = 0; i < VEC_COUNT; i++) 
        begin
          for (int j = 0; j < VEC_COUNT; j++) 
          begin
            for (int k = 0; k < VEC_COUNT; k++) 
            begin
              res_unpacked[i][j] += a_unpacked[i][k] * b_unpacked[k][j];
              // res_unpacked[i][j] = res_unpacked[i][j] + (a_unpacked[i][k] * b_unpacked[k][j]);
            end
          end
        end
      end
    endcase
  end

  // Pack result back into 128-bit output vectors
  always_comb 
  begin
    for (int i = 0; i < VEC_COUNT; i++) 
    begin
      for (int j = 0; j < VEC_COUNT; j++) 
      begin
        result[i][ELEM_WIDTH*(j+1)-1 -: ELEM_WIDTH] = res_unpacked[i][j];
      end
    end
  end

endmodule
