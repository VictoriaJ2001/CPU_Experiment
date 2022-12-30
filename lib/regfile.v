`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata,
    //新增
    input wire ex_id_wreg,
    input wire [4:0] ex_id_waddr,
    input wire [31:0] ex_id_wdata,
    
    input wire mem_id_wreg,
    input wire [4:0] mem_id_waddr,
    input wire [31:0] mem_id_wdata,
    
    input wire wb_id_wreg,
    input wire [4:0] wb_id_waddr,
    input wire [31:0] wb_id_wdata,
    
    //LL 数据相关
    input wire ex_id_hi_we,           
    input wire ex_id_lo_we,           
    input wire [31:0] ex_id_hi_i,                
    input wire [31:0] ex_id_lo_i,
    input wire mem_id_hi_we,           
    input wire mem_id_lo_we,           
    input wire [31:0] mem_id_hi_i,                
    input wire [31:0] mem_id_lo_i,
    input wire wb_id_hi_we,           
    input wire wb_id_lo_we,           
    input wire [31:0] wb_id_hi_i,                
    input wire [31:0] wb_id_lo_i,
    
     //LL
    input wire hi_we,
    input wire lo_we,
    input wire hi_read,
    input wire lo_read,
    input wire [31:0] hi_i,
    input wire [31:0] lo_i,
    output wire [31:0] hi_out,
    output wire [31:0] lo_out
);
    reg [31:0] reg_array [31:0];//定义32位寄存器
    reg [31:0] reg_hi;//定义hi寄存器  (LL)
    reg [31:0] reg_lo;//定义lo寄存器  (LL)
    
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end
    
    //LL write
    always @ (posedge clk) begin
        if (hi_we) begin
            reg_hi <= hi_i;
        end  
        if(lo_we) begin
            reg_lo <= lo_i;
        end
    end

    // read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : 
                    ((ex_id_wreg==1'b1)&&(ex_id_waddr==raddr1))?ex_id_wdata:
                    ((mem_id_wreg==1'b1)&&(mem_id_waddr==raddr1))?mem_id_wdata:
                    ((wb_id_wreg==1'b1)&&(wb_id_waddr==raddr1))?wb_id_wdata:reg_array[raddr1];

    // read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : 
                    ((ex_id_wreg==1'b1)&&(ex_id_waddr==raddr2))?ex_id_wdata:
                    ((mem_id_wreg==1'b1)&&(mem_id_waddr==raddr2))?mem_id_wdata:
                    ((wb_id_wreg==1'b1)&&(wb_id_waddr==raddr2))?wb_id_wdata:reg_array[raddr2];
     
    //LL read hi_out
    assign hi_out = (ex_id_hi_we) ? ex_id_hi_i:
                    (mem_id_hi_we)? mem_id_hi_i:
                    (wb_id_hi_we) ? wb_id_hi_i:
           //         (hi_read) ? hi_out:
                    reg_hi; 
                    
    //LL read lo_out          
    assign lo_out = (ex_id_lo_we) ? ex_id_lo_i:
                    (mem_id_lo_we)? mem_id_lo_i:
                    (wb_id_lo_we) ? wb_id_lo_i:
          //          (lo_read) ? lo_out:
                    reg_lo; 
                    
   // LL    
    assign out = (hi_read)?hi_out:
                 (lo_read)?lo_out:
                 32'b0;
endmodule