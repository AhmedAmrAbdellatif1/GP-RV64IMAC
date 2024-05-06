module riscv_pc #(parameter KERNEL_PC = 'h00000000) (
  input  wire        i_riscv_pc_clk    ,
  input  wire        i_riscv_pc_rst    ,
  input  wire        i_riscv_pc_stallpc,
  input  wire [63:0] i_riscv_pc_nextpc ,
  output reg  [63:0] o_riscv_pc_pc
);

  always @(posedge i_riscv_pc_clk or posedge i_riscv_pc_rst) begin
    if(i_riscv_pc_rst)
      o_riscv_pc_pc <= KERNEL_PC;
    else if(!i_riscv_pc_stallpc)
      o_riscv_pc_pc <= i_riscv_pc_nextpc;
  end
endmodule