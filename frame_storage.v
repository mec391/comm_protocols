module frame_storage( 
//this module receives data from the the ALU, 
//determines what the frame should be, 
//and sends frames to the the TFT driver pixel by pixel
input i_clk,
input i_rst_n,

//data from ALU
input [23:0] i_hr,
input [23:0] i_spo2,
input [21:0] i_IR_raw,
input [21:0] i_red_raw,
input i_ALU_DV,

//data to TFT driver
input [15:0] i_row_pixel,
input [15:0] i_col_pixel,
output [7:0] o_Red,
output [7:0] o_Green,
output [7:0] o_Blue

);

//ram_data[23:16] = red, ram_data[15:8] = green, ram_data[7:0] = blue
reg [23:0] ram_data [0:479][0:799];
wire [23:0] output_ram_data;

//102 frames per second at 50 Mhz
//for now just cycle between R G and B
integer i = 0;
integer j = 0;
reg init_reg = 0;
reg [3:0] r_SM = 0;
reg [31:0] frame_cnt = 0;

reg [11:0] horiz_counter = 0;
reg [11:0] vert_counter = 0;
always@(posedge i_clk)
begin
if(horiz_counter == 799) horiz_counter <= 0;
else horiz_counter <= horiz_counter + 1;
if(vert_counter == 399) vert_counter <= 0;
else vert_counter <= vert_counter + 1;
ram_data[horiz_counter][vert_counter] <= 24'b11111111_00000000_00000000;
end

/*
always@(posedge i_clk)
begin
if(~init_reg) begin
for (i = 0; i < 480; i = i + 1)begin
for (j = 0; j < 800; j = j + 1)begin
ram_data[i][j] <= 24'b11111111_00000000_00000000;
end end
init_reg <= 1;
end
else begin
case(r_SM)
0: begin
if(frame_cnt == 50000000) begin
frame_cnt <= 0;
for (i = 0; i < 480; i = i + 1)begin
for (j = 0; j < 800; j = j + 1)begin
ram_data[i][j] <= 24'b00000000_11111111_00000000;
end end
r_SM <= 1;
end
else begin r_SM <= 0; frame_cnt <= frame_cnt + 1; end
end
1:begin
if(frame_cnt == 50000000) begin
frame_cnt <= 0;
for (i = 0; i < 480; i = i + 1)begin
for (j = 0; j < 800; j = j + 1)begin
ram_data[i][j] <= 24'b00000000_00000000_11111111;
end end
r_SM <= 2;
end
else begin r_SM <= 1; frame_cnt <= frame_cnt + 1; end
end
2:begin
if(frame_cnt == 50000000) begin
frame_cnt <= 0;
for (i = 0; i < 480; i = i + 1)begin
for (j = 0; j < 800; j = j + 1)begin
ram_data[i][j] <= 24'b11111111_00000000_00000000;
end end
r_SM <= 0;
end
else begin r_SM <= 2; frame_cnt <= frame_cnt + 1; end
end
endcase
end
end
*/

/*
//code for when raw data is coming into the system
//0 - 2,097,151 -> 240 - 479
//2,097,152 -> 4,194,303 -> 0-239
reg [11:0] ram_raw_IR [0:799];
reg [11:0] ram_raw_red [0:799];
reg [21:0] r_raw_IR_map;
reg [21:0] r_raw_red_map;
reg r_downsample = 0;
reg [11:0] r_addr_cnt = 0;
reg [3:0] r_raw_SM = 0;
always@(posedge i_clk) //store the raw signal 
begin
case(r_raw_SM)
0:begin
if(i_ALU_DV) begin
r_downsample <= ~r_downsample;
r_raw_SM <= 1;
end
else begin
r_downsample <= r_downsample;
r_raw_SM <= r_raw_SM;
end
end
1: begin //downsample from 500sps to 250 sps
if(r_downsample == 1)begin
r_raw_IR_map <= i_IR_raw;
r_raw_red_map <= i_red_raw;
r_raw_SM <= 2;
end
else begin
r_raw_IR_map <= r_raw_IR_map;
r_raw_red_map <= r_raw_red_map;
r_raw_SM <= 0;
end
2: begin //map from 22 bit to 8 bit value
ram_raw_IR[r_addr_cnt] <= r_raw_IR_map[20:13];
ram_raw_red[r_addr_cnt] <= r_raw_red_map[20:13];
r_raw_SM <= 3;
end
3: begin
if(ram_raw_IR[r_addr_cnt] > 239) ram_raw_IR[r_addr_cnt] <= 239;
if(ram_raw_red[r_addr_cnt] > 239) ram_raw_red[r_addr_cnt] <= 239; 
r_raw_SM <= 4;
end
4: begin
if(r_raw_IR_map[21] == 0) ram_raw_IR[r_addr_cnt] <= ram_raw_IR[r_addr_cnt] + 240;
if(r_raw_red_map[21] ==0) ram_raw_red[r_addr_cnt] <= ram_raw_red[r_addr_cnt] + 240;
if(r_addr_cnt == 799) r_addr_cnt <= 0;
else r_addr_cnt <= r_addr_cnt + 1;
r_raw_SM <= 5;
end
5: begin //update the values of the ram_data -- for now just use IR
for(i=0; i < 480; i = i+1)begin
for(j=0; j < 800; j = j+1)begin
if(ram_raw_IR[j] == i) ram_data[i][j] <= 24'b11111111_11111111_11111111;//set to white
else ram_data[i][j] <= 24'd0; //set to black
end
end
r_raw_SM <= 0;
end
endcase
end
*/

//assign the outputs R, G, B based on input pointers row_pixel and col_pixel
assign output_ram_data = ram_data[i_row_pixel][i_col_pixel];
assign o_Red = output_ram_data[23:16];
assign o_Green = output_ram_data[15:8];
assign o_Blue = output_ram_data[7:0];



endmodule