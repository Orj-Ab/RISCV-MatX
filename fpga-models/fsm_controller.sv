`timescale 1ns/1ps

module fsm_controller #(
  parameter VLEN = 128,
  parameter VEC_COUNT = 4
)(
  input  logic        clk,
  input  logic        reset_n,
  output logic [4:0]  addr_a,     // base address for A matrix
  output logic [4:0]  addr_b,     // base address for B matrix
  output logic        start_valu, // enable VALU to compute
  output logic        done        // high when multiplication is complete
);

  typedef enum logic [1:0] {
    IDLE,
    LOAD,
    EXECUTE,
    FINISH
  } state_t;

  state_t state, next_state;

  // FSM sequential logic
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      state <= IDLE;
    else
      state <= next_state;
  end

  // FSM combinational logic
  always_comb begin
    // defaults
    addr_a      = 5'd0;
    addr_b      = 5'd4;
    start_valu  = 1'b0;
    done        = 1'b0;

    case (state)
      IDLE: begin
        next_state = LOAD;
      end
      LOAD: begin
        next_state = EXECUTE;
      end
      EXECUTE: begin
        start_valu = 1'b1;
        next_state = FINISH;
      end
      FINISH: begin
        done = 1'b1;
        next_state = IDLE;  // ✅ חוזר ל-IDLE במקום להישאר ב-FINISH
      end
      default: next_state = IDLE;
    endcase
  end

endmodule
