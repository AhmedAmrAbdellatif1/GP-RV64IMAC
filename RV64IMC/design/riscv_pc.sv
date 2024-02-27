module riscv_pc #(parameter width =64)(
 input  logic               i_riscv_pc_clk,
 input  logic               i_riscv_pc_rst,               //active high rst 
 input  logic               i_riscv_pc_stallpc,
 input  logic [width-1:0]   i_riscv_pc_nextpc,
 output logic [width-1:0]   o_riscv_pc_pc);
 
 always_ff @(posedge i_riscv_pc_clk or posedge i_riscv_pc_rst)
 begin
   if(i_riscv_pc_rst)
     o_riscv_pc_pc<='h0;
   else
    if(!i_riscv_pc_stallpc)
     o_riscv_pc_pc<=i_riscv_pc_nextpc;
 end 
 endmodule