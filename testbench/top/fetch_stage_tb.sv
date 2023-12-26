`timescale 1ns/1ns

module riscv_top_tb();

/*********************** Parameters ***********************/
  parameter CLK_PERIOD = 50;
  parameter HALF_PERIOD = CLK_PERIOD/2;

/************** Internal Signals Declaration **************/
  logic clk,rst;
  logic [31:0] instr;
    logic [63:0] nextpc;
  logic [63:0] pc;
  logic [63:0] pcplus4;
  logic [63:0] aluexe;
  
  assign pc = DUT.u_top_datapath.u_riscv_fstage.o_riscv_fstage_pc;
  assign stall_pc = DUT.u_top_datapath.u_riscv_fstage.i_riscv_fstage_stallpc;
  assign pcsrc = DUT.u_top_datapath.u_riscv_fstage.i_riscv_fstage_pcsrc;
  assign aluexe= DUT.u_top_datapath.u_riscv_fstage.i_riscv_fstage_aluexe;
  assign pcplus4=DUT.u_top_datapath.u_riscv_fstage.o_riscv_fstage_pcplus4;
  assign nextpc=DUT.u_top_datapath.u_riscv_fstage.o_riscv_pcmux_nextpc;
  assign instr=DUT.riscv_im_inst_datapath;
  

/********************* Initial Blocks *********************/
  initial begin : proc_fetch
  #CLK_PERIOD;
   pc_check (0);
   instr_check('h00a00413);
  #CLK_PERIOD;
   pc_check (4);
   instr_check('h01400493);
   nextpc_check(8);
  #CLK_PERIOD;
   pc_check (8);
   instr_check('h00100317);
   #CLK_PERIOD; 
    pc_check (12);
   instr_check('h008002ef ); //jump 
   #CLK_PERIOD; 
    pc_check (16);
   instr_check('h00000013);  
   #CLK_PERIOD; 
    pc_check (20);
   instr_check('h00000013); 
   pcsrc_check(1);
    #CLK_PERIOD; 
    pc_check (24);
   instr_check('h00603023);
    #CLK_PERIOD; 
    pc_check (28);
   instr_check('h00033383);
    #CLK_PERIOD; 
    pc_check (32);
   instr_check('h00940533);
    #CLK_PERIOD; 
    pc_check (36);
   instr_check('h200002b7);
     #CLK_PERIOD; 
    pc_check (40);
   instr_check('hfe7316e3); //bne
   #CLK_PERIOD; 
    pc_check (44);
   instr_check('h0120009b);
   #CLK_PERIOD; 
    pc_check (48);
   instr_check('h00808267);
   #CLK_PERIOD; 
    pc_check (52);
   instr_check('h00000013);
   #CLK_PERIOD; 
    pc_check (56);
   instr_check('h009431b3);
   #CLK_PERIOD; 
    pc_check (60);
   instr_check('h00f00413);
     #CLK_PERIOD;
   pc_check (64);
   instr_check('h40940db3);
     #CLK_PERIOD;
   pc_check (68);
   instr_check('h0084eeb3);
     #CLK_PERIOD;
   pc_check (72);
   instr_check('h00249e1b);
     #CLK_PERIOD;
   pc_check (76);
   instr_check('h00000013);
     #CLK_PERIOD;
   pc_check (80);
   instr_check('h01e00493);
     #CLK_PERIOD;
   pc_check (84);
   instr_check('h00948033);
   
  #CLK_PERIOD;
   
pc_check (88);
   instr_check('h00030383);
     #CLK_PERIOD;
   pc_check (92);
   instr_check('h00700233);
   
  #CLK_PERIOD;
   pc_check (96);
   instr_check('h00000863);
     #CLK_PERIOD;
   pc_check (100);
   instr_check('h07c10093);
     #CLK_PERIOD;
   pc_check (104);
   instr_check('h07d10093);
     #CLK_PERIOD;
   pc_check (108);
   instr_check('h07f10093);
   #CLK_PERIOD;
   pc_check (112);
   instr_check('h00a00093);
      
   
   
   

   
  

  $stop;
  end

  /** Reseting Block **/
  initial begin : proc_reseting
    rst = 1'b1;
    #CLK_PERIOD;
    rst = 1'b0;
  end

  /** Clock Generation Block **/
  initial begin : proc_clock
    clk = 1'b1;
    forever begin
      #HALF_PERIOD clk = ~clk;
    end
  end

/******************** Tasks & Functions *******************/
task pc_check ;
  input [63:0] expected_pc;
    if(pc != expected_pc)
      $display("[%0t] pc failed",$time);
  endtask
  
task instr_check ;
  input [31:0] expected_instr;
    if(expected_instr != instr)
      $display("[%0t] instr failed",$time);
  endtask
  
  task stall_check ;
  input  expected_stall;
    if(expected_stall != stall_pc)
      $display("[%0t] stall failed",$time);
  endtask
  
   task pcsrc_check ;
  input  expected_pcsrc;
    if(expected_pcsrc != pcsrc)
      $display("[%0t] pcsrc failed",$time);
  endtask
  
  task pcplus4_check ;
  input [63:0] expected_pcplus4;
    if(pcplus4 != expected_pcplus4)
      $display("[%0t] pcplus4 failed",$time);
  endtask
  
  task nextpc_check ;
  input [63:0] expected_nextpc;
    if(nextpc != expected_nextpc)
      $display("[%0t] nextpc failed",$time);
  endtask

/******************** DUT Instantiation *******************/

  riscv_top DUT
  (
    .i_riscv_clk(clk),
    .i_riscv_rst(rst)
  );
endmodule

