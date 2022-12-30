`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq_from_id,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus,
    ////新增
    input wire [`EX_TO_ID_WD-1:0] ex_to_id_bus,
    input wire [`MEM_TO_ID_WD-1:0] mem_to_id_bus,
    input wire [`WB_TO_ID_WD-1:0] wb_to_id_bus,
    //12-10
    input wire isLS,
    input wire div_ready_to_id
);
    wire hi_read; //LL
    wire lo_read; //LL
    
    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    //12-9
    //reg delayslot;//延迟槽
    
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;

    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;
    //新增
    wire ex_id_wreg;
    wire [4:0] ex_id_waddr;
    wire [31:0] ex_id_wdata;
    wire ex_id_hi_we;           //LL
    wire ex_id_lo_we;           //LL
    wire [31:0] ex_id_hi;       //LL
    wire [31:0] ex_id_lo;       //LL

    wire ex_rf_hi_we;           //LL
    wire ex_rf_lo_we;           //LL
    wire [31:0] ex_rf_hi;       //LL
    wire [31:0] ex_rf_lo;       //LL
      
    wire mem_id_wreg;
    wire [4:0] mem_id_waddr;
    wire [31:0] mem_id_wdata;
    wire mem_id_hi_we;          //LL
    wire mem_id_lo_we;          //LL
    wire [31:0] mem_id_hi;      //LL
    wire [31:0] mem_id_lo;      //LL
    
    wire wb_id_wreg;
    wire [4:0] wb_id_waddr;
    wire [31:0] wb_id_wdata;
    wire wb_id_hi_we;          //LL
    wire wb_id_lo_we;          //LL
    wire [31:0] wb_id_hi;      //LL
    wire [31:0] wb_id_lo;      //LL
    wire [31:0] hi_out_file;         //LL
    wire [31:0] lo_out_file;         //LL
    
    reg id_stop;
    
    //
    always @ (posedge clk) begin
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;       
            id_stop <= 1'b0;      
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
            id_stop <= 1'b0;     
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
            id_stop <= 1'b0;     
        end
        else if(stall[2] == `Stop && div_ready_to_id==1'b0) begin
            id_stop <= 1'b1;
        end
    end
    
    //12-10
  //  reg stop;
  //  always @ (posedge clk) begin
    //    if(rst) begin
    //        stop<=1'b0;
     //   end else if(stall[2]==`Stop)begin
     //       stop<=1'b1;
      //  end else begin
     //       stop<=1'b0;
     //   end
   // end
    
    assign inst = id_stop?inst:inst_sram_rdata;
    
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    assign {
        ex_rf_hi_we,            //LL
        ex_rf_lo_we,            //LL
        ex_rf_hi,               //LL
        ex_rf_lo,               //LL
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
        
    } = wb_to_rf_bus;
    //新增
    assign {
        ex_id_wreg,
        ex_id_waddr,
        ex_id_wdata,
        ex_id_hi_we,       //LL
        ex_id_lo_we,       //LL
        ex_id_hi,          //LL
        ex_id_lo           //LL
    }=ex_to_id_bus;
    
    assign {
        mem_id_wreg,
        mem_id_waddr,
        mem_id_wdata,
        mem_id_hi_we,       //LL
        mem_id_lo_we,       //LL
        mem_id_hi,          //LL
        mem_id_lo           //LL
    }=mem_to_id_bus;
   
    assign {
        wb_id_wreg,
        wb_id_waddr,
        wb_id_wdata,
        wb_id_hi_we,       //LL
        wb_id_lo_we,       //LL
        wb_id_hi,          //LL
        wb_id_lo           //LL
    }=wb_to_id_bus;
    
    //

    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [3:0] data_ram_readen;     //LL
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;

    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs ),
        .rdata1 (rdata1 ),
        .raddr2 (rt ),
        .rdata2 (rdata2 ),
        
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  ),
        
        //新增
        .ex_id_wreg  (ex_id_wreg  ),
        .ex_id_waddr (ex_id_waddr ),
        .ex_id_wdata (ex_id_wdata ),
        .mem_id_wreg (mem_id_wreg ),
        .mem_id_waddr(mem_id_waddr),
        .mem_id_wdata(mem_id_wdata),
        .wb_id_wreg  (wb_id_wreg  ),
        .wb_id_waddr (wb_id_waddr ),
        .wb_id_wdata (wb_id_wdata ),
        
        //LL
        .hi_we(ex_rf_hi_we),           
        .lo_we(ex_rf_lo_we),  
        //是否缺少hi_read,lo_read 
        .hi_read(hi_read),
        .lo_read(lo_read),        
        .hi_i(ex_rf_hi),                
        .lo_i(ex_rf_lo),
        .hi_out(hi_out_file),
        .lo_out(lo_out_file),
        //LL 数据相关
        .ex_id_hi_we(ex_id_hi_we),           
        .ex_id_lo_we(ex_id_lo_we),           
        .ex_id_hi_i(ex_id_hi),                
        .ex_id_lo_i(ex_id_lo),
        .mem_id_hi_we(mem_id_hi_we),           
        .mem_id_lo_we(mem_id_lo_we),           
        .mem_id_hi_i(mem_id_hi),                
        .mem_id_lo_i(mem_id_lo),
        .wb_id_hi_we(wb_id_hi_we),           
        .wb_id_lo_we(wb_id_lo_we),           
        .wb_id_hi_i(wb_id_hi),                
        .wb_id_lo_i(wb_id_lo)             
        
    );
    
    //译码
    assign opcode = inst[31:26];//运算操作
    assign rs = inst[25:21];//源寄存器
    assign rt = inst[20:16];//目的寄存器
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];//立即数
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];

    wire inst_ori, inst_lui, inst_addiu, inst_beq;
    //新增
    wire inst_and,inst_or,inst_nor,inst_xor;
    wire inst_andi,inst_xori;
    wire inst_sll,inst_sllv,inst_sra,inst_srav,inst_srl,inst_srlv;
    wire inst_subu,inst_slt,inst_sltu;
    //12-10
    wire inst_slti,inst_sltiu;
    wire inst_j,inst_bne,inst_add,inst_addi;
    
    
    wire inst_jal,inst_jr;
    wire inst_addu,inst_sub;
    wire inst_lw,inst_sw;
    wire inst_movn,inst_movz,inst_mfhi,inst_mflo,inst_mthi,inst_mtlo;                  //LL
    wire inst_bgez,inst_bgtz, inst_blez ,inst_bltz ,inst_bltzal,inst_bgezal,inst_jalr ;//LL
    wire inst_lb,inst_lbu, inst_lh, inst_lhu, inst_sb,  inst_sh;                       //LL

    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;
    wire inst_div, inst_divu, inst_mult, inst_multu;//LL
    
    assign stallreq_from_id=(isLS&((rs==ex_id_waddr)|(rt==ex_id_waddr)))? `Stop: `NoStop;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );

    
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_beq     = op_d[6'b00_0100];
    //新增
    assign inst_and     = op_d[6'b00_0000]&(sa==5'b00000)&func_d[6'b10_0100];
    assign inst_or      = op_d[6'b00_0000]&(sa==5'b00000)&func_d[6'b10_0101];
    assign inst_nor     = op_d[6'b00_0000]&(sa==5'b00000)&func_d[6'b10_0111];
    assign inst_xor     = op_d[6'b00_0000]&(sa==5'b00000)&func_d[6'b10_0110];
    assign inst_add     = op_d[6'b00_0000] & func_d[6'b10_0000];
    assign inst_addi    = op_d[6'b00_1000];
    assign inst_andi    = op_d[6'b00_1100];
    assign inst_xori    = op_d[6'b00_1110];
    assign inst_sub     = op_d[6'b00_0000] & func_d[6'b10_0010];    
    assign inst_sll     = op_d[6'b00_0000]&rs_d[5'b00000]&func_d[6'b00_0000];
    assign inst_sllv    = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b00_0100];
    assign inst_sra     = op_d[6'b00_0000]&rs_d[5'b00000]&func_d[6'b00_0011];
    assign inst_srav    = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b00_0111];
    assign inst_srl     = op_d[6'b00_0000]&rs_d[5'b00000]&func_d[6'b00_0010];
    assign inst_srlv    = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b00_0110];
    
    assign inst_subu    = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b10_0011];
    assign inst_slt     = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b10_1010];
    assign inst_sltu    = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b10_1011];
    assign inst_slti    = op_d[6'b00_1010];
    assign inst_sltiu   = op_d[6'b00_1011];
    
    assign inst_jal     = op_d[6'b00_0011];
    assign inst_jr      = op_d[6'b00_0000]&inst[20:11]==10'b00000_00000&sa==5'b00000&func_d[6'b00_1000];
    assign inst_bne     = op_d[6'b00_0101];
    assign inst_j       = op_d[6'b00_0010];
    
    assign inst_addu    = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b10_0001];
    assign inst_lw      = op_d[6'b10_0011];
    assign inst_sw      = op_d[6'b10_1011];
    
    assign inst_movn    = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b00_1011];
    assign inst_movz    = op_d[6'b00_0000]&sa==5'b00000&func_d[6'b00_1010];
    assign inst_mfhi    = op_d[6'b00_0000]&inst[25:16]==10'b00000_00000&sa==5'b00000&func_d[6'b01_0000];
    assign inst_mflo    = op_d[6'b00_0000]&inst[25:16]==10'b00000_00000&sa==5'b00000&func_d[6'b01_0010];
    assign inst_mthi    = op_d[6'b00_0000]&inst[20:11]==10'b00000_00000&sa==5'b00000&func_d[6'b01_0001];
    assign inst_mtlo    = op_d[6'b00_0000]&inst[20:11]==10'b00000_00000&sa==5'b00000&func_d[6'b01_0011];
    
     //LL
    assign inst_bgez    = op_d[6'b00_0001]&rt_d[5'b00001];
    assign inst_bgtz    = op_d[6'b00_0111]&rt_d[5'b00000];
    assign inst_blez    = op_d[6'b00_0110]&rt_d[5'b00000];
    assign inst_bltz    = op_d[6'b00_0001]&rt_d[5'b00000];
    assign inst_bltzal  = op_d[6'b00_0001]&rt_d[5'b10000];
    assign inst_bgezal  = op_d[6'b00_0001]&rt_d[5'b10001];
    assign inst_jalr    = op_d[6'b00_0000]&rt_d[5'b00000]&sa==5'b00000&func_d[6'b00_1001];
    assign inst_div     = op_d[6'b00_000?]&inst[15:6]==10'b00000_00000&func_d[6'b01_1010];
    assign inst_divu    = op_d[6'b00_0000]&inst[15:6]==10'b00000_00000&func_d[6'b01_1011];
    assign inst_mult    = op_d[6'b00_0000]&inst[15:6]==10'b00000_00000&func_d[6'b01_1000];
    assign inst_multu   = op_d[6'b00_0000]&inst[15:6]==10'b00000_00000&func_d[6'b01_1001];
    assign inst_lb      = op_d[6'b10_0000];
    assign inst_lbu     = op_d[6'b10_0100];
    assign inst_lh      = op_d[6'b10_0001];
    assign inst_lhu     = op_d[6'b10_0101];
    assign inst_sb      = op_d[6'b10_1000];
    assign inst_sh      = op_d[6'b10_1001];
    
    // rs to reg1
    assign sel_alu_src1[0] = inst_srlv | inst_srav | inst_sllv |
                              inst_xori | inst_ori | inst_addiu | inst_subu | 
                              inst_andi | inst_and | inst_slt | 
                              inst_sltu | inst_nor | inst_xor | inst_or|
                              inst_addu | inst_lw | inst_sw |inst_slti|
                              inst_sltiu|inst_add|inst_addi|inst_sub|
                              inst_div  | inst_divu | inst_mult | inst_multu|inst_jalr |         //LL
                              inst_mthi | inst_mtlo | inst_sh   | inst_sb   | inst_lhu |         //LL
                              inst_lh | inst_lb | inst_lbu ;                                     //LL

    // pc to reg1
    assign sel_alu_src1[1] = inst_jal|
                             inst_bltzal | inst_bgezal| inst_jalr;    //LL
                             

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] = inst_sll | inst_srl | inst_sra;

    
    // rt to reg2
    assign sel_alu_src2[0] = inst_srlv | inst_srav | inst_sllv | inst_subu | 
                              inst_and | inst_slt | inst_sltu | inst_nor | inst_xor | 
                              inst_sll | inst_srl | inst_sra | inst_or | inst_addu|inst_add|inst_sub|
                              inst_div | inst_divu| inst_mult| inst_multu |inst_sh | inst_sb | inst_lhu |         //LL
                              inst_lh | inst_lb | inst_lbu ;                                                      //LL
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_lw |inst_sw|inst_slti|
                             inst_sltiu|inst_addi|
                             inst_sh | inst_sb | inst_lhu | inst_lh | inst_lbu|inst_lb;         //LL

    // 32'b8 to reg2
        assign sel_alu_src2[2] = inst_jal|
                                 inst_j|inst_bltzal|inst_bgezal //LL
                                 |inst_jalr ;        //LL

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_xori | inst_ori | inst_andi;



    assign op_add = inst_addiu | inst_jal|inst_addu|inst_lw|inst_sw|inst_add|inst_addi|
                    inst_bltzal| inst_bgezal|inst_jalr|                                                 //LL
                    inst_sh | inst_sb | inst_lhu | inst_lh | inst_lbu |  inst_lb ;                      //LL
    assign op_sub = inst_subu|inst_sub;
    assign op_slt = inst_slt|inst_slti;
    assign op_sltu = inst_sltu|inst_sltiu;
    assign op_and = inst_andi | inst_and;
    assign op_nor = inst_nor;
    assign op_or = inst_ori | inst_or;
    assign op_xor = inst_xor | inst_xori;
    assign op_sll = inst_sll | inst_sllv;
    assign op_srl = inst_srl | inst_srlv;
    assign op_sra = inst_sra | inst_srav;
    assign op_lui = inst_lui;

    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};

    // load and store enable
    assign data_ram_en = inst_sh | inst_sb | inst_lhu | inst_lh | inst_lbu | inst_lw | inst_sw | inst_lb;//LL

    // write enable
    assign data_ram_wen = inst_sw?4'b1111:4'b0000;
    
    //LL
    //mem read enable
    assign data_ram_readen =  inst_lw  ? 4'b1111 
                             :inst_lb  ? 4'b0001 
                             :inst_lbu ? 4'b0010
                             :inst_lh  ? 4'b0011
                             :inst_lhu ? 4'b0100
                             :inst_sb  ? 4'b0101
                             :inst_sh  ? 4'b0111
                             :4'b0000;
                             
    wire hi_write;//LL
    wire lo_write;//LL
    
    assign hi_read = inst_mfhi;                             //LL
    assign lo_read = inst_mflo;                             //LL
    assign hi_write = inst_mthi;                             //LL
    assign lo_write = inst_mtlo;                             //LL
    // regfile store enable
    assign rf_we = inst_srlv | inst_srav | inst_sllv | inst_xori | 
                    inst_or | inst_ori | inst_lui | inst_addiu | inst_subu | 
                    inst_andi | inst_and | inst_slt | inst_sltu | inst_nor | 
                    inst_xor | inst_sll | inst_srl | inst_sra | inst_jal|
                    inst_addu|inst_lw|inst_slti|inst_sltiu|inst_add|inst_addi|inst_sub|
                    inst_bgezal | inst_bltzal | inst_jalr | inst_mfhi | inst_mflo|      //LL
                    inst_lhu | inst_lh | inst_lbu | inst_lb;                            //LL

    // store in [rd]
    assign sel_rf_dst[0] = inst_srlv | inst_srav | inst_sllv | inst_subu | 
                            inst_and | inst_slt | inst_sltu | inst_nor | inst_xor | 
                            inst_sll | inst_srl | inst_sra|inst_addu|inst_or|inst_add|inst_sub|
                            inst_jalr| inst_mfhi| inst_mflo;                      //LL
    // store in [rt] 
    assign sel_rf_dst[1] = inst_xori | inst_ori | inst_lui | inst_addiu | inst_andi 
                            | inst_lw|inst_slti|inst_sltiu|inst_addi|                          //LL
                            inst_lhu | inst_lh | inst_lbu | inst_lb;                           //LL
    // store in [31]
    assign sel_rf_dst[2] = inst_jal|
                           inst_bltzal | inst_bgezal;//LL

    // sel for regfile address 可以选出rd或者rt
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
   // assign sel_rf_res = inst_lw; 
    assign sel_rf_res = 1'b0; //LL

    assign id_to_ex_bus = {
        data_ram_readen,//3
        hi_write,//LL       
        lo_write,//LL
        hi_read,//LL
        lo_read,//LL
        hi_out_file, //LL
        lo_out_file, //LL
        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rdata1,         // 63:32
        rdata2          // 31:0
    };


    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    assign pc_plus_4 = id_pc + 32'h4;
    
    assign rs_eq_rt  = (rdata1 == rdata2);                           //LL
    assign rs_neq_rt = (rdata1 != rdata2);                           //LL
    assign rs_ge_z   = (rdata1[31] == 1'b0);                         //LL
    assign rs_gt_z   = (rdata1[31] == 1'b0 && rdata1 != 32'b0);      //LL
    assign rs_le_z   = (rdata1[31] == 1'b1 || rdata1 == 32'b0);      //LL
    assign rs_lt_z   = (rdata1[31] == 1'b1);                         //LL
        
    assign rs_eq_rt = (rdata1 == rdata2);

    assign br_e = (inst_beq & rs_eq_rt)  | (inst_bne&~rs_eq_rt) | inst_jal|inst_jr|inst_j|inst_jalr|
                  (inst_bgez && rs_ge_z) | (inst_bgtz &&  rs_gt_z)  | (inst_blez && rs_le_z)|   //LL
                  (inst_bltz && rs_lt_z) | (inst_bltzal && rs_lt_z) | (inst_bgezal && rs_ge_z); //LL 
    assign br_addr = inst_beq ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) : 
                      inst_bne?(pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):
                      inst_jal?({pc_plus_4[31:28],inst[25:0],2'b0}):
                      inst_bgez?(pc_plus_4+{{14{inst[15]}},inst[15:0],2'b0}):   //LL
                      inst_bgtz?(pc_plus_4+{{14{inst[15]}},inst[15:0],2'b0}):   //LL
                      inst_blez?(pc_plus_4+{{14{inst[15]}},inst[15:0],2'b0}):   //LL
                      inst_bltz?(pc_plus_4+{{14{inst[15]}},inst[15:0],2'b0}):   //LL
                      inst_bltzal?(pc_plus_4+{{14{inst[15]}},inst[15:0],2'b0}): //LL
                      inst_bgezal?(pc_plus_4+{{14{inst[15]}},inst[15:0],2'b0}): //LL
                      inst_jr?(rdata1):
                      inst_jalr?(rdata1):                                        //LL
                      inst_j?({pc_plus_4[31:28],inst[25:0],2'b0}):
                      32'b0;

    assign br_bus = {
        br_e,
        br_addr
    };
    

endmodule