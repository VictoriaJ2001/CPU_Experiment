`include "lib/defines.vh"
module WB(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,

    output wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,
    //新增
    output wire [`WB_TO_ID_WD-1:0] wb_to_id_bus
);

    reg [`MEM_TO_WB_WD-1:0] mem_to_wb_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
        end
        // else if (flush) begin
        //     mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
        // end
        else if (stall[4]==`Stop && stall[5]==`NoStop) begin
            mem_to_wb_bus_r <= `MEM_TO_WB_WD'b0;
        end
        else if (stall[4]==`NoStop) begin
            mem_to_wb_bus_r <= mem_to_wb_bus;
        end
    end

    wire [31:0] wb_pc;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire hi_we;         //LL
    wire lo_we;         //LL
    wire [31:0] hi_ex; //LL
    wire [31:0] lo_ex; //LL

    assign {
        hi_we,                    //LL
        lo_we,                    //LL
        hi_ex,                    //LL
        lo_ex,                    //LL
        wb_pc,
        rf_we,
        rf_waddr,
        rf_wdata
    } = mem_to_wb_bus_r;

    // assign wb_to_rf_bus = mem_to_wb_bus_r[`WB_TO_RF_WD-1:0];
    assign wb_to_rf_bus = {
        hi_we,                    //LL
        lo_we,                    //LL
        hi_ex,                    //LL
        lo_ex,                    //LL
        rf_we,
        rf_waddr,
        rf_wdata
    };
    //新增
    
    assign wb_to_id_bus={
        rf_we,
        rf_waddr,
        rf_wdata,
        hi_we,                    //LL
        lo_we,                    //LL
        hi_ex,                    //LL
        lo_ex                     //LL
    };
    
    //
    
    assign debug_wb_pc = wb_pc;
    assign debug_wb_rf_wen = {4{rf_we}};
    assign debug_wb_rf_wnum = rf_waddr;
    assign debug_wb_rf_wdata = rf_wdata;

    
endmodule