module riscv_datapath #(parameter MXLEN = 64) (
  input  logic        i_riscv_datapath_clk            ,
  input  logic        i_riscv_datapath_rst            ,
  /************************* Fetch Stage Signals *************************/
  output logic [63:0] o_riscv_datapath_pc             ,
  /************************* Fetch PP Register Signals *************************/
  input  logic [31:0] i_riscv_datapath_inst           ,
  /************************* Memory Stage Signals *************************/
  input  logic [63:0] i_riscv_datapath_dm_rdata       ,
  output logic [ 4:0] o_riscv_datapath_rdaddr_m       ,
  output logic        o_riscv_datapath_memw_e         ,
  output logic        o_riscv_datapath_memr_e         ,
  output logic        o_riscv_datapath_amo            ,
  output logic [ 4:0] o_riscv_datapath_amo_op         ,
  output logic [ 1:0] o_riscv_datapath_storesrc_m     ,
  output logic [63:0] o_riscv_datapath_memodata_addr  ,
  output logic [63:0] o_riscv_datapath_storedata_m    ,
  /************************* WB Stage Signals *************************/
  input  logic        i_riscv_datapath_icache_stall_wb,
  /************************* Stall Signals *************************/
  input  logic        i_riscv_datapath_stall_dm       ,
  input  logic        i_riscv_datapath_stall_im       ,
  output logic        o_riscv_datapath_hzrdu_globstall,
  /************************* Traps Signals *************************/
  input  logic        i_riscv_core_timer_interrupt    ,
  input  logic        i_riscv_core_external_interrupt ,
  input  logic [63:0] i_riscv_timer_datapath_rdata    ,
  input  logic [63:0] i_riscv_timer_datapath_time     ,
  output logic        o_riscv_datapath_timer_wren     ,
  output logic        o_riscv_datapath_timer_rden     ,
  output logic [ 1:0] o_riscv_datapath_timer_regsel   ,
  /************************* Peripherals Signals *************************/
  input  logic        i_riscv_datapath_fifo_full      ,
  input  logic [ 7:0] i_riscv_datapath_switches_upper ,
  input  logic [ 7:0] i_riscv_datapath_switches_lower ,
  input  logic        i_riscv_datapath_button1        ,
  input  logic        i_riscv_datapath_button2        ,
  input  logic        i_riscv_datapath_button3        ,
  output logic        o_riscv_datapath_uart_tx_valid  ,
  output logic        o_riscv_datapath_seg_en         ,
  output logic        o_riscv_datapath_led_en
);

  /************************* Fetch Stage Signals *************************/
  logic [63:0] riscv_aluexe_fe;
  logic [63:0] riscv_pcplus4_f;
  logic [31:0] riscv_inst_f   ;

  /************************* Control Unit Signals *************************/
  logic       riscv_datapath_cu_jump     ;
  logic       riscv_datapath_cu_regw     ;
  logic [2:0] riscv_datapath_cu_immsrc   ;
  logic       riscv_cu_illegal_inst      ;
  logic [2:0] riscv_datapath_cu_csrop    ;
  logic       riscv_datapath_cu_iscsr    ;
  logic       riscv_datapath_cu_ecall_u  ;
  logic       riscv_datapath_cu_ecall_s  ;
  logic       riscv_datapath_cu_ecall_m  ;
  logic       riscv_datapath_cu_immreg   ;
  logic       riscv_datapath_cu_instret  ;
  logic [1:0] riscv_datapath_cu_lr       ;
  logic [1:0] riscv_datapath_cu_sc       ;
  logic [4:0] riscv_datapath_cu_amo_op   ;
  logic       riscv_datapath_cu_amo      ;
  logic       riscv_datapath_cu_asel     ;
  logic       riscv_datapath_cu_bsel     ;
  logic       riscv_datapath_cu_memw     ;
  logic       riscv_datapath_cu_memr     ;
  logic [1:0] riscv_datapath_cu_storesrc ;
  logic [2:0] riscv_datapath_cu_resultsrc;
  logic [3:0] riscv_datapath_cu_bcond    ;
  logic [2:0] riscv_datapath_cu_memext   ;
  logic [5:0] riscv_datapath_cu_aluctrl  ;
  logic [3:0] riscv_datapath_cu_mulctrl  ;
  logic [3:0] riscv_datapath_cu_divctrl  ;
  logic [1:0] riscv_datapath_cu_funcsel  ;

  /************************* Decode Stage Signals *************************/
  logic [31:0] riscv_inst_d             ;
  logic [ 4:0] riscv_rdaddr_d           ;
  logic [ 4:0] riscv_rdaddr_wb          ;
  logic [63:0] riscv_rddata_wb          ;
  logic        riscv_regw_wb            ;
  logic [63:0] riscv_rs1data_d          ;
  logic [63:0] riscv_rs2data_d          ;
  logic [63:0] riscv_simm_d             ;
  logic [63:0] riscv_pcplus4_d          ;
  logic [63:0] riscv_pc_d               ;
  logic [ 4:0] riscv_rs1addr_d          ;
  logic [ 4:0] riscv_rs2addr_d          ;
  logic [ 6:0] riscv_datapath_opcode_d  ;
  logic [ 2:0] riscv_datapath_func3     ;
  logic [ 6:0] riscv_datapath_func7     ;
  logic [ 4:0] riscv_datapath_fd_cu_rs1 ;
  logic [11:0] riscv_datapath_constimm12;

  /************************* Execute Stage Signals *************************/
  logic [ 6:0] riscv_opcode_e     ;
  logic [63:0] riscv_pc_e         ;
  logic [63:0] riscv_pcplus4_e    ;
  logic [63:0] riscv_rs1data_e    ;
  logic [63:0] riscv_rs2data_e    ;
  logic [63:0] riscv_store_data   ;
  logic [ 4:0] riscv_rdaddr_e     ;
  logic [63:0] riscv_extendedimm_e;
  logic [ 3:0] riscv_b_condition_e;
  logic        riscv_oprnd2sel_e  ;
  logic [ 1:0] riscv_storesrc_e   ;
  logic [ 5:0] riscv_alucontrol_e ;
  logic [ 3:0] riscv_mulctrl_e    ;
  logic [ 3:0] riscv_divctrl_e    ;
  logic [ 1:0] riscv_funcsel_e    ;
  logic        riscv_oprnd1sel_e  ;
  logic [ 2:0] riscv_memext_e     ;
  logic [ 2:0] riscv_resultsrc_e  ;
  logic        riscv_regwrite_e   ;
  logic        riscv_jump_e       ;
  logic        riscv_branchtaken  ;
  logic        riscv_instret_e    ;
  logic [ 1:0] riscv_lr_e         ;
  logic [ 1:0] riscv_sc_e         ;
  logic [ 4:0] riscv_amo_op_e     ;
  logic        riscv_amo_e        ;
  logic [63:0] riscv_rddata_sc_e  ;

  /************************* Memory Stage Signals *************************/
  logic [63:0] riscv_pc_m                  ;
  logic [63:0] riscv_pcplus4_m             ;
  logic [63:0] riscv_rddata_me             ;
  logic        riscv_regw_m                ;
  logic [ 2:0] riscv_resultsrc_m           ;
  logic [ 2:0] riscv_memext_m              ;
  logic [ 4:0] riscv_rdaddr_m              ;
  logic [63:0] riscv_imm_m                 ;
  logic [63:0] riscv_memload_m             ;
  logic        riscv_instret_m             ;
  logic [ 4:0] riscv_amo_op_m              ;
  logic [63:0] riscv_rddata_sc_m           ;
  logic        datapath_memw_e             ;
  logic        datapath_memr_e             ;
  logic [63:0] riscv_datapath_memodata_addr;
  logic        riscv_em_uart_tx_valid      ;
  logic        riscv_em_timer_wren         ;
  logic        riscv_em_timer_rden         ;
  logic [ 1:0] riscv_em_timer_regsel       ;

  /************************* WB Stage Signals *************************/
  logic [63:0] riscv_pc_wb       ;
  logic [63:0] riscv_pcplus4_wb  ;
  logic [63:0] riscv_result_wb   ;
  logic [63:0] riscv_uimm_wb     ;
  logic [63:0] riscv_memload_wb  ;
  logic [63:0] riscv_rddata_sc_wb;
  logic [ 2:0] riscv_resultsrc_wb;
  logic        riscv_instret_wb  ;

  /************************* Tracer Signals *************************/

  logic [31:0] riscv_inst_wb   ;
  logic [15:0] riscv_cinst_wb  ;
  logic [63:0] riscv_memaddr_wb;
  logic [63:0] riscv_rs2data_wb;
  logic [31:0] riscv_inst_e    ;
  logic [15:0] riscv_cinst_e   ;
  logic [31:0] riscv_inst_m    ;
  logic [15:0] riscv_cinst_d   ;
  logic [15:0] riscv_cinst_m   ;

  /************************* Hazard Unit Signals *************************/
  logic [4:0] riscv_datapath_hzrdu_rs1addr  ;
  logic [4:0] riscv_datapath_hzrdu_rs2addr  ;
  logic       riscv_datapath_hzrdu_pcsrc_e  ;
  logic       riscv_datapath_icu_valid      ;
  logic [1:0] riscv_datapath_fwda           ;
  logic [1:0] riscv_datapath_fwdb           ;
  logic [6:0] riscv_datapath_hzrdu_opcode   ;
  logic       riscv_datapath_hzrdu_div_en_e ;
  logic       riscv_datapath_hzrdu_mul_en_e ;
  logic       riscv_datapath_hzrdu_stall_pc ;
  logic       riscv_datapath_hzrdu_flush_fd ;
  logic       riscv_datapath_hzrdu_stall_fd ;
  logic       riscv_datapath_hzrdu_flush_de ;
  logic       riscv_datapath_hzrdu_stall_de ;
  logic       riscv_datapath_hzrdu_stall_em ;
  logic       riscv_datapath_hzrdu_stall_mw ;
  logic       riscv_datapath_hzrd_iscsr_d   ;
  logic       riscv_datapath_hzrd_iscsr_e   ;
  logic       riscv_datapath_hzrd_iscsr_m   ;
  logic       riscv_datapath_hzrd_iscsr_w   ;
  logic [4:0] riscv_datapath_hzrdu_rs1addr_m;
  logic       riscv_datapath_hzrd_muxcsr_sel;

  /************************* Trap & CSR Signals *************************/
  logic             riscv_reg_flush                        ;
  logic             gototrap_mw_trap                       ;
  logic [      1:0] returnfromtrap_mw_trap                 ;
  logic             iscsr_mw_trap                          ;
  logic [     63:0] csrout_mw_trap                         ;
  logic [      1:0] pcsel_trap_fetchpc                     ;
  logic             gototrap_csr_mw                        ;
  logic [      1:0] returnfromtrap_csr_mw                  ;
  logic             iscsr_csr_mw                           ;
  logic [MXLEN-1:0] csrout_csr_mw                          ;
  logic [MXLEN-1:0] mtvec_csr_pctrap                       ;
  logic [MXLEN-1:0] mepc_csr_pctrap                        ;
  logic             ecallu_de_em                           ;
  logic             ecalls_de_em                           ;
  logic             ecallm_de_em                           ;
  logic             illegal_inst_de_em                     ;
  logic             iscsr_de_em                            ;
  logic [      2:0] csrop_de_em                            ;
  logic [      2:0] csrop_de_em_illegal                    ;
  logic [     11:0] csraddress_de_em                       ;
  logic             m_em_csr                               ;
  logic [     11:0] csraddress_em_csr                      ;
  logic             illegal_inst_em_csr                    ;
  logic [      2:0] csrop_em_csr                           ;
  logic [     63:0] csrwdata_em_csr                        ;
  logic [     63:0] immzeroextend_dstage_de                ;
  logic [     63:0] immzeroextend_de_estage                ;
  logic             immreg_de_estage                       ;
  logic             inst_addr_misaligned_em_csr            ;
  logic [     63:0] csrwritedata_estage_em                 ;
  logic             inst_addr_misaligned_estage_em         ;
  logic             riscv_cillegal_inst_d                  ;
  logic [     63:0] muxout_csr                             ;
  logic             csr_is_compressed_flag                 ;
  logic [     63:0] riscv_csr_sepc                         ;
  logic [      1:0] riscv_datapath_privlvl                 ;
  logic             riscv_datapath_tsr                     ;
  logic             load_addr_misaligned_em_csr            ;
  logic             store_addr_misaligned_em_csr           ;
  logic             load_addr_misaligned_estage_em   = 1'b0;
  logic             store_addr_misaligned_estage_em  = 1'b0;
  logic             riscv_datapath_uart_tx_valid           ;
  logic [      2:0] riscv_datapath_mstage_mux_sel          ;
  logic [      2:0] riscv_datapath_em_mstage_mux_sel       ;
  logic             riscv_datapath_em_seg_en               ;
  logic             riscv_datapath_em_led_en               ;


  ////////////////////////////////////////////////////////////////////////////////////

  assign o_riscv_datapath_uart_tx_valid = riscv_datapath_uart_tx_valid && !o_riscv_datapath_hzrdu_globstall;

  assign riscv_datapath_hzrdu_pcsrc_e = riscv_jump_e | riscv_branchtaken;
  assign o_riscv_datapath_rdaddr_m    = riscv_rdaddr_m          ;  // to hazard unit

  assign o_riscv_datapath_amo    = riscv_amo_e ;
  assign o_riscv_datapath_amo_op = riscv_amo_op_m ;

  assign csrop_de_em_illegal    = (gototrap_csr_mw || returnfromtrap_csr_mw)? 3'b000:csrop_de_em;
  assign csr_is_compressed_flag = ~&(riscv_cinst_m[1:0]);

  assign riscv_rstctrl_f = riscv_datapath_hzrdu_flush_fd | i_riscv_datapath_rst | riscv_reg_flush;
  assign riscv_rstctrl_d = riscv_datapath_hzrdu_flush_de | i_riscv_datapath_rst | riscv_reg_flush | gototrap_csr_mw | returnfromtrap_csr_mw;

  assign riscv_datapath_hzrd_iscsr_w = iscsr_mw_trap                 ;
  assign riscv_datapath_hzrd_iscsr_m = iscsr_csr_mw                  ;
  assign riscv_datapath_hzrd_iscsr_e = iscsr_de_em                   ;
  assign riscv_datapath_hzrd_iscsr_d = riscv_datapath_cu_iscsr       ;
  assign illegal_inst_d              = riscv_cu_illegal_inst | riscv_cillegal_inst_d ;

  /************************* ************** *************************/
  /************************* Instantiations *************************/
  /************************* ************** *************************/

  riscv_cu u_top_cu (
    /************************* DP -> CU Signals *************************/
    .i_riscv_cu_opcode    (riscv_datapath_opcode_d    ),
    .i_riscv_cu_funct3    (riscv_datapath_func3       ),
    .i_riscv_cu_funct7    (riscv_datapath_func7       ),
    .i_riscv_cu_privlvl   (riscv_datapath_privlvl     ),
    .i_riscv_cu_rs1       (riscv_datapath_fd_cu_rs1   ),
    .i_riscv_cu_constimm12(riscv_datapath_constimm12  ),
    .i_riscv_cu_tsr       (riscv_datapath_tsr         ),
    /************************* CU -> DP Signals *************************/
    .o_riscv_cu_jump      (riscv_datapath_cu_jump     ),
    .o_riscv_cu_regw      (riscv_datapath_cu_regw     ),
    .o_riscv_cu_asel      (riscv_datapath_cu_asel     ),
    .o_riscv_cu_bsel      (riscv_datapath_cu_bsel     ),
    .o_riscv_cu_memw      (riscv_datapath_cu_memw     ),
    .o_riscv_cu_memr      (riscv_datapath_cu_memr     ),
    .o_riscv_cu_storesrc  (riscv_datapath_cu_storesrc ),
    .o_riscv_cu_resultsrc (riscv_datapath_cu_resultsrc),
    .o_riscv_cu_bcond     (riscv_datapath_cu_bcond    ),
    .o_riscv_cu_memext    (riscv_datapath_cu_memext   ),
    .o_riscv_cu_immsrc    (riscv_datapath_cu_immsrc   ),
    .o_riscv_cu_aluctrl   (riscv_datapath_cu_aluctrl  ),
    .o_riscv_cu_funcsel   (riscv_datapath_cu_funcsel  ),
    .o_riscv_cu_mulctrl   (riscv_datapath_cu_mulctrl  ),
    .o_riscv_cu_divctrl   (riscv_datapath_cu_divctrl  ),
    .o_riscv_cu_csrop     (riscv_datapath_cu_csrop    ),
    .o_riscv_cu_sel_rs_imm(riscv_datapath_cu_immreg   ),
    .o_riscv_cu_illgalinst(riscv_cu_illegal_inst      ),
    .o_riscv_cu_iscsr     (riscv_datapath_cu_iscsr    ),
    .o_riscv_cu_ecall_u   (riscv_datapath_cu_ecall_u  ),
    .o_riscv_cu_ecall_s   (riscv_datapath_cu_ecall_s  ),
    .o_riscv_cu_ecall_m   (riscv_datapath_cu_ecall_m  ),
    .o_riscv_cu_instret   (riscv_datapath_cu_instret  ),
    .o_riscv_cu_lr        (riscv_datapath_cu_lr       ),
    .o_riscv_cu_sc        (riscv_datapath_cu_sc       ),
    .o_riscv_cu_amo_op    (riscv_datapath_cu_amo_op   ),
    .o_riscv_cu_amo       (riscv_datapath_cu_amo      )
  );

  riscv_fstage u_riscv_fstage (
    .i_riscv_fstage_clk          (i_riscv_datapath_clk         ),
    .i_riscv_fstage_rst          (i_riscv_datapath_rst         ),
    .i_riscv_fstage_stallpc      (riscv_datapath_hzrdu_stall_pc),
    .i_riscv_fstage_aluexe       (riscv_aluexe_fe              ),
    .i_riscv_fstage_inst         (i_riscv_datapath_inst        ),
    .i_riscv_fstage_pcsrc        (riscv_datapath_hzrdu_pcsrc_e ),
    .i_riscv_fstage_pcsel        (pcsel_trap_fetchpc           ),
    .i_riscv_fstage_mtvec        (mtvec_csr_pctrap             ),
    .i_riscv_fstage_mepc         (mepc_csr_pctrap              ),
    .i_riscv_fstage_sepc         (riscv_csr_sepc               ),
    .o_riscv_fstage_pc           (o_riscv_datapath_pc          ),
    .o_riscv_fstage_pcplus4      (riscv_pcplus4_f              ),
    .o_riscv_fstage_inst         (riscv_inst_f                 ),
    .o_riscv_fstage_cillegal_inst(riscv_cillegal_inst          )
  );

  riscv_ppreg_fd u_riscv_fd_ppreg (
    .i_riscv_fd_clk            (i_riscv_datapath_clk         ),
    .i_riscv_fd_rst            (i_riscv_datapath_rst         ),
    .i_riscv_fd_flush          (riscv_rstctrl_f              ),
    .i_riscv_fd_en             (riscv_datapath_hzrdu_stall_fd),
    .i_riscv_fd_pc_f           (o_riscv_datapath_pc          ),
    .i_riscv_fd_inst_f         (riscv_inst_f                 ),
    .i_riscv_fd_pcplus4_f      (riscv_pcplus4_f              ),
    .i_riscv_fd_cillegal_inst_f(riscv_cillegal_inst          ),
    .i_riscv_fd_cinst_f        (i_riscv_datapath_inst[15:0]  ),
    .o_riscv_fd_cinst_d        (riscv_cinst_d                ),
    .o_riscv_fd_pc_d           (riscv_pc_d                   ),
    .o_riscv_fd_inst_d         (riscv_inst_d                 ),
    .o_riscv_fd_pcplus4_d      (riscv_pcplus4_d              ),
    .o_riscv_fd_rs1_d          (riscv_datapath_fd_cu_rs1     ),
    .o_riscv_fd_cillegal_inst_d(riscv_cillegal_inst_d        ),
    .o_riscv_fd_constimm12_d   (riscv_datapath_constimm12    )
  );

  riscv_dstage u_riscv_dstage (
    .i_riscv_dstage_clk_n        (i_riscv_datapath_clk    ),
    .i_riscv_dstage_regw         (riscv_regw_wb           ),
    .i_riscv_dstage_immsrc       (riscv_datapath_cu_immsrc),
    .i_riscv_dstage_inst         (riscv_inst_d            ),
    .i_riscv_dstage_rdaddr       (riscv_rdaddr_wb         ),
    .i_riscv_dstage_rddata       (riscv_rddata_wb         ),
    .o_riscv_dstage_rs1addr      (riscv_rs1addr_d         ),
    .o_riscv_dstage_rs2addr      (riscv_rs2addr_d         ),
    .o_riscv_dstage_rs1data      (riscv_rs1data_d         ),
    .o_riscv_dstage_rs2data      (riscv_rs2data_d         ),
    .o_riscv_dstage_rdaddr       (riscv_rdaddr_d          ),
    .o_riscv_dstage_simm         (riscv_simm_d            ),
    .o_riscv_dstage_opcode       (riscv_datapath_opcode_d ),
    .o_riscv_dstage_funct3       (riscv_datapath_func3    ),
    .o_riscv_dstage_func7        (riscv_datapath_func7    ),
    .o_riscv_dstage_immzeroextend(immzeroextend_dstage_de )
  );

  riscv_ppreg_de u_riscv_de_ppreg (
    .i_riscv_de_en             (riscv_datapath_hzrdu_stall_de),
    .i_riscv_de_clk            (i_riscv_datapath_clk         ),
    .i_riscv_de_rst            (i_riscv_datapath_rst         ),
    .i_riscv_de_flush          (riscv_rstctrl_d              ),
    .i_riscv_de_pc_d           (riscv_pc_d                   ),
    .i_riscv_de_rs1addr_d      (riscv_rs1addr_d              ),
    .i_riscv_de_rs1data_d      (riscv_rs1data_d              ),
    .i_riscv_de_rs2data_d      (riscv_rs2data_d              ),
    .i_riscv_de_rs2addr_d      (riscv_rs2addr_d              ),
    .i_riscv_de_rdaddr_d       (riscv_rdaddr_d               ),
    .i_riscv_de_extendedimm_d  (riscv_simm_d                 ),
    .i_riscv_de_b_condition_d  (riscv_datapath_cu_bcond      ),
    .i_riscv_de_oprnd2sel_d    (riscv_datapath_cu_bsel       ),
    .i_riscv_de_storesrc_d     (riscv_datapath_cu_storesrc   ),
    .i_riscv_de_alucontrol_d   (riscv_datapath_cu_aluctrl    ),
    .i_riscv_de_mulctrl_d      (riscv_datapath_cu_mulctrl    ),
    .i_riscv_de_divctrl_d      (riscv_datapath_cu_divctrl    ),
    .i_riscv_de_funcsel_d      (riscv_datapath_cu_funcsel    ),
    .i_riscv_de_oprnd1sel_d    (riscv_datapath_cu_asel       ),
    .i_riscv_de_memwrite_d     (riscv_datapath_cu_memw       ),
    .i_riscv_de_memread_d      (riscv_datapath_cu_memr       ),
    .i_riscv_de_memext_d       (riscv_datapath_cu_memext     ),
    .i_riscv_de_resultsrc_d    (riscv_datapath_cu_resultsrc  ),
    .i_riscv_de_regwrite_d     (riscv_datapath_cu_regw       ),
    .i_riscv_de_jump_d         (riscv_datapath_cu_jump       ),
    .i_riscv_de_pcplus4_d      (riscv_pcplus4_d              ),
    .i_riscv_de_opcode_d       (riscv_datapath_opcode_d      ),
    .i_riscv_de_ecall_m_d      (riscv_datapath_cu_ecall_m    ),
    .i_riscv_de_ecall_u_d      (riscv_datapath_cu_ecall_u    ), //>>
    .i_riscv_de_ecall_s_d      (riscv_datapath_cu_ecall_s    ), //<<
    .i_riscv_de_csraddress_d   (riscv_inst_d[31:20]          ),
    .i_riscv_de_illegal_inst_d (illegal_inst_d               ),
    .i_riscv_de_iscsr_d        (riscv_datapath_cu_iscsr      ),
    .i_riscv_de_csrop_d        (riscv_datapath_cu_csrop      ),
    .i_riscv_de_immreg_d       (riscv_datapath_cu_immreg     ),
    .i_riscv_de_immzeroextend_d(immzeroextend_dstage_de      ),
    .i_riscv_de_instret_d      (riscv_datapath_cu_instret    ),
    .i_riscv_de_lr_d           (riscv_datapath_cu_lr         ),
    .i_riscv_de_sc_d           (riscv_datapath_cu_sc         ),
    .i_riscv_de_amo_op_d       (riscv_datapath_cu_amo_op     ),
    .i_riscv_de_amo_d          (riscv_datapath_cu_amo        ),
    .i_riscv_de_inst           (riscv_inst_d                 ),
    .i_riscv_de_cinst          (riscv_cinst_d                ),
    
    .o_riscv_de_inst           (riscv_inst_e                 ),
    .o_riscv_de_cinst          (riscv_cinst_e                ),
    .o_riscv_de_lr_e           (riscv_lr_e                   ),
    .o_riscv_de_sc_e           (riscv_sc_e                   ),
    .o_riscv_de_amo_op_e       (riscv_amo_op_e               ),
    .o_riscv_de_amo_e          (riscv_amo_e                  ),
    .o_riscv_de_instret_e      (riscv_instret_e              ),
    .o_riscv_de_ecall_m_e      (ecallm_de_em                 ),
    .o_riscv_de_ecall_s_e      (ecalls_de_em                 ), // >>
    .o_riscv_de_ecall_u_e      (ecallu_de_em                 ), //>>
    
    .o_riscv_de_csraddress_e   (csraddress_de_em             ),
    .o_riscv_de_illegal_inst_e (illegal_inst_de_em           ),
    .o_riscv_de_iscsr_e        (iscsr_de_em                  ),
    .o_riscv_de_csrop_e        (csrop_de_em                  ),
    .o_riscv_de_immreg_e       (immreg_de_estage             ),
    .o_riscv_de_immzeroextend_e(immzeroextend_de_estage      ),
    .o_riscv_de_pc_e           (riscv_pc_e                   ),
    .o_riscv_de_pcplus4_e      (riscv_pcplus4_e              ),
    .o_riscv_de_rs1addr_e      (riscv_datapath_hzrdu_rs1addr ),
    .o_riscv_de_rs1data_e      (riscv_rs1data_e              ),
    .o_riscv_de_rs2data_e      (riscv_rs2data_e              ),
    .o_riscv_de_rs2addr_e      (riscv_datapath_hzrdu_rs2addr ),
    .o_riscv_de_rdaddr_e       (riscv_rdaddr_e               ),
    .o_riscv_de_extendedimm_e  (riscv_extendedimm_e          ),
    .o_riscv_de_b_condition_e  (riscv_b_condition_e          ),
    .o_riscv_de_oprnd2sel_e    (riscv_oprnd2sel_e            ),
    .o_riscv_de_storesrc_e     (riscv_storesrc_e             ),
    .o_riscv_de_alucontrol_e   (riscv_alucontrol_e           ),
    .o_riscv_de_mulctrl_e      (riscv_mulctrl_e              ),
    .o_riscv_de_divctrl_e      (riscv_divctrl_e              ),
    .o_riscv_de_funcsel_e      (riscv_funcsel_e              ),
    .o_riscv_de_oprnd1sel_e    (riscv_oprnd1sel_e            ),
    .o_riscv_de_memwrite_e     (datapath_memw_e              ),
    .o_riscv_de_memread_e      (datapath_memr_e              ),
    .o_riscv_de_memext_e       (riscv_memext_e               ),
    .o_riscv_de_resultsrc_e    (riscv_resultsrc_e            ),
    .o_riscv_de_regwrite_e     (riscv_regwrite_e             ),
    .o_riscv_de_jump_e         (riscv_jump_e                 ),
    .o_riscv_de_opcode_e       (riscv_opcode_e               )
  );

  riscv_estage u_riscv_estage (
    .i_riscv_estage_clk                  (i_riscv_datapath_clk            ),
    .i_riscv_estage_rst                  (i_riscv_datapath_rst            ),
    .i_riscv_estage_globstall            (o_riscv_datapath_hzrdu_globstall),
    .i_riscv_estage_rs1data              (riscv_rs1data_e                 ),
    .i_riscv_estage_rs2data              (riscv_rs2data_e                 ),
    .i_riscv_estage_fwda                 (riscv_datapath_fwda             ),
    .i_riscv_estage_fwdb                 (riscv_datapath_fwdb             ),
    .i_riscv_estage_rdata_wb             (riscv_rddata_wb                 ),
    .i_riscv_estage_rddata_m             (riscv_rddata_me                 ),
    .i_riscv_estage_imm_m                (riscv_imm_m                     ),
    .i_riscv_estage_oprnd1sel            (riscv_oprnd1sel_e               ),
    .i_riscv_estage_oprnd2sel            (riscv_oprnd2sel_e               ),
    .i_riscv_estage_pc                   (riscv_pc_e                      ),
    .i_riscv_estage_aluctrl              (riscv_alucontrol_e              ),
    .i_riscv_estage_mulctrl              (riscv_mulctrl_e                 ),
    .i_riscv_estage_divctrl              (riscv_divctrl_e                 ),
    .i_riscv_estage_funcsel              (riscv_funcsel_e                 ),
    .i_riscv_estage_simm                 (riscv_extendedimm_e             ),
    .i_riscv_estage_bcond                (riscv_b_condition_e             ),
    .i_riscv_estage_opcode               (riscv_opcode_e                  ),
    .i_riscv_estage_memext               (riscv_memext_e                  ),
    .i_riscv_estage_storesrc             (riscv_storesrc_e                ),
    .i_riscv_estage_imm_reg              (immreg_de_estage                ),
    .i_riscv_estage_immextended          (immzeroextend_de_estage         ),
    .i_riscv_estage_lr                   (riscv_lr_e                      ),
    .i_riscv_estage_sc                   (riscv_sc_e                      ),
    .i_riscv_estage_amo                  (riscv_amo_e                     ),
    .i_riscv_estage_memw                 (datapath_memw_e                 ),
    .i_riscv_estage_memr                 (datapath_memr_e                 ),
    .i_riscv_estage_gtrap                (gototrap_csr_mw                 ),
    .i_riscv_estage_rtrap                (returnfromtrap_csr_mw           ),
    .o_riscv_estage_dcache_wren          (o_riscv_datapath_memw_e         ),
    .o_riscv_estage_dcache_rden          (o_riscv_datapath_memr_e         ),
    .o_riscv_estage_dcache_addr          (riscv_datapath_memodata_addr    ),
    .o_riscv_estage_rddata_sc            (riscv_rddata_sc_e               ),
    .o_riscv_estage_result               (riscv_aluexe_fe                 ),
    .o_riscv_estage_store_data           (riscv_store_data                ),
    .o_riscv_estage_branchtaken          (riscv_branchtaken               ),
    .o_riscv_estage_icu_valid            (riscv_datapath_icu_valid        ),
    .o_riscv_estage_mul_en               (riscv_datapath_hzrdu_mul_en_e   ),
    .o_riscv_estage_div_en               (riscv_datapath_hzrdu_div_en_e   ),
    .o_riscv_estage_csrwritedata         (csrwritedata_estage_em          ),
    .o_riscv_estage_inst_addr_misaligned (inst_addr_misaligned_estage_em  ),
    .o_riscv_estage_store_addr_misaligned(                                ),
    .o_riscv_estage_load_addr_misaligned (                                ),
    .o_riscv_estage_uart_tx_valid        (riscv_em_uart_tx_valid          ),
    .o_riscv_estage_timer_wren           (riscv_em_timer_wren             ),
    .o_riscv_estage_timer_rden           (riscv_em_timer_rden             ),
    .o_riscv_estage_timer_regsel         (riscv_em_timer_regsel           ),
    .o_riscv_estage_seg_en               (riscv_datapath_em_seg_en        ),
    .o_riscv_estage_led_en               (riscv_datapath_em_led_en        ),
    .o_riscv_estage_mstage_mux_sel       (riscv_datapath_mstage_mux_sel   )
  );


  riscv_ppreg_em u_riscv_em_ppreg (
    .i_riscv_em_pc                     (riscv_pc_e                      ),
    .i_riscv_em_en                     (riscv_datapath_hzrdu_stall_em   ),
    .i_riscv_em_clk                    (i_riscv_datapath_clk            ),
    .i_riscv_em_rst                    (i_riscv_datapath_rst            ),
    .i_riscv_em_regw_e                 (riscv_regwrite_e                ),
    .i_riscv_em_resultsrc_e            (riscv_resultsrc_e               ),
    .i_riscv_em_storesrc_e             (riscv_storesrc_e                ),
    .i_riscv_em_memext_e               (riscv_memext_e                  ),
    .i_riscv_em_pcplus4_e              (riscv_pcplus4_e                 ),
    .i_riscv_em_result_e               (riscv_aluexe_fe                 ),
    .i_riscv_em_storedata_e            (riscv_store_data                ),
    .i_riscv_em_dcache_addr            (riscv_datapath_memodata_addr    ),
    .i_riscv_em_rdaddr_e               (riscv_rdaddr_e                  ),
    .i_riscv_em_imm_e                  (riscv_extendedimm_e             ),
    .i_riscv_em_opcode_e               (riscv_opcode_e                  ),
    .i_riscv_em_flush                  (riscv_reg_flush                 ),
    .i_riscv_em_ecall_m_e              (ecallm_de_em                    ),
    .i_riscv_em_ecall_s_e              (ecalls_de_em                    ), //>>
    .i_riscv_em_ecall_u_e              (ecallu_de_em                    ), //>>
    .i_riscv_em_csraddress_e           (csraddress_de_em                ),
    .i_riscv_em_illegal_inst_e         (illegal_inst_de_em              ),
    .i_riscv_em_iscsr_e                (iscsr_de_em                     ),
    .i_riscv_em_csrop_e                (csrop_de_em_illegal             ),
    .i_riscv_em_inst_addr_misaligned_e (inst_addr_misaligned_estage_em  ),
    .i_riscv_em_load_addr_misaligned_e (load_addr_misaligned_estage_em  ),
    .i_riscv_em_store_addr_misaligned_e(store_addr_misaligned_estage_em ),
    .i_riscv_em_csrwritedata_e         (csrwritedata_estage_em          ),
    .i_riscv_em_rs1addr_e              (riscv_datapath_hzrdu_rs1addr    ),
    .i_riscv_em_instret_e              (riscv_instret_e                 ),
    .i_riscv_em_rddata_sc_e            (riscv_rddata_sc_e               ),
    .i_riscv_em_amo_op_e               (riscv_amo_op_e                  ),
    .i_riscv_em_inst                   (riscv_inst_e                    ),
    .i_riscv_em_cinst                  (riscv_cinst_e                   ),
    .i_riscv_em_timer_wren             (riscv_em_timer_wren             ),
    .i_riscv_em_timer_rden             (riscv_em_timer_rden             ),
    .i_riscv_em_timer_regsel           (riscv_em_timer_regsel           ),
    .i_riscv_em_uart_tx_valid          (riscv_em_uart_tx_valid          ),
    .i_riscv_em_mstage_mux_sel         (riscv_datapath_mstage_mux_sel   ),
    .i_riscv_em_seg_en                 (riscv_datapath_em_seg_en        ),
    .i_riscv_em_led_en                 (riscv_datapath_em_led_en        ),
    .o_riscv_em_mstage_mux_sel         (riscv_datapath_em_mstage_mux_sel),
    .o_riscv_em_inst                   (riscv_inst_m                    ),
    .o_riscv_em_cinst                  (riscv_cinst_m                   ),
    .o_riscv_em_amo_op_m               (riscv_amo_op_m                  ),
    .o_riscv_em_rddata_sc_m            (riscv_rddata_sc_m               ),
    .o_riscv_em_pc                     (riscv_pc_m                      ),
    .o_riscv_em_instret_m              (riscv_instret_m                 ),
    .o_riscv_em_rs1addr_m              (riscv_datapath_hzrdu_rs1addr_m  ),
    .o_riscv_em_ecall_m_m              (m_em_csr                        ),
    .o_riscv_em_ecall_s_m              (s_em_csr                        ),
    .o_riscv_em_ecall_u_m              (u_em_csr                        ),
    .o_riscv_em_csraddress_m           (csraddress_em_csr               ),
    .o_riscv_em_illegal_inst_m         (illegal_inst_em_csr             ),
    .o_riscv_em_iscsr_m                (iscsr_csr_mw                    ),
    .o_riscv_em_csrop_m                (csrop_em_csr                    ),
    .o_riscv_em_inst_addr_misaligned_m (inst_addr_misaligned_em_csr     ),
    .o_riscv_em_load_addr_misaligned_m (load_addr_misaligned_em_csr     ),
    .o_riscv_em_store_addr_misaligned_m(store_addr_misaligned_em_csr    ),
    .o_riscv_em_csrwritedata_m         (csrwdata_em_csr                 ),
    .o_riscv_em_regw_m                 (riscv_regw_m                    ),
    .o_riscv_em_dcache_addr            (o_riscv_datapath_memodata_addr  ),
    .o_riscv_em_resultsrc_m            (riscv_resultsrc_m               ),
    .o_riscv_em_storesrc_m             (o_riscv_datapath_storesrc_m     ),
    .o_riscv_em_memext_m               (riscv_memext_m                  ),
    .o_riscv_em_pcplus4_m              (riscv_pcplus4_m                 ),
    .o_riscv_em_result_m               (riscv_rddata_me                 ),
    .o_riscv_em_storedata_m            (o_riscv_datapath_storedata_m    ),
    .o_riscv_em_rdaddr_m               (riscv_rdaddr_m                  ),
    .o_riscv_em_imm_m                  (riscv_imm_m                     ),
    .o_riscv_em_opcode_m               (riscv_datapath_hzrdu_opcode     ),
    .o_riscv_em_timer_wren             (o_riscv_datapath_timer_wren     ),
    .o_riscv_em_timer_rden             (o_riscv_datapath_timer_rden     ),
    .o_riscv_em_uart_tx_valid          (riscv_datapath_uart_tx_valid    ),
    .o_riscv_em_timer_regsel           (o_riscv_datapath_timer_regsel   ),
    .o_riscv_em_seg_en                 (o_riscv_datapath_seg_en         ),
    .o_riscv_em_led_en                 (o_riscv_datapath_led_en         )
  );

  riscv_mstage u_riscv_mstage (
    .i_riscv_mstage_dm_rdata      (i_riscv_datapath_dm_rdata       ),
    .i_riscv_mstage_load_mux_sel  (riscv_datapath_em_mstage_mux_sel),
    .i_riscv_mstage_switches_upper(i_riscv_datapath_switches_upper ),
    .i_riscv_mstage_switches_lower(i_riscv_datapath_switches_lower ),
    .i_riscv_mstage_button1       (i_riscv_datapath_button1        ),
    .i_riscv_mstage_button2       (i_riscv_datapath_button2        ),
    .i_riscv_mstage_button3       (i_riscv_datapath_button3        ),
    .i_riscv_mstage_timer_rdata   (i_riscv_timer_datapath_rdata    ),
    .i_riscv_mstage_memext        (riscv_memext_m                  ),
    .i_riscv_mstage_addr          (riscv_rddata_me                 ),
    .i_riscv_mstage_mux2_sel      (riscv_datapath_hzrd_muxcsr_sel  ),
    .i_riscv_mux2_in0             (csrwdata_em_csr                 ),
    .i_riscv_mux2_in1             (csrout_csr_mw                   ),
    .o_riscv_mstage_memload       (riscv_memload_m                 ),
    .o_riscv_mstage_mux2_out      (muxout_csr                      )
  );

  ////memory write back pipeline flip flops ////
  riscv_ppreg_mw u_riscv_mw_ppreg (
    `ifdef TEST
    .i_riscv_mw_pc               (riscv_pc_m                                                ),
    .i_riscv_mw_inst             (riscv_inst_m                                              ),
    .i_riscv_mw_cinst            (riscv_cinst_m                                             ),
    .i_riscv_mw_memaddr          (o_riscv_datapath_memodata_addr                            ),
    .i_riscv_mw_rs2data          (i_riscv_datapath_dm_rdata                                 ),
    .o_riscv_mw_cinst            (riscv_cinst_wb                                            ),
    .o_riscv_mw_memaddr          (riscv_memaddr_wb                                          ),
    .o_riscv_mw_inst             (riscv_inst_wb                                             ),
    .o_riscv_mw_pc               (riscv_pc_wb                                               ),
    .o_riscv_mw_rs2data          (riscv_rs2data_wb                                          ),
    `endif
    .i_riscv_mw_regw_m           (riscv_regw_m && !gototrap_csr_mw && !returnfromtrap_csr_mw),
    .i_riscv_mw_en               (riscv_datapath_hzrdu_stall_mw                             ),
    .i_riscv_mw_clk              (i_riscv_datapath_clk                                      ),
    .i_riscv_mw_rst              (i_riscv_datapath_rst                                      ),
    .i_riscv_mw_pcplus4_m        (riscv_pcplus4_m                                           ),
    .i_riscv_mw_result_m         (riscv_rddata_me                                           ),
    .i_riscv_mw_uimm_m           (riscv_imm_m                                               ),
    .i_riscv_mw_memload_m        (riscv_memload_m                                           ),
    .i_riscv_mw_rdaddr_m         (riscv_rdaddr_m                                            ),
    .i_riscv_mw_resultsrc_m      (riscv_resultsrc_m                                         ),
    .i_riscv_mw_flush            (riscv_reg_flush                                           ),
    .i_riscv_mw_csrout_m         (csrout_mw_trap                                            ),
    .i_riscv_mw_iscsr_m          (iscsr_csr_mw                                              ),
    .i_riscv_mw_returnfromtrap_m (returnfromtrap_csr_mw                                     ),
    .i_riscv_mw_gototrap_m       (gototrap_csr_mw                                           ),
    .i_riscv_mw_instret_m        (riscv_instret_m                                           ),
    .i_riscv_mw_rddata_sc_m      (riscv_rddata_sc_m                                         ),
    .o_riscv_mw_rddata_sc_wb     (riscv_rddata_sc_wb                                        ),
    .o_riscv_mw_instret_wb       (riscv_instret_wb                                          ),
    .o_riscv_mw_pcplus4_wb       (riscv_pcplus4_wb                                          ),
    .o_riscv_mw_result_wb        (riscv_result_wb                                           ),
    .o_riscv_mw_uimm_wb          (riscv_uimm_wb                                             ),
    .o_riscv_mw_memload_wb       (riscv_memload_wb                                          ),
    .o_riscv_mw_rdaddr_wb        (riscv_rdaddr_wb                                           ),
    .o_riscv_mw_resultsrc_wb     (riscv_resultsrc_wb                                        ),
    .o_riscv_mw_regw_wb          (riscv_regw_wb                                             ),
    .o_riscv_mw_csrout_wb        (csrout_csr_mw                                             ),
    .o_riscv_mw_iscsr_wb         (iscsr_mw_trap                                             ),
    .o_riscv_mw_gototrap_wb      (gototrap_mw_trap                                          ),
    .o_riscv_mw_returnfromtrap_wb(returnfromtrap_mw_trap                                    )
  );

  ////////////////////////////////
  riscv_wbstage u_riscv_wbstage (
    .i_riscv_wb_resultsrc     (riscv_resultsrc_wb              ),
    .i_riscv_wb_pcplus4       (riscv_pcplus4_wb                ),
    .i_riscv_wb_result        (riscv_result_wb                 ),
    .i_riscv_wb_memload       (riscv_memload_wb                ),
    .i_riscv_wb_uimm          (riscv_uimm_wb                   ),
    .i_riscv_wb_rddata_sc     (riscv_rddata_sc_wb              ),
    .i_riscv_wb_csrout        (csrout_csr_mw                   ),
    .i_riscv_wb_iscsr         (iscsr_mw_trap                   ),
    .i_riscv_wb_gototrap      (gototrap_mw_trap                ),
    .i_riscv_wb_returnfromtrap(returnfromtrap_mw_trap          ),
    .i_riscv_wb_icache_stall  (i_riscv_datapath_icache_stall_wb),
    .o_riscv_wb_rddata        (riscv_rddata_wb                 ),
    .o_riscv_wb_pcsel         (pcsel_trap_fetchpc              ),
    .o_riscv_wb_flush         (riscv_reg_flush                 )
  );

