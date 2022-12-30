`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,

    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,
    
    ///新增
    output wire [`MEM_TO_ID_WD-1:0] mem_to_id_bus
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        // else if (flush) begin
        //     ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        // end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
        end
    end

    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [3:0] data_ram_readen;//LL
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;
    wire hi_we;         //LL
    wire lo_we;         //LL
    wire [31:0] hi_ex; //LL
    wire [31:0] lo_ex; //LL
    
    assign mem_result=data_sram_rdata;

    assign {
        data_ram_readen,          //LL
        hi_we,                    //LL
        lo_we,                    //LL
        hi_ex,                    //LL
        lo_ex,                    //LL
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;



    //assign rf_wdata = sel_rf_res ? mem_result :ex_result;
    
    //LL
    assign rf_wdata =     (data_ram_readen==4'b1111 && data_ram_en==1'b1) ? data_sram_rdata 
                        : (data_ram_readen==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({{24{data_sram_rdata[7]}},data_sram_rdata[7:0]})
                        : (data_ram_readen==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b01) ?({{24{data_sram_rdata[15]}},data_sram_rdata[15:8]})
                        : (data_ram_readen==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({{24{data_sram_rdata[23]}},data_sram_rdata[23:16]})
                        : (data_ram_readen==4'b0001 && data_ram_en==1'b1 && ex_result[1:0]==2'b11) ?({{24{data_sram_rdata[31]}},data_sram_rdata[31:24]})
                        : (data_ram_readen==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({24'b0,data_sram_rdata[7:0]})
                        : (data_ram_readen==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b01) ?({24'b0,data_sram_rdata[15:8]})
                        : (data_ram_readen==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({24'b0,data_sram_rdata[23:16]})
                        : (data_ram_readen==4'b0010 && data_ram_en==1'b1 && ex_result[1:0]==2'b11) ?({24'b0,data_sram_rdata[31:24]})
                        : (data_ram_readen==4'b0011 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({{16{data_sram_rdata[15]}},data_sram_rdata[15:0]})
                        : (data_ram_readen==4'b0011 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({{16{data_sram_rdata[31]}},data_sram_rdata[31:16]})
                        : (data_ram_readen==4'b0100 && data_ram_en==1'b1 && ex_result[1:0]==2'b00) ?({16'b0,data_sram_rdata[15:0]})
                        : (data_ram_readen==4'b0100 && data_ram_en==1'b1 && ex_result[1:0]==2'b10) ?({16'b0,data_sram_rdata[31:16]})
                        : ex_result;
                        

    assign mem_to_wb_bus = {
        hi_we,                    //LL
        lo_we,                    //LL
        hi_ex,                    //LL
        lo_ex,                    //LL
        mem_pc,     // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };
    //新增
    assign mem_to_id_bus={
        rf_we,
        rf_waddr,
        rf_wdata,
        hi_we,                    //LL
        lo_we,                    //LL
        hi_ex,                    //LL
        lo_ex                     //LL
    };

endmodule