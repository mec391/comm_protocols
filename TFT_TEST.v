module TFT_TEST(
input i_clk,
input i_rst_n,

//to TFT
output  o_tft_clk,
output  o_HS,
output  o_VS,
output  o_DE, 
output  [7:0] o_Red,
output  [7:0] o_Blue,
output  [7:0] o_Green
);


wire [15:0] row_pixel;
wire [15:0] col_pixel;
wire [7:0] red;
wire [7:0] green;
wire [7:0] blue;

my_tft tft0(
.i_clk (i_clk),
.i_rst_n (i_rst_n),
.o_tft_clk (o_tft_clk),
.o_HS (o_HS),
.o_VS (o_VS),
.o_DE (o_DE),
.o_Red (o_Red),
.o_Green (o_Green),
.o_Blue (o_Blue),
.i_Red (red),
.i_Blue (blue),
.i_Green (green),
.o_row_pixel (row_pixel),
.o_col_pixel (col_pixel)
	);

frame_storage fs0(
.i_clk (i_clk),
.i_rst_n (i_rst_n),
.i_hr (24'd0),
.i_spo2 (24'd0),
.i_IR_raw (24'd0),
.i_red_raw (24'd0),
.i_ALU_DV (1'd0),
.i_row_pixel (row_pixel),
.i_col_pixel (col_pixel),
.o_Red (red),
.o_Green (green),
.o_Blue (blue)
	);


endmodule
