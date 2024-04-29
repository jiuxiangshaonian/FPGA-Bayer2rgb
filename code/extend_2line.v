`timescale 1ns / 1ps
//图像边界填充两行两列
module extend_2line #(
    parameter           DISP_WIDTH = 640,
    parameter           DISP_HIGHT = 480
)(
    input               clk,
    input               rst_n,

    input               frame_vsync,
    input               data_in_valid,
    input  [7:0]        data_in,

    output              data_out_valid,
    output [7:0]        data_out
    );

reg  [9:0]  x_cnt;
reg  [9:0]  y_cnt;
reg  [9:0]  y_cnt_d1;
reg  [9:0]  wr_addr;
wire [7:0]  rd_data;
reg  [15:0] data_in_valid_t;
reg  [7:0]  data_in_d1;
reg  [15:0] new_line_valid_t;
wire        new_line_start;
wire        new_line_valid;
wire        new_2line_start;
wire        new_2line_valid;
wire        data_in_valid_p;
wire [7:0]  add2row_data;    //增加两行后的数据
reg         add2row_data_valid;
reg         add2row_data_valid_d1;
reg         add2row_data_valid_d2;
wire        add2row_data_valid_p;
wire        add2row_data_valid_d1_n;
wire        add2col_data_valid;    //增加2列后的数据有效
reg  [7:0]  add2col_data;
reg         add2col_data_valid_d1;
reg  [7:0]  add2row_data_d1;
reg  [7:0]  add2row_data_d2;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        y_cnt_d1                <= 10'd0;
        data_in_valid_t         <= 16'd0;
        new_line_valid_t        <= 16'd0;
        data_in_d1              <= 8'd0;
        add2row_data_d1         <= 8'd0;
        add2row_data_d2         <= 8'd0;
        add2row_data_valid_d1   <= 1'b0;
        add2row_data_valid_d2   <= 1'b0;
        add2col_data_valid_d1   <= 1'b0;
    end
    else begin
        data_in_d1              <= data_in;
        add2row_data_d1         <= add2row_data;
        add2row_data_d2         <= add2row_data_d1;
        add2row_data_valid_d1   <= add2row_data_valid;
        add2row_data_valid_d2   <= add2row_data_valid_d1;
        add2col_data_valid_d1   <= add2col_data_valid;
        y_cnt_d1                <= y_cnt;
        data_in_valid_t         <= {data_in_valid_t[14:0],data_in_valid};
        new_line_valid_t        <= {new_line_valid_t[14:0],new_line_valid};
    end
end

assign data_in_valid_p          = (~data_in_valid_t[0]) && data_in_valid;
assign new_line_start           = (~data_in_valid_t[14]) && data_in_valid_t[15] && y_cnt >= DISP_HIGHT;
assign new_line_valid           = new_line_start || (x_cnt != 0 && y_cnt == DISP_HIGHT);
assign new_2line_start          = (~new_line_valid_t[14]) && new_line_valid_t[15] && y_cnt >= DISP_HIGHT;
assign new_2line_valid          = new_2line_start || (x_cnt != 0 && y_cnt == DISP_HIGHT + 1);
assign add2row_data             = y_cnt_d1 == 0 ? data_in_d1 : rd_data;
assign add2row_data_valid_p     = (~add2row_data_valid_d1) && add2row_data_valid;
assign add2row_data_valid_d1_n  = (~add2row_data_valid_d1) && add2row_data_valid_d2;
assign add2col_data_valid       = add2row_data_valid_p || add2row_data_valid_d1_n || add2row_data_valid_d1;
assign data_out_valid           = add2col_data_valid_d1;
assign data_out                 = add2col_data;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n || ~frame_vsync)
        x_cnt <= 10'd0;
    else if(x_cnt == DISP_WIDTH - 1)
        x_cnt <= 10'd0;
    else if(data_in_valid_p || new_line_start || new_2line_start || x_cnt != 0)
        x_cnt <= x_cnt + 1'b1;
    else
        x_cnt <= x_cnt;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n || ~frame_vsync)
        y_cnt <= 11'd0;
    else if(x_cnt == DISP_WIDTH - 1)begin
        if(y_cnt == DISP_HIGHT + 1)
            y_cnt <= 11'd0;
        else 
            y_cnt <= y_cnt + 1'b1;
    end  
    else 
        y_cnt <= y_cnt;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        wr_addr <= 10'd0;
    else if(wr_addr == DISP_WIDTH - 1)
        wr_addr <= 10'd0;
    else if(data_in_valid_t[0])
        wr_addr <= wr_addr + 1'b1;
    else    
        wr_addr <= wr_addr;
end

gray_linebuffer delay_line(
    .clka               (clk),    // input wire clka
    .wea                (data_in_valid_t[0]),      // input wire [0 : 0] wea
    .addra              (wr_addr),  // input wire [9 : 0] addra
    .dina               (data_in_d1),    // input wire [7 : 0] dina

    .clkb               (clk),    // input wire clkb
    .addrb              (x_cnt),  // input wire [9 : 0] addrb
    .doutb              (rd_data)  // output wire [7 : 0] doutb
);

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        add2row_data_valid <= 1'b0;
    else if(data_in_valid || new_2line_valid || new_line_valid)
        add2row_data_valid <= 1'b1;
    else
        add2row_data_valid <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        add2col_data <= 8'd0;
    else if(add2row_data_valid_p)
        add2col_data <= add2row_data;
    else if(add2row_data_valid_d1_n)
        add2col_data <= add2row_data_d2;
    else
        add2col_data <= add2row_data_d1;
end

endmodule
