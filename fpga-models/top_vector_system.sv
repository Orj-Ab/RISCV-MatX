`timescale 1ns/1ps

module top_vector_system (
  input  logic clk,
  input  logic reset_n,
  output logic done,
  output logic [127:0] result [3:0]
);

  parameter ELEM_WIDTH = 32;
  parameter VEC_COUNT  = 4;
  parameter VLEN       = ELEM_WIDTH * VEC_COUNT;

  // בקרים
  logic [4:0] addr_a, addr_b;
  logic       start_valu;

  // יציאות הזיכרון
  logic [VLEN-1:0] vec_a_raw [VEC_COUNT];
  logic [VLEN-1:0] vec_b_raw [VEC_COUNT];

  // וקטורים שמוזנים ל־VALU (FF!)
  logic [VLEN-1:0] vec_a [VEC_COUNT];
  logic [VLEN-1:0] vec_b [VEC_COUNT];

  // מחולל פקודות FSM
  fsm_controller fsm_inst (
    .clk(clk),
    .reset_n(reset_n),
    .addr_a(addr_a),
    .addr_b(addr_b),
    .start_valu(start_valu),
    .done(done)
  );

  // זיכרון מטריצה
  matrix_rom #(
    .VLEN(VLEN),
    .VEC_COUNT(VEC_COUNT)
  ) rom_inst (
    .addr_a(addr_a),
    .addr_b(addr_b),
    .vec_a(vec_a_raw),
    .vec_b(vec_b_raw)
  );

  // טעינת וקטורים ברגע ש־start_valu פעיל (FF!!)
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      for (int i = 0; i < VEC_COUNT; i++) begin
        vec_a[i] <= '0;
        vec_b[i] <= '0;
      end
    end else if (start_valu) begin
      for (int i = 0; i < VEC_COUNT; i++) begin
        vec_a[i] <= vec_a_raw[i];
        vec_b[i] <= vec_b_raw[i];
      end
    end
  end

  // יחידת חישוב (vector ALU)
  valu #(
    .ELEM_WIDTH(ELEM_WIDTH),
    .VEC_COUNT(VEC_COUNT)
  ) valu_inst (
    .vec_a(vec_a),
    .vec_b(vec_b),
    .result(result)
  );

endmodule
