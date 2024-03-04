module riscv_wbstage (
   input    logic [1:0]    i_riscv_wb_resultsrc       ,
   input    logic [63:0]   i_riscv_wb_pcplus4         ,
   input    logic [63:0]   i_riscv_wb_result          ,
   input    logic [63:0]   i_riscv_wb_memload         ,
   input    logic [63:0]   i_riscv_wb_uimm            ,
   input    logic [63:0]   i_riscv_wb_csrout          , //<--- Trap
   input    logic          i_riscv_wb_iscsr           , //<--- Trap
   input    logic          i_riscv_wb_gototrap        , //<--- Trap
   input    logic          i_riscv_wb_returnfromtrap  , //<--- Trap
   output   logic [1:0]    o_riscv_wb_pcsel           , //<--- Trap
   output   logic          o_riscv_wb_flush           , //<--- Trap
   output   logic [63:0]   o_riscv_wb_rddata            //modified position
);

logic [63:0] riscv_wb_rddata ; //<---- NEW

riscv_mux4 u_result_mux (
   .i_riscv_mux4_sel  (i_riscv_wb_resultsrc),
   .i_riscv_mux4_in0  (i_riscv_wb_pcplus4)  ,
   .i_riscv_mux4_in1  (i_riscv_wb_result)   ,
   .i_riscv_mux4_in2  (i_riscv_wb_memload)  ,
   .i_riscv_mux4_in3  (i_riscv_wb_uimm)     ,  
   .o_riscv_mux4_out  (riscv_wb_rddata)
);

riscv_trap_wb trap_wb (
  .i_riscv_trap_gototrap        (i_riscv_wb_gototrap)         ,                  
  .i_riscv_trap_returnfromtrap  (i_riscv_wb_returnfromtrap)   ,  
  .o_riscv_trap_flush           (o_riscv_wb_flush)            ,                    
  .o_riscv_trap_pcsel           (o_riscv_wb_pcsel)                       
);

riscv_mux2 mux2_wb (
  .i_riscv_mux2_sel (i_riscv_wb_iscsr)  ,   
  .i_riscv_mux2_in0 (riscv_wb_rddata)   ,     
  .i_riscv_mux2_in1 (i_riscv_wb_csrout) ,  
  .o_riscv_mux2_out (o_riscv_wb_rddata)  
);

endmodule 