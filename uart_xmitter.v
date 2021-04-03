//simple UART transmitter for EE 417
//designed to take an input 8 bit value from DE1-SOC switches and a DV from a pushbutton and send on the TX line @ 115200baud given a 50mhz input clk
//if you have a USB to serial cable (FTDI cable), you can connect a terminal program (such as PUTTY), on the PC to the COMM port and view the 8 bit ascii equivalent values
//UART TX: 1 start bit, 1 stop bit, no parity bit, no flow control/RTS
module uart_xmitter(  
input  i_clk,	
input  i_rst_n, 		   //route to pushbutton -- active low press
input  [7:0] i_data_in,   //route to switches
output [7:0] o_data_in,  //route to LEDs
input  i_data_DV, 	    //route to pushbutton --active low press

output o_tx, 		//route to gpio
output reg o_wait, //route to LED
output [3:0] debug
	);
localparam IDLE = 0;
localparam TX_BEGIN = 1;
localparam TX_WAIT = 2;
assign o_data_in = i_data_in;

reg [3:0] SM;
assign debug = SM;
reg r_begin_tx;
wire w_uart_busy;

reg [23:0] r_debounce_cnt;
reg r_debounce_en;
reg [3:0] r_debounce_SM;
always@(posedge i_clk) //debouncing circuit, 200 ms before registering new data
begin
if(~i_rst_n)begin r_debounce_SM <= IDLE; r_debounce_en <= 1; end
else begin
case(r_debounce_SM)
IDLE:
if(~i_data_DV) begin r_debounce_SM <= TX_BEGIN; r_debounce_en <= 0; end
else begin r_debounce_SM <= r_debounce_SM; r_debounce_en <= 1; end
TX_BEGIN:
if(r_debounce_cnt == 24'd10000000) begin r_debounce_SM <= IDLE; r_debounce_en <= 1; r_debounce_cnt <= 0; end
else begin r_debounce_SM <= r_debounce_SM; r_debounce_en <= 0; r_debounce_cnt = r_debounce_cnt + 1; end
default: begin
r_debounce_SM <= IDLE; r_debounce_en <= 1; end
endcase
end
end

always@(posedge i_clk) //state machine for controlling the transmitter module (datapath)
begin
if(~i_rst_n) begin SM <= IDLE; r_begin_tx <= 0; o_wait <= 0; end
else
begin
r_begin_tx <= 0;
o_wait <= 0;
case (SM)
IDLE: //wait for new data to come in
begin
if((~i_data_DV) && (r_debounce_en)) begin r_begin_tx <= 1; SM <= TX_BEGIN; o_wait <= 1;end
else SM <= SM;
end
TX_BEGIN: //1 clk cycle delay for TX_busy to trigger from UART module
begin
SM <= TX_WAIT; o_wait <= 1; 
end
TX_WAIT: //wait for the transmission to finish
begin
if(w_uart_busy) begin SM <= SM; o_wait <= 1; end
else SM <= IDLE; 
end
default:
begin
SM <= IDLE;
r_begin_tx <= 0;
o_wait <= 0;
end
endcase
end
end

//instantiate the UART_TX module:
uart_tx ut0(
.i_clk (i_clk),
.i_rst_n (i_rst_n),
.i_data_in (i_data_in),
.i_begin_tx (r_begin_tx),
.o_uart_busy (w_uart_busy),
.o_tx (o_tx)
	);
endmodule

//line is high before xmission
//start bit toggles LO
//send 8 bits of my data
//stop bit toggles HI
module uart_tx(
input i_clk,
input i_rst_n,
input [7:0] i_data_in,
input i_begin_tx,

output reg o_uart_busy,
output reg o_tx
	);

wire w_clk_div;
reg [7:0] r_data;
reg [3:0] SM0;
reg [3:0] SM1;
reg r_begin_tx_cc;
reg [10:0] r_clk_cnt;
reg [7:0] r_data_cc;

localparam clk_div_cnt = 434;
localparam IDLE = 0;
localparam SEND = 1;
localparam WAIT = 2;
localparam STOP = 3;

always@(posedge i_clk) //reg data, handle clock domain crossing for transmitter (Controller)
begin
if(~i_rst_n) begin r_data <= 0; r_begin_tx_cc <= 0; o_uart_busy <= 0; SM0 <= IDLE; r_clk_cnt <= 0; end
else begin
case(SM0)
IDLE:
begin
if(i_begin_tx) begin r_data <= i_data_in; r_begin_tx_cc <= 1; SM0 <= SEND; o_uart_busy <= 1; end //reg data, handle busy signal, begin transmission
else begin r_data <= 0; r_begin_tx_cc <= 0; SM0 <= SM0; o_uart_busy <= 0; end
end
SEND: //hold DV for 434 clock cycles
begin
if (r_clk_cnt == clk_div_cnt) begin r_begin_tx_cc <= 0; SM0 <= WAIT; r_clk_cnt <= 0; end
else begin  r_begin_tx_cc <= 1; SM0 <= SM0; r_clk_cnt <= r_clk_cnt + 1; end
end
WAIT: //wait for the system to finish sending data
begin
if (SM1 == SEND) begin SM0 <= SM0; o_uart_busy <= 1; end
else begin SM0 <= IDLE; o_uart_busy <= 0; end
end
default:
begin
r_data <= 0; r_begin_tx_cc <= 0; o_uart_busy <= 0; SM0 <= IDLE; r_clk_cnt <= 0;
end
endcase
end
end

integer ii = 0;
reg [3:0] r_cnt_down = 4'd8;
always@(posedge w_clk_div) //send out data when a DV comes in at 115200 (datapath)
begin
if(~i_rst_n) begin o_tx <= 1; SM1 <= IDLE; r_data_cc <= 0; r_cnt_down <= 8'd8; end
else begin
case(SM1)
IDLE:
if(r_begin_tx_cc) begin SM1 <= SEND; o_tx <= 0; r_data_cc <= r_data; end //send the start bit
else SM1 <= SM1;
SEND: 
begin //send the data bits (lsb to msb)
if(r_cnt_down > 0) begin o_tx <= r_data_cc[0]; for (ii = 0; ii < 7; ii=ii+1) r_data_cc[ii] <= r_data_cc[ii+1]; r_cnt_down = r_cnt_down - 1; SM1 <= SM1; end
//send the stop bit
else begin o_tx <= 1; r_cnt_down <= 4'd8; SM1 <= IDLE; end
end
default:
begin
o_tx <= 1;
SM1 <= IDLE;
r_data_cc <= 0;
r_cnt_down <= 8'd8;
end
endcase
end
end

//instantiate the CLK_DIV module:
clk_div cd0(
.i_clk (i_clk),
.i_rst_n (i_rst_n),
.o_clk_div (w_clk_div)
);
endmodule

//get a clk running at 115200 baud for xmission
module clk_div(
input i_clk,
input i_rst_n,
output reg o_clk_div

	);
parameter divisor = 217; //50MHz / 115200 == 434; 434 / 2 == 217
reg [9:0] r_cnt;

always@(posedge i_clk)
begin
if(~i_rst_n) begin o_clk_div <= 0; r_cnt <= 0; end
else 
if(r_cnt == divisor) begin o_clk_div <= ~o_clk_div; r_cnt <= 0; end
else begin o_clk_div <= o_clk_div; r_cnt <= r_cnt + 1; end
end
endmodule