`timescale 1ns/1ps

module tb_riscv_top;

    // Testbench signals
    logic clk;             // Clock signal
    logic reset_n;         // Active-low reset signal

    integer cycle_count = 0; // Counter for simulation cycles

    // Clock generation: 10ns period (50MHz)
    always #5 clk = ~clk; // Toggle clock every 5ns

    // Count cycles when reset is de-asserted
    always_ff @(posedge clk) begin
        if (reset_n)
            cycle_count <= cycle_count + 1;
    end

    // Instantiate the DUT (Device Under Test)
    riscv_top #(
        .RESET_PC(32'h000) // Set initial PC
    ) uut (
        .clk(clk),
        .reset_n(reset_n)
    );

    // Simulation sequence
    initial begin
        clk = 0;           // Initialize clock
        reset_n = 0;       // Assert reset
        #10 reset_n = 1;   // De-assert reset after 10ns
        #5000;             // Run simulation for 5000ns
        $display("=== Total Simulation Cycles: %0d ===", cycle_count); // Print cycle count
        $finish;           // End simulation
    end

endmodule
