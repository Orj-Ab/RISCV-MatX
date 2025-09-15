`timescale 1ns/1ps

module fetch (
   input  logic          clk,
   input  logic          reset_n,
   input  logic [31:0]   instr_mem_rd_data_i,
   input  logic [31:0]   pc_q_i,
   output logic          instr_mem_req_o,
   output logic [31:0]   instr_mem_addr_o,
   output logic [31:0]   instr_mem_instr_o
);
 
   logic instr_mem_req_q;

   assign instr_mem_req_o   = instr_mem_req_q;
   assign instr_mem_addr_o  = pc_q_i;
   assign instr_mem_instr_o = instr_mem_rd_data_i;

   always_ff @(posedge clk or negedge reset_n) 
   begin 
      if (!reset_n) 
         instr_mem_req_q <= 1'b0;
	   else
	      instr_mem_req_q <= 1'b1;
	end

endmodule
 