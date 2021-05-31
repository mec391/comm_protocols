`timescale 1ns/1ns
module my_spi_TB();
	reg i_clk;
	reg i_rst_n;
	reg i_miso;
	wire o_mosi;
	wire o_sclk; //62.5ns min -- 16MHz min
	wire o_cs_n;

	reg [7:0] i_addr;
	reg [23:0] i_wr_data;
	reg i_rd_wr; //1 for read perform, 0 for write perform

	reg i_DV;
	wire o_done;
	wire [23:0] o_rd_data;

	wire [3:0] r_SM = UUT.r_SM;

my_spi UUT(
.i_clk (i_clk),
.i_rst_n(i_rst_n),
.i_miso(i_miso),
.o_mosi(o_mosi),
.o_sclk(o_sclk),
.o_cs_n(o_cs_n),
.i_addr(i_addr),
.i_wr_data(i_wr_data),
.i_rd_wr(i_rd_wr),
.i_DV(i_DV),
.o_done(o_done),
.o_rd_data(o_rd_data)
	);

initial begin
i_clk = 1;
i_rst_n = 1;
i_DV = 0;
i_addr = 0;
i_wr_data = 0;
i_rd_wr = 0;
i_miso = 0;
#2 i_addr = 8'b10101010; i_wr_data = 24'b10101010_00001111_010101010; i_rd_wr = 0; i_DV <= 1; //perform a write

#160 i_addr = 8'b00001111; i_miso <= 8'b10101111; i_rd_wr = 1;  //perform a read off mosi

end

always begin
#1 i_clk = !i_clk;
end

endmodule



module my_spi( // custom designed SPI for the AFE4490
	input i_clk,
	input i_rst_n,
	input i_miso,
	output reg o_mosi,
	output reg o_sclk, //62.5ns min -- 16MHz min
	output reg o_cs_n,

	input [7:0] i_addr,
	input [23:0] i_wr_data,
	input i_rd_wr, //1 for read perform, 0 for write perform

	input i_DV,
	output reg o_done,
	output reg [23:0] o_rd_data
);
reg [7:0] r_addr = 0;
reg [24:0] r_data = 0;
reg [4:0] cnt = 8;
reg [3:0] r_SM = 0;

always@(posedge i_clk)
begin
case(r_SM) //idle
0:begin
o_done <= 0;
cnt <= 8;
o_cs_n <= 1;
o_mosi <= 1;
o_sclk <= 0; //try keeping sclk low on idle
if(i_DV) begin r_SM <= 1;  r_addr <= i_addr; r_data <= i_wr_data; end
else r_SM <= 0;
end
1:begin //toggle cs low
o_cs_n <= 0;
o_sclk <= 0;
r_SM <= 2;
end
2:begin //toggle clock and send addr bit
if(cnt == 0) begin
	cnt <= 24;
	o_sclk <= 0;
	if(i_rd_wr) r_SM <= 4; //go to read SM
	else begin r_SM <= 6; o_mosi <= r_data[23]; end //go to write SM
	end
else begin
o_mosi <= r_addr[7];
o_sclk <= 0;
r_SM <= 3;
end
end
3: begin //toggle clock and shift data
cnt <= cnt - 1;
r_addr <= r_addr << 1;
o_sclk <= 1;
r_SM <= 2;
end
4:begin //read SM -- toggle hi and shift in data
if(cnt == 0) begin
cnt <= 8;
o_sclk <= 0;
o_done <= 1;
r_SM <= 0;
end
else begin
o_sclk <= 1;
o_rd_data[0] <= i_miso;
r_SM <= 5;
end
end
5:begin //read SM -- shift data and toggle lo 
o_rd_data <= o_rd_data << 1;
cnt <= cnt - 1;
o_sclk <= 0;
end
6:begin //write SM -- shift data and toggle hi
cnt <= cnt - 1;
r_data <= r_data << 1;
o_sclk <= 1;
r_SM <= 7;
end
7:begin //write SM -- write data and toggle lo
if(cnt == 0) begin
cnt <= 8;
r_SM <= 0;
o_done <= 1;
o_sclk <= 0;
end
else begin
o_sclk <= 0;
o_mosi <= r_data[23];
r_SM <= 6;
end
end
endcase 
end


endmodule