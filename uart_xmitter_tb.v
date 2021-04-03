`timescale 1ns/1ns
module uart_xmitter_tb();
parameter word_size = 8;
parameter full_cnt = 2**word_size - 1;
reg  i_clk;
reg  i_rst_n; 		   //route to pushbutton
reg  [7:0] i_data_in;   //route to switches
wire [7:0] o_data_in;  //route to LEDs
reg  i_data_DV; 	    //route to pushbutton

wire o_tx; 		//route to gpio
wire o_wait;  //route to LED
wire [3:0] debug;

uart_xmitter UUT(
.i_clk (i_clk),
.i_rst_n (i_rst_n),
.i_data_in (i_data_in),
.o_data_in (o_data_in),
.i_data_DV (i_data_DV),
.o_tx (o_tx),
.o_wait (o_wait),
.debug (debug)
	);

reg [word_size-1:0] r_counter;

initial begin
r_counter = 0;
i_clk = 1;
i_rst_n = 1;
i_data_in = 0;
i_data_DV = 0;

#2 i_rst_n = 0; //toggle reset
#4 i_rst_n = 1;

while(r_counter < full_cnt)
begin
if(o_wait)
begin #2 r_counter = r_counter; end

else begin
#2 i_data_DV = 1;
#2 i_data_DV = 0;
# 24;
r_counter = r_counter + 1;
i_data_in = i_data_in + 1;
end
end
end


always begin 
#1 i_clk = !i_clk;
end

endmodule