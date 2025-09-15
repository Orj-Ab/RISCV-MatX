module binary_to_bcd (
  input  logic [11:0] binary_in, // עד 4095 (3 ספרות)
  output logic [3:0] hundreds,
  output logic [3:0] tens,
  output logic [3:0] ones
);

  logic [11:0] temp;
  always_comb begin
    temp = binary_in;
    hundreds = temp / 100;
    temp = temp % 100;
    tens = temp / 10;
    ones = temp % 10;
  end

endmodule
