module reg_fwrite(
    input        clk_i,
    input        rstn_i,
    
    input        rd_en,
    input [6:0]  rd_addr,
    input [31:0] rd_wdata,
    input [31:0] pc,
    input [2:0]  mem_ren,
    input [31:0] mem_raddr,
    input [2:0]  mem_wen,
    input [31:0] mem_waddr,
    input [31:0] mem_wdata,
    
    input        wrd_en1,
    input [ 6:0] wrd_add1,
    input [31:0] wrd_data1,
    input        wrd_en2,
    input [ 6:0] wrd_add2,
    input [31:0] wrd_data2
);

// ---------------		Reg Status Write (Simulation Only)	-------------------- //
    
    reg        reg_rd_en ; always@(posedge clk_i) reg_rd_en  <= rd_en ;
    reg [6:0]  reg_rd_add; always@(posedge clk_i) reg_rd_add <= rd_addr ;
    reg [31:0] reg_rd_wdata; always@(posedge clk_i) reg_rd_wdata <= rd_wdata ;
    
    reg [31:0] reg_pc        ; always@(posedge clk_i) reg_pc         <= pc ;
    reg [ 2:0] reg_mem_ren   ; always@(posedge clk_i) reg_mem_ren    <= mem_ren ;
    reg [ 2:0] reg_mem_wen   ; always@(posedge clk_i) reg_mem_wen    <= mem_wen ;
    
    reg [31:0] reg_mem_radd  ; always@(posedge clk_i) if (mem_ren!=0) reg_mem_radd  <= mem_raddr ; else reg_mem_radd  <= 0;
    reg [31:0] reg_mem_wadd  ; always@(posedge clk_i) if (mem_wen!=0) reg_mem_wadd  <= mem_waddr ; else reg_mem_wadd  <= 0;
    reg [31:0] reg_mem_wdata ; always@(posedge clk_i) 
        if      (mem_wen[0]) reg_mem_wdata <= {24'd0,mem_wdata[7:0]}; 
        else if (mem_wen[1]) reg_mem_wdata <= {16'd0,mem_wdata[15:0]}; 
        else if (mem_wen[2]) reg_mem_wdata <= mem_wdata; 
        else                 reg_mem_wdata <= 0;
    
    integer write_file;
    initial begin
        write_file = $fopen("./reg_status_hw.txt","w");
        $fdisplay(write_file, "pc       (rd rd  wdata   ) (wen wadd     wdata    | radd    )");
        $fclose(write_file);
    end
    
    wire[4:0] wire_rd_add = reg_rd_add[4:0] ;
    
    wire vrd_en = reg_rd_en & (wire_rd_add!=0) ; 
    
    wire [23:0] reg_name = (wire_rd_add==01) ? " ra" : (wire_rd_add==02) ? " sp" : (wire_rd_add==03) ? " gp" : (wire_rd_add==04) ? " tp"
    :                      (wire_rd_add==05) ? " t0" : (wire_rd_add==06) ? " t1" : (wire_rd_add==07) ? " t2" : (wire_rd_add==08) ? " s0"
    :                      (wire_rd_add==09) ? " s1" : (wire_rd_add==10) ? " a0" : (wire_rd_add==11) ? " a1" : (wire_rd_add==12) ? " a2"
    :                      (wire_rd_add==13) ? " a3" : (wire_rd_add==14) ? " a4" : (wire_rd_add==15) ? " a5" : (wire_rd_add==16) ? " a6"
    :                      (wire_rd_add==17) ? " a7" : (wire_rd_add==18) ? " s2" : (wire_rd_add==19) ? " s3" : (wire_rd_add==20) ? " s4"
    :                      (wire_rd_add==21) ? " s5" : (wire_rd_add==22) ? " s6" : (wire_rd_add==23) ? " s7" : (wire_rd_add==24) ? " s8"
    :                      (wire_rd_add==25) ? " s9" : (wire_rd_add==26) ? "s10" : (wire_rd_add==27) ? "s11" : (wire_rd_add==28) ? " t3"
    :                      (wire_rd_add==29) ? " t4" : (wire_rd_add==30) ? " t5" : (wire_rd_add==31) ? " t6" :                    "  0" ;
    
    always@(posedge clk_i) begin
        if ( vrd_en ) begin
            write_file = $fopen("./reg_status_hw.txt","a");
            $fdisplay(write_file, "%h (%02d %s %h) (%b %h %h | %h)",reg_pc,wire_rd_add,reg_name,reg_rd_wdata,reg_mem_wen,reg_mem_wadd,reg_mem_wdata,reg_mem_radd);
            $fclose(write_file);
        end else if ( reg_mem_wen!=0 ) begin
            write_file = $fopen("./reg_status_hw.txt","a");
            $fdisplay(write_file, "%h (%02d %s %h) (%b %h %h | %h)",reg_pc,0,"000",32'd0,reg_mem_wen,reg_mem_wadd,reg_mem_wdata,reg_mem_radd);
            $fclose(write_file);
        end 
    end
    
    
    reg [31:0] inst_counter;
    always@(posedge clk_i) begin
        if (!rstn_i) begin
            inst_counter <= 0;
        end else if ( vrd_en | reg_mem_wen!=0 ) begin
            inst_counter <= inst_counter + 1 ;
        end 
    end
    
//-------------------------------------------------------------------------------------//
//                     Storing position of uncompleted instructions
//-------------------------------------------------------------------------------------//
    
    integer pos;
    
    reg [31:0] mem_pos [127:0];
    
    always@(posedge clk_i) begin
        if ( vrd_en ) begin
            write_file = $fopen("./reg_status_hw.txt","a");
            pos = $ftell(write_file);
            mem_pos[reg_rd_add] <= pos;
            $fclose(write_file);
        end
    end
    
//-------------------------------------------------------------------------------------//
//                Writing register write data to uncompleted instructions
//-------------------------------------------------------------------------------------//
    
    integer pos_write, fseek;
    
    wire vwrd_en1 = wrd_en1 & (wrd_add1[4:0]!=0) ; 
    wire vwrd_en2 = wrd_en2 & (wrd_add2[4:0]!=0) ; 
    
    wire [31:0] pos1 = mem_pos[wrd_add1] ;
    wire [31:0] pos2 = mem_pos[wrd_add2] ;
    
    always@(posedge clk_i) begin
        
        if ( vwrd_en1 ) begin
            write_file = $fopen("./reg_status_hw.txt","r+b");
            pos_write = pos1 - 45 ;
            fseek = $fseek(write_file, pos_write , 0);
            // $fwrite(write_file, "xxxxxxxx" );
            $fwrite(write_file, "%h", wrd_data1);
            $fclose(write_file);
        end
        
        if ( vwrd_en2 ) begin
            write_file = $fopen("./reg_status_hw.txt","r+b");
            pos_write = pos2 - 45 ;
            fseek = $fseek(write_file, pos_write , 0);
            // $fwrite(write_file, "xxxxxxxx" );
            $fwrite(write_file, "%h", wrd_data2);
            $fclose(write_file);
        end
        
    end

endmodule 