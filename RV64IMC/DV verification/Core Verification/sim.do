transcript file questa.txt

vlog +define+TEST=1 riscv_alu.sv riscv_branch.sv riscv_compressed_decoder.sv riscv_control_unit.sv riscv_core.sv riscv_csrfile.sv riscv_datapath.sv riscv_dcache_data.sv riscv_dcache_fsm.sv riscv_dcache_tag.sv riscv_dcache_top.sv riscv_decode_stage.sv riscv_divider.sv riscv_dm.sv riscv_exception_unit.sv riscv_execute_stage.sv riscv_extend.sv riscv_fetch_stage.sv riscv_hazardunit.sv riscv_icu.sv riscv_im.sv riscv_memext.sv riscv_mem_stage.sv riscv_multiplier.sv riscv_mux2.sv riscv_mux3.sv riscv_mux4.sv riscv_pc.sv riscv_pcadder.sv riscv_ppreg_de.sv riscv_ppreg_em.sv riscv_ppreg_fd.sv riscv_ppreg_mw.sv riscv_ram_model.sv riscv_rf.sv riscv_top.sv riscv_top_tb.sv riscv_tracer.sv riscv_trap_wb.sv riscv_wb_stage.sv riscv_zeroextend.sv
vsim -gui -voptargs=+acc work.riscv_top_tb -novopt
puts "run -all"
run -all
transcript file ""