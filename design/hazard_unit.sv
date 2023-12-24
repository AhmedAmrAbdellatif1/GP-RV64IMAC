module riscv_hazardunit
//Combitional civuit no clk
//res_Src make 1 bit in document + stall pc make 2bits
 (
   input       [4:0]   i_riscv_hzrdu_rs1addr_d ,
                       i_riscv_hzrdu_rs2addr_d ,
                       i_riscv_hzrdu_rs1addr_e ,
                       i_riscv_hzrdu_rs2addr_e ,
 	                     i_riscv_hzrdu_rdaddr_m  ,
                       i_riscv_hzrdu_rdaddr_w , 
 	  
     input             i_riscv_hzrdu_pcsrc ,
                       i_riscv_hzrdu_regw_m   ,
                       i_riscv_hzrdu_regw_w  ,

    // input op1,op2
   input       [1:0]   i_riscv_hzrdu_resultsrc   ,

   output reg  [1:0]   o_riscv_hzrdu_fw_da  , 
                       o_riscv_hzrdu_fw_db , //Concept behind Forwarding unit

 	 output reg          o_riscv_hzrdu_stall_pc  ,
                       o_riscv_hzrdu_stall_fd  ,
                       o_riscv_hzrdu_flush_fd ,
                       o_riscv_hzrdu_flush_de
 );


//Note : needing of mem_Asserted >>not useful i thimk if it is implented as priority mux will not check 2nd condition if 1st is satisfied
assign mem_asserted_data_hazard = ( i_riscv_hzrdu_rs1addr_e == i_riscv_hzrdu_rdaddr_m) && i_riscv_hzrdu_regw_m && i_riscv_hzrdu_rdaddr_m ;

always @(*)

    begin 
       /*if(~rst_n) begin
             <= 0;
        end else begin */
    
        if      ( (i_riscv_hzrdu_rs2addr_e == i_riscv_hzrdu_rdaddr_m ) &&
                (i_riscv_hzrdu_regw_m ) && 
                (i_riscv_hzrdu_rdaddr_m !=0) )
                    begin
                      o_riscv_hzrdu_fw_db = 1  ;
                    end

        else if ( (i_riscv_hzrdu_rs2addr_e == i_riscv_hzrdu_rdaddr_w ) &&
                (i_riscv_hzrdu_regw_w )        && 
                (i_riscv_hzrdu_rdaddr_w !=0 )  &&
                (mem_asserted_data_hazard == 0 )  )
                    begin
                      o_riscv_hzrdu_fw_db = 2 ;
                    end
        else 

                      o_riscv_hzrdu_fw_db = 0 ; 
    
    end


always @(*)

    begin 
        /*if(~rst_n) begin
             <= 0;
        end else begin */

        if      ( (i_riscv_hzrdu_rs1addr_e == i_riscv_hzrdu_rdaddr_m) && 
                (i_riscv_hzrdu_regw_m) &&
                (i_riscv_hzrdu_rdaddr_m !=0) )
                   begin
                     o_riscv_hzrdu_fw_da  = 1  ;
                   end

        else if ( i_riscv_hzrdu_rs1addr_e == i_riscv_hzrdu_rdaddr_w && 
                i_riscv_hzrdu_regw_w && 
                (i_riscv_hzrdu_rdaddr_w !=0 ) && 
                (~ mem_asserted_data_hazard ) )
                   begin
                     o_riscv_hzrdu_fw_da  = 2 ;
                   end
        else 

                     o_riscv_hzrdu_fw_da  = 0 ; 
    end


always @(*) 

    begin 
        /*if(~rst_n) 
         <= 0; else */
   
        if      ( ( (i_riscv_hzrdu_rs1addr_d == i_riscv_hzrdu_rs1addr_e ||  i_riscv_hzrdu_rs2addr_d == i_riscv_hzrdu_rs1addr_e  ) && 
                i_riscv_hzrdu_resultsrc == 2'b10 ) || 
                i_riscv_hzrdu_pcsrc  ) //Condition For branch hazard

                  begin
                    o_riscv_hzrdu_stall_pc = 1 ; 
                    o_riscv_hzrdu_stall_fd = 1 ;  
                    o_riscv_hzrdu_flush_de = 1 ; 
                  end
 
        else     
                  begin
                    o_riscv_hzrdu_stall_pc = 0 ;
                    o_riscv_hzrdu_stall_fd = 0 ;  
                    o_riscv_hzrdu_flush_de = 0 ; 
                  end


    end


/*  supporting lw sw hazardalways @(*) 

    begin 
        /*if(~rst_n) 
         <= 0; else 
   
        if      ( ( (i_riscv_hzrdu_rs1addr_d == i_riscv_hzrdu_rs1addr_e ||  i_riscv_hzrdu_rs2addr_d == i_riscv_hzrdu_rs1addr_e  ) && 
                i_riscv_hzrdu_resultsrc == 2'b10 && MEM_Write_d !=1) //dont stall if it is sw instruction || 
                i_riscv_hzrdu_pcsrc  ) //Condition For branch hazard

                  begin
                    o_riscv_hzrdu_stall_pc = 1 ; 
                    o_riscv_hzrdu_stall_fd = 1 ;  
                    o_riscv_hzrdu_flush_de = 1 ; 
                  end
 
        else     
                  begin
                    o_riscv_hzrdu_stall_pc = 0 ;
                    o_riscv_hzrdu_stall_fd = 0 ;  
                    o_riscv_hzrdu_flush_de = 0 ; 
                  end


    end    */


   /* supporting lw sw hazard 
   always @(*)

    begin 
        /*if(~rst_n) begin
             <= 0;
        end else begin */

        if      ( (i_riscv_hzrdu_rs2addr_m == i_riscv_hzrdu_rdaddr_w) && 
                (i_riscv_hzrdu_regw_m ) && (MEM_WRITE_M = 1 );
                (i_riscv_hzrdu_rdaddr_m !=0) )
                   begin
                     o_riscv_hzrdu_fw_dc  = 1  ;
                   end

        else 

                     o_riscv_hzrdu_fw_dc  = 0 ; 
    end
*/


assign o_riscv_hzrdu_flush_fd =  ( i_riscv_hzrdu_pcsrc )? 1 : 0 ;

/*assign o_riscv_hzrdu_flush_de = (i_riscv_hzrdu_pcsrc)?1:0 ;
assign o_riscv_hzrdu_stall_fd = (i_riscv_hzrdu_pcsrc)?1:0;*/



endmodule




