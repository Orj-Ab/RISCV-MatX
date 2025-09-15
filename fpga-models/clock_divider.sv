`timescale 1ns/1ps

module clock_divider (
  input  logic clk,        // 50 MHz clock
  input  logic reset_n,
  output logic clk_slow
);

  parameter DIVISOR = 150_000_000; // 50 MHz / 150M = 0.33 Hz (בערך 3 שניות)

  logic [$clog2(DIVISOR)-1:0] counter;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      counter <= 0;
      clk_slow <= 0;
    end else if (counter == (DIVISOR/2)-1) begin
      counter <= 0;
      clk_slow <= ~clk_slow; // הפוך את השעון
    end else begin
      counter <= counter + 1;
    end
  end

endmodule
