`timescale 1ns / 1ps
module demosaic  #(
    parameter           DISP_WIDTH = 640,
    parameter           DISP_HIGHT = 480
)(
    input               clk,
    input               rst_n,
    
    input               cam_vsync,
    input               data_in_valid,
    input  [7:0]        data_in,
    
    output              frame_vsync,
    output              data_out_valid,
    output [23:0]       data_out
    );


wire extend_data_valid;
wire [7:0] extend_data;

frame_vsync frame_vsync_inst0(
    .clk                (clk                ),
    .rst_n              (rst_n              ),

    .cam_vsync          (cam_vsync          ),
    .frame_vsync        (frame_vsync        )
    );

extend_2line #(
    .DISP_WIDTH         (DISP_WIDTH         ),
    .DISP_HIGHT         (DISP_HIGHT         )
)extend_2line(
    .clk                (clk                ),
    .rst_n              (rst_n              ),

    .frame_vsync        (frame_vsync        ),
    .data_in_valid      (data_in_valid      ),
    .data_in            (data_in            ),

    .data_out_valid     (extend_data_valid  ),
    .data_out           (extend_data        )
    );

bayer2rgb#(
    .DISP_WIDTH         (DISP_WIDTH + 2     ),
    .DISP_HIGHT         (DISP_HIGHT + 2     )
)bayer2rgb(
    .clk                (clk                ),
    .rst_n              (rst_n              ),

    .frame_vsync        (frame_vsync        ),
    .data_in_valid      (extend_data_valid  ),
    .data_in            (extend_data        ),

    .data_out_valid     (data_out_valid     ),
    .data_out           (data_out)
    );
    
endmodule
