`timescale 1ns/1ps                      // Simulation timescale: 1 ns, precision 1 ps

module valu 
  import yarp_pkg ::*;                 // Import all constants/types from yarp_pkg package
# (
  parameter ELEM_WIDTH = 32,           // Width of each vector element
  parameter VEC_COUNT  = 4             // Number of elements/vectors (4x4 for this module)
) (
  input  logic [ELEM_WIDTH*VEC_COUNT-1:0] vec_a [VEC_COUNT],  // Input vectors A (4 vectors, 128-bit each)
  input  logic [ELEM_WIDTH*VEC_COUNT-1:0] vec_b [VEC_COUNT],  // Input vectors B (4 vectors, 128-bit each)
  input  logic                            valu_op,            // Operation selector (V_ADD or V_MMUL)
  output logic [ELEM_WIDTH*VEC_COUNT-1:0] result [VEC_COUNT]  // Output result vectors (4 vectors)
);

  // Local unpacked arrays for element-wise operations
  logic [ELEM_WIDTH-1:0] a_unpacked   [VEC_COUNT][VEC_COUNT]; // Unpacked elements of A
  logic [ELEM_WIDTH-1:0] b_unpacked   [VEC_COUNT][VEC_COUNT]; // Unpacked elements of B
  logic [ELEM_WIDTH-1:0] res_unpacked [VEC_COUNT][VEC_COUNT]; // Result elements

  // Unpack input vectors into individual elements for computation
  always_comb 
  begin
    for (int i = 0; i < VEC_COUNT; i++)           // Loop over each vector
    begin
      for (int j = 0; j < VEC_COUNT; j++)         // Loop over each element within vector
      begin
        a_unpacked[i][j] = vec_a[i][ELEM_WIDTH*(j+1)-1 -: ELEM_WIDTH];  // Extract element j from vector i of A
        b_unpacked[i][j] = vec_b[i][ELEM_WIDTH*(j+1)-1 -: ELEM_WIDTH];  // Extract element j from vector i of B
      end
    end
  end

  // Perform selected vector operation
  always_comb 
  begin
    // Initialize all result elements to zero
    for (int i = 0; i < VEC_COUNT; i++) 
    begin
      for (int j = 0; j < VEC_COUNT; j++) 
      begin
        res_unpacked[i][j] = '0;
      end
    end

    case (valu_op)                              // Select operation based on input
      V_ADD:                                    // Vector addition
      begin
        for (int i = 0; i < VEC_COUNT; i++) 
        begin
          for (int j = 0; j < VEC_COUNT; j++) 
          begin
            res_unpacked[i][j] = a_unpacked[i][j] + b_unpacked[i][j];  // Element-wise addition
          end
        end
      end

      V_MMUL:                                   // Matrix multiplication / dot product
      begin
        for (int i = 0; i < VEC_COUNT; i++) 
        begin
          for (int j = 0; j < VEC_COUNT; j++) 
          begin
            for (int k = 0; k < VEC_COUNT; k++) 
            begin
              res_unpacked[i][j] += a_unpacked[i][k] * b_unpacked[k][j]; // Sum of products
            end
          end
        end
      end
    endcase
  end

  // Pack the computed result elements back into output vectors
  always_comb 
  begin
    for (int i = 0; i < VEC_COUNT; i++) 
    begin
      for (int j = 0; j < VEC_COUNT; j++) 
      begin
        result[i][ELEM_WIDTH*(j+1)-1 -: ELEM_WIDTH] = res_unpacked[i][j]; // Pack element j into vector i
      end
    end
  end

endmodule
