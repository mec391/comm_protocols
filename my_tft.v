//set clk to 25 - 50 MHz

//active area: width = 800, height = 480

//per frame:
//toggle VS low for 3*928 clock cycles, then wait 29*928 clock cycles (blanking),
// then wait 480*928 clock cycles (data runs), 
//then wait 13*928 clock cycles (front porch)
//repeat

//per row (during 'data runs'):
//toggle HS low for 48 clk cycles, then wait 40 clock cycles (blanking)
//toggle DE high and send data on each clock cycle for 800 clock cycles
// toggle DE low and wait 40 clock cycles (front porch)
//repeat

`timescale 1ns/1ns
module my_tft_TB();
	reg i_clk;
	reg i_rst_n;

	wire o_tft_clk;
	wire o_HS;
	wire o_VS;
	wire o_DE;
	wire [7:0] o_Red;
	wire [7:0] o_Blue;
	wire [7:0] o_Green;

	reg [7:0] i_Red;
	reg [7:0] i_Blue;
	reg [7:0] i_Green;
	wire [15:0] o_row_pixel;
	wire [15:0] o_col_pixel;

my_tft UUT(
.i_clk (i_clk),
.i_rst_n (i_rst_n),
.o_tft_clk (o_tft_clk),
.o_HS (o_HS),
.o_VS (o_VS),
.o_DE (o_DE),
.o_Red (o_Red),
.o_Green (o_Green),
.o_Blue (o_Blue),
.i_Red (i_Red),
.i_Blue (i_Blue),
.i_Green (i_Green),
.o_row_pixel (o_row_pixel),
.o_col_pixel (o_col_pixel)

	);

initial begin
i_clk = 1;
i_rst_n = 1;

end

always begin
#1 i_clk = !i_clk;
end

endmodule

module my_tft(
input i_clk,
input i_rst_n,

//data out to TFT
output  o_tft_clk,
output reg o_HS,
output reg o_VS,
output o_DE, //also route to Data Module 
output reg [7:0] o_Red,
output reg [7:0] o_Blue,
output reg [7:0] o_Green,


//data IO from a Data Module -- should have something with RAM to store an entire frame of data
input [7:0] i_Red,
input [7:0] i_Blue,
input [7:0] i_Green,
output reg [15:0] o_row_pixel = 0,
output reg [15:0] o_col_pixel = 0
	);

assign o_tft_clk = i_clk; //set tft clk to FPGA clk freq. for now

reg [23:0] r_vs_cnt = 0;
reg r_vs_blank;
reg r_vs_front_porch;

always@(posedge o_tft_clk) //control the VS toggle/blank/porch
begin
if (r_vs_cnt == 24'd487200) r_vs_cnt <= 0;
else r_vs_cnt <= r_vs_cnt + 1;

if (r_vs_cnt == 0) begin 
	o_VS <= 0; 
	r_vs_blank <= 0; 
	r_vs_front_porch <= 1; end
if (r_vs_cnt == 24'd2784) o_VS <= 1;
if(r_vs_cnt == 24'd29696) r_vs_blank <= 1;
if(r_vs_cnt == 24'd475136) r_vs_front_porch <= 0;
end

reg [23:0] r_hs_cnt = 0;
reg r_hs_blank;
reg r_hs_front_porch;
always@(posedge o_tft_clk) //control the HS toggle/blank/porch
begin
if (r_hs_cnt == 24'd928) r_hs_cnt <= 0;
else r_hs_cnt <= r_hs_cnt + 1;

if(r_hs_cnt == 0)begin
o_HS <= 0;
r_hs_blank <= 0;
r_hs_front_porch <= 1; end
if(r_hs_cnt == 24'd48) o_HS <= 1;
if(r_hs_cnt == 24'd88) r_hs_blank <= 1;
if(r_hs_cnt == 24'd888) r_hs_front_porch <= 0;
end

assign o_DE = (o_VS && r_vs_blank && r_vs_front_porch && o_HS && r_hs_blank && r_hs_front_porch);
//need all blanks, porches and syncs hi for DE to toggle hi
//always@(posedge o_tft_clk) 
//o_DE <= (o_VS && r_vs_blank && r_vs_front_porch && o_HS && r_hs_blank && r_hs_front_porch)
//endmodule

always@(posedge o_tft_clk) //send a row of data from data module
begin
if(o_DE) begin
o_Green <= i_Green;
o_Red <= i_Red;
o_Blue <= i_Blue;
o_col_pixel <= o_col_pixel +1;
end
else begin
o_Green <= o_Green;
o_Red <= o_Red;
o_Blue <= o_Blue;
o_col_pixel <= 0;
end
end

always@(posedge o_tft_clk) //keep track of what row we are on
begin
if (o_row_pixel == 479)
o_row_pixel <= 0;
else if(o_col_pixel == 799)
o_row_pixel <= o_row_pixel +1;
else o_row_pixel <= o_row_pixel;
end

endmodule