`timescale 1ns/1ps

module v_regfile 
    import yarp_pkg ::*;
# (
	parameter VLEN       = 128, // Total vector width
	parameter ELEM_WIDTH = 32,  // Width of each element
	parameter VREG_DEPTH = 32,  // Total number of vector registers

	localparam REG_WIDTH = $clog2(VREG_DEPTH)
) (
	input  logic                 clk,
	input  logic                 reset_n,

	// Read addresses for A and B matrices
	input  logic [REG_WIDTH-1:0] rs1_addr,
	input  logic [REG_WIDTH-1:0] rs2_addr,

	// 4 output vectors for each matrix
	output logic [VLEN-1:0]      rs1_data [4],
	output logic [VLEN-1:0]      rs2_data [4],

	// Write port
	input  logic                 wen,
	input  logic [REG_WIDTH-1:0] rd_addr,
	input  logic [VLEN     -1:0] rd_data [4]
);

	int file; // File handle for writing memory contents
	// Internal vector register file
	logic [VLEN-1:0] vregs [0:VREG_DEPTH-1];

	// Read 4 consecutive vectors for rs1 (Matrix A rows)
	always_comb 
	begin
		for (int i = 0; i < 4; i++) 
		begin
			rs1_data[i] = vregs[rs1_addr + i];
		end
	end

	// Read 4 consecutive vectors for rs2 (Matrix B columns)
	always_comb 
	begin
		for (int i = 0; i < 4; i++) 
		begin
			rs2_data[i] = vregs[rs2_addr + i];
		end
	end

	// Write logic
	always_ff @(posedge clk or negedge reset_n) 
	begin
		if (~reset_n) 
		begin
			for (int i = 0; i < VREG_DEPTH; i++) 
			begin
				vregs[i] <= '0;
			end
		end 
		else if (wen) 
		begin
			for (int i = 0; i < 4; i++) 
			begin
				vregs[rd_addr + i] <= rd_data[i];
			end
		end
	end


	// dump data_memory contents to file: data_mem.results
	final begin
		file = $fopen("vector_regfile.results", "w");
		if (file) begin
			for (int i = 0; i < 32; i++) begin
				$fwrite(file, "Addr %02d: %0d %0d %0d %0d\n", i,
					vregs[i][127:96],
					vregs[i][95:64],
					vregs[i][63:32],
					vregs[i][31:0]);
			end
			$fclose(file);
			$display("Memory contents written to vector_regfile.results");
		end else begin
			$fatal(2, "Could not open vector_regfile.results for writing.");
		end
	end

endmodule
