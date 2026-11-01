`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/18 19:51:53
// Design Name: 
// Module Name: SCPU_TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SCPU_TOP#(
    parameter DIV_SLOW_BITS = 27,
    parameter DIV_FAST_BITS = 25
)(
    input  wire        clk,
    input  wire        rstn,
    input  wire [15:0] sw_i,

    output wire [7:0]  disp_an_o,
    output wire [7:0]  disp_seg_o
);

    // =================================================
    // 1. 控制电路：确定多久读取下一条数据
    //
    // SW15 = 0：每2^25个主时钟周期更新一次
    // SW15 = 1：每2^27个主时钟周期更新一次
    // =================================================

    wire [31:0] update_cycles;

    assign update_cycles =
        sw_i[15] ? (32'd1 << DIV_SLOW_BITS)
                 : (32'd1 << DIV_FAST_BITS);

    reg [31:0] update_count;
    reg [5:0]  rom_addr;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            update_count <= 32'd0;
            rom_addr     <= 6'd0;
        end
        else if (update_count >= update_cycles - 32'd1) begin
            update_count <= 32'd0;

            // 循环读取12条数据：0、1、...、11、0
            if (rom_addr == 6'd11)
                rom_addr <= 6'd0;
            else
                rom_addr <= rom_addr + 6'd1;
        end
        else begin
            update_count <= update_count + 32'd1;
        end
    end

    // =================================================
    // 2. ROM电路：根据地址提供数据
    //
    // IP配置必须为：
    // 深度64，位宽32，ROM，输入输出直通
    // =================================================

    wire [31:0] instr;

    dist_mem_gen_0 U_IM (
        .a   (rom_addr),
        .spo (instr)
    );

    // =================================================
    // 3. 选择显示内容
    //
    // SW14 = 1：显示ROM中的数据
    // SW14 = 0：显示00000000
    // =================================================

    wire [31:0] display_data;

    assign display_data =
        sw_i[14] ? instr : 32'h00000000;

    // =================================================
    // 4. 显示电路
    //
    // 本讲实现数字模式：
    // SW0 = 0：显示十六进制数字
    // SW0 = 1：关闭显示
    // =================================================

    seg7x16 u_seg7x16 (
        .clk       (clk),
        .rstn      (rstn),
        .i_data    (display_data),
        .disp_mode (sw_i[0]),
        .o_seg     (disp_seg_o),
        .o_sel     (disp_an_o)
    );

endmodule
   
