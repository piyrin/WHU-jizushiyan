`timescale 1ns / 1ps

module SCPU_TOP #(
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

module seg7x16 (
    input  wire        clk,
    input  wire        rstn,
    input  wire [31:0] i_data,
    input  wire        disp_mode,

    output wire [7:0]  o_seg,
    output wire [7:0]  o_sel
);

    // =================================================
    // 1. 扫描计数
    //
    // 低15位负责每个位置的显示时间
    // 高3位负责选择8个位置中的一个
    // =================================================

    reg [17:0] scan_count;

    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            scan_count <= 18'd0;
        else
            scan_count <= scan_count + 18'd1;
    end

    wire [2:0] digit_sel;

    assign digit_sel = scan_count[17:15];

    // =================================================
    // 2. 从32位数据中取出当前位置的4位数字
    //
    // 最右边显示最低4位
    // 最左边显示最高4位
    // =================================================

    reg [3:0] digit_data;

    always @(*) begin
        case (digit_sel)
            3'd0: digit_data = i_data[3:0];
            3'd1: digit_data = i_data[7:4];
            3'd2: digit_data = i_data[11:8];
            3'd3: digit_data = i_data[15:12];
            3'd4: digit_data = i_data[19:16];
            3'd5: digit_data = i_data[23:20];
            3'd6: digit_data = i_data[27:24];
            3'd7: digit_data = i_data[31:28];
            default: digit_data = 4'h0;
        endcase
    end

    // =================================================
    // 3. 把0～F转换为段码
    // 最高位为1，表示小数点关闭
    // =================================================

    reg [7:0] seg_code;

    always @(*) begin
        case (digit_data)
            4'h0: seg_code = 8'hC0;
            4'h1: seg_code = 8'hF9;
            4'h2: seg_code = 8'hA4;
            4'h3: seg_code = 8'hB0;
            4'h4: seg_code = 8'h99;
            4'h5: seg_code = 8'h92;
            4'h6: seg_code = 8'h82;
            4'h7: seg_code = 8'hF8;
            4'h8: seg_code = 8'h80;
            4'h9: seg_code = 8'h90;
            4'hA: seg_code = 8'h88;
            4'hB: seg_code = 8'h83;
            4'hC: seg_code = 8'hC6;
            4'hD: seg_code = 8'hA1;
            4'hE: seg_code = 8'h86;
            4'hF: seg_code = 8'h8E;
            default: seg_code = 8'hFF;
        endcase
    end

    // =================================================
    // 4. 输出到数码管
    //
    // 每次切换位置后，先关闭约1微秒，
    // 再打开当前位，留出段码切换时间。
    // =================================================

    wire display_enable;

    assign display_enable =
        rstn &&
        !disp_mode &&
        (scan_count[14:0] >= 15'd100);

    assign o_sel = display_enable
                 ? ~(8'b00000001 << digit_sel)
                 : 8'hFF;

    assign o_seg = display_enable
                 ? seg_code
                 : 8'hFF;

endmodule