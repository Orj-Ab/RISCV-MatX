`timescale 1ns/1ps

module tb_riscv_top;

    // Testbench signals
    logic clk;
    logic reset_n;

    integer cycle_count = 0;

    // Clock generation: 10ns clock period (50MHz)
    always #5 clk = ~clk;

    // Count cycles
    always_ff @(posedge clk) begin
        if (reset_n)
            cycle_count <= cycle_count + 1;
    end

    // Instantiate the DUT
    riscv_top #(
        .RESET_PC(32'h000)
    ) uut (
        .clk(clk),
        .reset_n(reset_n)
    );

    initial begin
        clk = 0;
        reset_n = 0;
        #10 reset_n = 1;
        #5000;
        $display("=== Total Simulation Cycles: %0d ===", cycle_count);
        $finish;
    end

endmodule