////////////////////////////////
  riscv_csrfile u_riscv_csrfile (
    .i_riscv_csr_clk                  (i_riscv_datapath_clk            ),
    .i_riscv_csr_rst                  (i_riscv_datapath_rst            ),
    .i_riscv_csr_flush                (riscv_reg_flush                 ),
    .i_riscv_csr_address              (csraddress_em_csr               ),
    .i_riscv_csr_op                   (csrop_em_csr                    ),
    .i_riscv_csr_wdata                (muxout_csr                      ),
    .i_riscv_csr_external_int         (i_riscv_core_external_interrupt ),
    .i_riscv_csr_timer_int            (i_riscv_core_timer_interrupt    ),
    .i_riscv_csr_timer_time           (i_riscv_timer_datapath_time     ),
    .i_riscv_csr_ecall_u              (u_em_csr                        ),
    .i_riscv_csr_ecall_s              (s_em_csr                        ),
    .i_riscv_csr_ecall_m              (m_em_csr                        ),
    .i_riscv_csr_illegal_inst         (illegal_inst_em_csr             ), //illegal_inst_em_csr
    .i_riscv_csr_inst_addr_misaligned (inst_addr_misaligned_em_csr     ),
    .i_riscv_csr_load_addr_misaligned (load_addr_misaligned_em_csr     ),
    .i_riscv_csr_store_addr_misaligned(store_addr_misaligned_em_csr    ),
    .i_riscv_csr_pc                   (riscv_pc_m                      ),
    .i_riscv_csr_instret              (riscv_instret_wb                ),
    .i_riscv_csr_addressALU           (riscv_rddata_me                 ),
    .i_riscv_csr_globstall            (o_riscv_datapath_hzrdu_globstall),
    .i_riscv_csr_inst                 (riscv_inst_m                    ),
    .i_riscv_csr_cinst                (riscv_cinst_m                   ),
    .i_riscv_csr_is_compressed        (csr_is_compressed_flag          ),
    .o_riscv_csr_return_address       (mepc_csr_pctrap                 ),
    .o_riscv_csr_trap_address         (mtvec_csr_pctrap                ),
    .o_riscv_csr_gotoTrap_cs          (gototrap_csr_mw                 ),
    .o_riscv_csr_returnfromTrap       (returnfromtrap_csr_mw           ),
    .o_riscv_csr_rdata                (csrout_mw_trap                  ),
    .o_riscv_csr_privlvl              (riscv_datapath_privlvl          ),
    .o_riscv_csr_tsr                  (riscv_datapath_tsr              ),
    .o_riscv_sepc                     (riscv_csr_sepc                  )
  );

  riscv_hazardunit u_riscv_hazard_unit (
    .i_riscv_hzrdu_rs1addr_d  (riscv_rs1addr_d                 ),
    .i_riscv_hzrdu_rs2addr_d  (riscv_rs2addr_d                 ),
    .i_riscv_hzrdu_rs1addr_e  (riscv_datapath_hzrdu_rs1addr    ),
    .i_riscv_hzrdu_rs2addr_e  (riscv_datapath_hzrdu_rs2addr    ),
    .i_riscv_hzrdu_resultsrc_e(riscv_resultsrc_e               ),
    .i_riscv_hzrdu_rdaddr_e   (riscv_rdaddr_e                  ),
    .i_riscv_hzrdu_valid      (riscv_datapath_icu_valid        ),
    .o_riscv_hzrdu_fwda       (riscv_datapath_fwda             ),
    .o_riscv_hzrdu_fwdb       (riscv_datapath_fwdb             ),
    .i_riscv_hzrdu_rdaddr_m   (riscv_rdaddr_m                  ),
    .i_riscv_hzrdu_regw_m     (riscv_regw_m                    ),
    .i_riscv_dcahe_stall_m    (i_riscv_datapath_stall_dm       ),
    .i_riscv_icahe_stall_m    (i_riscv_datapath_stall_im       ),
    .i_riscv_fifo_full        (i_riscv_datapath_fifo_full      ),
    .i_riscv_hzrdu_pcsrc      (riscv_datapath_hzrdu_pcsrc_e    ),
    .i_riscv_hzrdu_rdaddr_w   (riscv_rdaddr_wb                 ),
    .i_riscv_hzrdu_regw_w     (riscv_regw_wb                   ),
    .i_riscv_hzrdu_opcode_m   (riscv_datapath_hzrdu_opcode     ),
    .i_riscv_hzrdu_mul_en     (riscv_datapath_hzrdu_mul_en_e   ),
    .i_riscv_hzrdu_div_en     (riscv_datapath_hzrdu_div_en_e   ),
    .o_riscv_hzrdu_stallpc    (riscv_datapath_hzrdu_stall_pc   ),
    .o_riscv_hzrdu_stallfd    (riscv_datapath_hzrdu_stall_fd   ),
    .o_riscv_hzrdu_flushfd    (riscv_datapath_hzrdu_flush_fd   ),
    .o_riscv_hzrdu_flushde    (riscv_datapath_hzrdu_flush_de   ),
    .o_riscv_hzrdu_stallmw    (riscv_datapath_hzrdu_stall_mw   ),
    .o_riscv_hzrdu_stallem    (riscv_datapath_hzrdu_stall_em   ),
    .o_riscv_hzrdu_stallde    (riscv_datapath_hzrdu_stall_de   ),
    .o_riscv_hzrdu_globstall  (o_riscv_datapath_hzrdu_globstall),
    .i_riscv_hzrdu_iscsr_e    (riscv_datapath_hzrd_iscsr_e     ),
    .i_riscv_hzrdu_iscsr_d    (riscv_datapath_hzrd_iscsr_d     ),
    .i_riscv_hzrdu_iscsr_w    (riscv_datapath_hzrd_iscsr_w     ),
    .i_riscv_hzrdu_iscsr_m    (riscv_datapath_hzrd_iscsr_m     ),
    .o_riscv_hzrdu_passwb     (riscv_datapath_hzrd_muxcsr_sel  ),
    .i_riscv_hzrdu_rs1addr_m  (riscv_datapath_hzrdu_rs1addr_m  )
  );

  ///tracer instantiation///
  `ifdef TEST
  riscv_tracer u_riscv_tracer (
    .i_riscv_clk        (i_riscv_datapath_clk),
    .i_riscv_rst        (i_riscv_datapath_rst),
    .i_riscv_trc_inst   (riscv_inst_wb       ),
    .i_riscv_trc_cinst  (riscv_cinst_wb      ),
    .i_riscv_trc_rdaddr (riscv_rdaddr_wb     ),
    .i_riscv_trc_memaddr(riscv_memaddr_wb    ),
    .i_riscv_trc_pc     (riscv_pc_wb         ),
    .i_riscv_trc_store  (riscv_rs2data_wb    ),
    .i_riscv_trc_rddata (riscv_rddata_wb     )
  );
  `endif

endmodule
