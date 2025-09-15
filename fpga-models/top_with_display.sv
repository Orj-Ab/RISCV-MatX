`timescale 1ns/1ps

module top_with_display (
  input  logic clk,
  input  logic reset_n,
  output logic done,
  output logic [6:0] HEX0, HEX1, HEX2,
  output logic [6:0] HEX3, HEX4, HEX5
);

  // חיבור לתוצאה מלאה 4x4 (4 וקטורים כל אחד בגודל 128 ביט)
  logic [127:0] result [3:0];

  // מחשב מטריצה
  top_vector_system core (
    .clk(clk),
    .reset_n(reset_n),
    .done(done),
    .result(result)
  );

  // מחלק שעון (~2Hz)
  logic clk_slow;
  clock_divider clkdiv_inst (
    .clk(clk),
    .reset_n(reset_n),
    .clk_slow(clk_slow)
  );

  // מונה תצוגה – עובר על 16 ערכים (4x4)
  logic [4:0] display_counter;
  always_ff @(posedge clk_slow or negedge reset_n) begin
    if (!reset_n)
      display_counter <= 0;
    else if (display_counter < 15)
      display_counter <= display_counter + 1;
    else
      display_counter <= 0;
  end

  logic [1:0] row_idx, col_idx;
  assign row_idx = 3 - display_counter[3:2];   // סורק משורה עליונה לתחתונה
  assign col_idx = display_counter[1:0];       // סורק מימין לשמאל בתוך שורה

  // חילוץ ערך מתוך מטריצת תוצאה
  logic [31:0] value_full;
  assign value_full = result[row_idx][32*col_idx +: 32];

  // הגבלת ערך לתצוגה (max 999)
  logic [11:0] display_value;
  always_comb begin
    if (value_full > 999)
      display_value = 999;
    else
      display_value = value_full[11:0];
  end

  // המרה ל־BCD
  logic [3:0] hundreds, tens, ones;
  binary_to_bcd bcd_inst (
    .binary_in(display_value),
    .hundreds(hundreds),
    .tens(tens),
    .ones(ones)
  );

  // פענוח 7-SEG
  seven_seg_decoder ssd0 (.bcd(ones),     .seg(HEX0));
  seven_seg_decoder ssd1 (.bcd(tens),     .seg(HEX1));
  seven_seg_decoder ssd2 (.bcd(hundreds), .seg(HEX2));

  // תצוגות נוספות כבויות
  assign HEX3 = 7'b1111111;
  assign HEX4 = 7'b1111111;
  assign HEX5 = 7'b1111111;

endmodule
