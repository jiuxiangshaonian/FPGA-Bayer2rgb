`timescale 1ns / 1ps
module frame_vsync(
    input               clk,
    input               rst_n,

    input               cam_vsync,
    output              frame_vsync
    );


//cam_vsync���½�����cam_href�����һ���½��ػ���û�м��,��������ʱ��Խ�絽�ڶ�֡��vsync��,������Ҫ��vsync���½������������ӳ�
//cam_vsync ����������������������������������������������������������������������������������|______________|��������������
//cam_href  _______________________|��������������|____|��������������|____|��������������|____________________________

reg  [10:0] n_delay_cnt;
reg         n_delay_valid; //��ӵ�vsync�½��غ���Ч�ڼ�
reg  [10:0] p_delay_cnt;
reg         p_delay_valid; //vsync�������ӳ�
reg         cam_vsync_d1;
wire        cam_vsync_p;
wire        cam_vsync_n;

assign cam_vsync_n = (~cam_vsync) && cam_vsync_d1;
assign cam_vsync_p = (~cam_vsync_d1) && cam_vsync;
assign frame_vsync = (cam_vsync && ~p_delay_valid) || cam_vsync_n || n_delay_valid;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cam_vsync_d1 <= 1'b0;
    else 
        cam_vsync_d1 <= cam_vsync;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        p_delay_cnt <= 11'd0;
    else if(p_delay_cnt == 11'd1023)
        p_delay_cnt <= 11'd0;
    else if(p_delay_cnt != 11'd0 || cam_vsync_p)
        p_delay_cnt <= p_delay_cnt + 1'b1;
    else
        p_delay_cnt <= p_delay_cnt;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        p_delay_valid <= 1'b0;
    else if(p_delay_cnt == 11'd1023)
        p_delay_valid <= 1'b0;
    else if(cam_vsync_p)
        p_delay_valid <= 1'b1;
    else 
        p_delay_valid <= p_delay_valid;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        n_delay_valid <= 1'b0;
    else if(n_delay_cnt == 1023) //�ӳ�1023������
        n_delay_valid <= 1'b0;
    else if(cam_vsync_n)
        n_delay_valid <= 1'b1;
    else
        n_delay_valid <= n_delay_valid;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        n_delay_cnt <= 11'd0;
    else if(n_delay_cnt == 11'd1023)
        n_delay_cnt <= 11'd0;
    else if(n_delay_cnt != 11'd0 || cam_vsync_n)
        n_delay_cnt <= n_delay_cnt + 1'b1;
    else    
        n_delay_cnt <= n_delay_cnt;
end

endmodule
