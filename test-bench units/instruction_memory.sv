`timescale 1ns/1ps

module instruction_memory (
    input  logic         instr_mem_req_i,
    input  logic [31:0]  instr_mem_addr_i,
    output logic [31:0]  instr_mem_rd_data_o
);

    // Memory declaration
    logic [31:0] memory  [0:495] ; // 495 words of 32 bits each
    
    initial 
    begin 
		$readmemh("C:/Users/WAKED/Desktop/r32imv/MA.txt",memory);
    end
    // On reset, clear output; otherwise, respond to requests
    always_ff @(*) 
    begin
        if (instr_mem_req_i) 
        begin
            instr_mem_rd_data_o <= memory[instr_mem_addr_i[31:2]];
		end  
	end

endmodule
