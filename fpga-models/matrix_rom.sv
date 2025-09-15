`timescale 1ns/1ps

module matrix_rom
#(
  parameter VLEN       = 128,
  parameter VEC_COUNT  = 4,
  parameter MEM_DEPTH  = 32
)(
  input  logic [4:0] addr_a, // Base address for Matrix A
  input  logic [4:0] addr_b, // Base address for Matrix B

  output logic [VLEN-1:0] vec_a [VEC_COUNT],
  output logic [VLEN-1:0] vec_b [VEC_COUNT]
);

  // ROM to store vectors
  logic [VLEN-1:0] mem [0:MEM_DEPTH-1];

  // Initialize with fixed matrices
  initial begin
    // Matrix A (row-major)
    mem[0] = {32'd4, 32'd3, 32'd2, 32'd1};
    mem[1] = {32'd8, 32'd7, 32'd6, 32'd5};
    mem[2] = {32'd12, 32'd11, 32'd10, 32'd9};
    mem[3] = {32'd16, 32'd15, 32'd14, 32'd13};

    // Matrix B (column-major)
    mem[4] = {32'd8, 32'd6, 32'd4, 32'd2};
    mem[5] = {32'd16, 32'd14, 32'd12, 32'd10};
    mem[6] = {32'd7, 32'd5, 32'd3, 32'd1};
    mem[7] = {32'd15, 32'd13, 32'd11, 32'd9};

    for (int i = 8; i < MEM_DEPTH; i++)
      mem[i] = '0;
  end

  // Combinational read
  always_comb begin
    for (int i = 0; i < VEC_COUNT; i++) begin
      vec_a[i] = mem[addr_a + i];
      vec_b[i] = mem[addr_b + i];
    end
  end

endmodule
