`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/04 18:39:00
// Design Name: 
// Module Name: basic1
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


module basic0(
input [8:0]sw_i,
output [4:0]led_o);
wire a,b,c,d,e,f,g,h,i;
  assign  a = sw_i[0];
  assign  b = sw_i[1];
  assign  c = sw_i[2];
  assign  d = sw_i[3];
  assign  e = sw_i[4];
  assign  f = sw_i[5];
  assign  g = sw_i[6];
  assign  h = sw_i[7];
  assign  i = sw_i[8];
    //构建5种基本门电路：
    //F1  = a&b。按位与，该符号代表按位与，是一种位运算符，对a和b对应的二进制值进行逐位比较。
    //注意&按位与和&&逻辑与是不同的，逻辑与是逻辑运算符，用于连接布尔表达式，在编程中更多是对条件是否为真的判断。
    //F2  = c|d。按位或，该符号代表按位或。同上。
    //F3  = ~e。按位非，该符号代表按位非。同上。
    //F4  = ~(f|g)。或非门
    //F5  = ~(h^i)。异或非门
  assign led_o[0] = a & b;    // 与门F1，为了代码实现更简洁，简化了F1赋值给led_o[0]的过程，直接把a与b的按位与结果，赋值给#1号的led_o[0]
  assign led_o[1] = c | d;    // 或门F2。同上。
  assign led_o[2] = ~e;       // 非门F3。同上。
  assign led_o[3] = ~(f | g); // 或非门F4。同上。
  assign led_o[4] = ~(h ^ i); // 同或门（异或非）F5。同上。

endmodule
