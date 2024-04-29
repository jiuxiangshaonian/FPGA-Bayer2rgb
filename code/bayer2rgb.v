`timescale 1ns / 1ps
//输入的是拓展两行后的图像
module bayer2rgb#(   
    parameter           DISP_WIDTH = 402,
    parameter           DISP_HIGHT = 402
)(
    input               clk,
    input               rst_n,
    
    input               frame_vsync,
    input               data_in_valid,
    input  [7:0]        data_in,
    
    output              data_out_valid,
    output [23:0]       data_out
    );


reg  [9:0] wr_addr;
reg  [9:0] rd_addr;
wire [9:0] rd_addr_pre2;

assign rd_addr_pre2 = wr_addr + 11'd2;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_addr <= 10'd0;
        rd_addr <= 10'd0;
    end
    else if(data_in_valid)begin
        if(wr_addr == DISP_WIDTH - 1)
            wr_addr <= 10'd0;
        else
            wr_addr <= wr_addr + 1'b1;
        if(rd_addr_pre2 > DISP_WIDTH - 1)
            rd_addr <= rd_addr_pre2 - DISP_WIDTH;
        else
            rd_addr <= rd_addr_pre2;
    end
    else begin
        wr_addr <= wr_addr;
        rd_addr <= rd_addr;
    end
end

wire [7:0] window_in [0:1];
wire [7:0] window_out[0:1];

gray_linebuffer u0_gauss_linebuffer(
    .clka           (clk            ), // input wire clka
    .wea            (data_in_valid  ), // input wire [0 : 0] wea
    .addra          (wr_addr        ), // input wire [9 : 0] addra
    .dina           (window_in[0]   ), // input wire [7 : 0] dina

    .clkb           (clk            ), // input wire clkb
    .addrb          (rd_addr        ), // input wire [9 : 0] addrb
    .doutb          (window_out[0]  )  // output wire [7 : 0] doutb
);

gray_linebuffer u1_gauss_linebuffer(
    .clka           (clk            ), // input wire clka
    .wea            (data_in_valid  ), // input wire [0 : 0] wea
    .addra          (wr_addr        ), // input wire [9 : 0] addra
    .dina           (window_in[1]   ), // input wire [7 : 0] dina

    .clkb           (clk            ), // input wire clkb
    .addrb          (rd_addr        ), // input wire [9 : 0] addrb
    .doutb          (window_out[1]  )  // output wire [7 : 0] doutb
);

// genvar k;
// generate
//     for(k=0;k<2;k=k+1)begin
//         gray_linebuffer gauss_linebuffer_inst0(
//             .clka           (clk            ), // input wire clka
//             .wea            (data_in_valid  ), // input wire [0 : 0] wea
//             .addra          (wr_addr        ), // input wire [9 : 0] addra
//             .dina           (window_in[k]   ), // input wire [7 : 0] dina

//             .clkb           (clk            ), // input wire clkb
//             .addrb          (rd_addr        ), // input wire [9 : 0] addrb
//             .doutb          (window_out[k]  )  // output wire [7 : 0] doutb
//         );
//     end
// endgenerate

assign window_in[0] = data_in;
assign window_in[1] = window_out[0];

reg  [7:0] window[2:0][2:0];
integer i,j;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<3;i=i+1)begin
            window[0][i] <= 8'd0;
        end
    end 
    else begin
        window[0][0] <= window_in[0];
        for(i=1;i<3;i=i+1)begin
            window[0][i] <= window[0][i-1];
        end
    end
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<3;i=i+1)begin
            window[1][i] <= 8'd0;
        end
    end 
    else begin
        window[1][0] <= window_in[1];
        for(i=1;i<3;i=i+1)begin
            window[1][i] <= window[1][i-1];
        end
    end
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<3;i=i+1)begin
            window[2][i] <= 8'd0;
        end
    end 
    else begin
        window[2][0] <= window_out[1];
        for(i=1;i<3;i=i+1)begin
            window[2][i] <= window[2][i-1];
        end
    end
end

//分辨奇偶行与列
reg  [9:0] x_cnt;
reg  [9:0] y_cnt;
reg  [3:0] data_in_valid_t;
reg  frame_vsync_d1;
wire frame_p;

assign frame_p = (~frame_vsync_d1) && frame_vsync;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        frame_vsync_d1 <= 1'b0;
    else 
        frame_vsync_d1 <= frame_vsync;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n || frame_p)
        x_cnt <= 10'd0;
    else if(data_in_valid_t[2])begin
        if(x_cnt == DISP_WIDTH - 1)
            x_cnt <= 10'd0;
        else
            x_cnt <= x_cnt + 1'b1;
    end
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n || frame_p)
        y_cnt <= 11'd1;
    else if(x_cnt == DISP_WIDTH - 1)begin
        if(y_cnt == DISP_HIGHT)
            y_cnt <= 11'd1;
        else 
            y_cnt <= y_cnt + 1'b1;
    end  
    else 
        y_cnt <= y_cnt;
end

reg  [7:0] r_inter;
reg  [7:0] g_inter;
reg  [7:0] b_inter;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        r_inter <= 8'd0;
        g_inter <= 8'd0;
        b_inter <= 8'd0;
    end
    else if(y_cnt[0] == 0 && x_cnt[0] == 0)begin    //行偶列偶
        r_inter <= window[1][1];
        g_inter <= (window[0][1] + window[1][0] + window[1][2] + window[2][1]) / 4;
        b_inter <= (window[0][0] + window[0][2] + window[2][0] + window[2][2]) / 4; 
    end
    else if(y_cnt[0] == 0 && x_cnt[0] == 1)begin    //行偶奇列
        r_inter <= (window[1][0] + window[1][2]) / 2;
        g_inter <= window[1][1];
        b_inter <= (window[0][1] + window[2][1]) / 2;
    end
    else if(y_cnt[0] == 1 && x_cnt[0] == 0)begin    //行奇列偶
        r_inter <= (window[0][1] + window[2][1]) / 2;
        g_inter <= window[1][1];
        b_inter <= (window[1][0] + window[1][2]) / 2;
    end
    else if(y_cnt[0] == 1 && x_cnt[0] == 1)begin    //行奇列奇
        r_inter <= (window[0][0] + window[0][2] + window[2][0] + window[2][2]) / 4;
        g_inter <= (window[0][1] + window[1][0] + window[1][2] + window[2][1]) / 4;
        b_inter <= window[1][1];
    end
    else begin
        r_inter <= r_inter;   
        g_inter <= g_inter;
        b_inter <= b_inter;
    end
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_in_valid_t <= 4'b0;
    else 
        data_in_valid_t <= {data_in_valid_t[2:0],data_in_valid};
end


assign data_out_valid = data_in_valid_t[3] && (x_cnt != 0 && x_cnt != DISP_WIDTH - 1) && y_cnt > 2;
assign data_out       = {r_inter,g_inter,b_inter};

endmodule
