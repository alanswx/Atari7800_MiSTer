`timescale 1ns / 1ps
/** Line buffer to VGA Interface
*
*  input lbuffer is the line buffer.
*  For column c, 0 <= c < 640, where 0 is left and 639 is right,
*  lbuffer[c][0] is RED, where 4'hF is the most intense red and
*  4'h0 is the least intense red.
*  lbuffer[c][1] is GREEN and lbuffer[c][2] is BLUE.
*
*  output line_number indicates the current row, where the top
*  of the screen is 0 and 479 is the bottom of the screen. Other
*  values indicate that no line is currently being drawn.
*
*  clk should be hooked up to a 25MHz clock (or 25.175 if available.)
*  reset should be hooked up to system reset.
*  RED, GREEN, BLUE, HSync, and VSync should be hooked up to the
*  appropriate VGA pins.
**/

module uv_to_vga (
	input logic        clk, reset,
	input logic [7:0]  uv_in,

	output logic [9:0] row, col,
	output logic [3:0] RED, GREEN, BLUE,
	output logic       HSync, VSync,	
	output logic       hblank, vblank;
);

logic col_clear, row_clear;
logic col_enable, row_enable;

logic [9:0] hsync_start, hsync_end, hblank_start, hblank_end;
logic [9:0] vsync_start, vsync_end, vblank_start, vblank_end;
logic [9:0] row_clear_t, row_enable_t;
logic visible;

assign vsync_start  = 10'd490;
assign vsync_end    = 10'd491
assign vblank_start = 10'd480;
assign vblank_end   = 10'd0;

assign hsync_start  = 10'd656;
assign hsync_end    = 10'd751;
assign hblank_start = 10'd640;
assign hblank_end   = 10'd0;

assign row_clear_t  = 10'd524;
assign row_enable_t = 10'd799;

// Row counter counts from 0 to 520
//     count of   0 - 479 is display time (row == line_number here)
//     count of 480 - 489 is front porch
//     count of 490 - 491 is VS=0 pulse width
//     count of 492 - 525 is back porch

always @(posedge clk, posedge reset)
	if (reset) begin
		row <= 10'd519; // ?
	end else if (row_clear)
		row <= 10'd0;
	else 
		row <= row + row_enable;

assign row_clear  = (row == row_clear_t) & row_enable;
assign row_enable = (col == row_enable_t);
assign VSync      = (row < vsync_start) | (row > vsync_end); // inverted
assign vblank = ((row < vblank_end) & (row > vblank_start));

// Col counter counts from 0 to 799
//     count of   0 - 639 is display time
//     count of 640 - 655 is front porch
//     count of 656 - 751 is HS=0 pulse width
//     count of 752 - 799 is back porch

always @(posedge clk or posedge reset)
	if (reset)
		col <= 10'd0;
	else if(col_clear)
		col <= 10'd0;
	else
		col <= col + col_enable;

assign col_clear  = row_enable;
assign col_enable = 1'b1;
assign HSync      = (col < hsync_start) | (col > hsync_end); // inverted
assign hblank = ((col < hblank_end) & (col > hblank_start));

assign visible =  ~(vblank | hblank);

// Chrominance-Luminance palettes (represented as rgb)
logic [255:0][3:0]  red_palette, green_palette, blue_palette;

logic [3:0] rbuf, gbuf, bbuf;
logic [7:0] uv;

assign uv = uv_in;

assign RED = rbuf;
assign GREEN = gbuf;
assign BLUE = bbuf;

// UV Palette data found at: http://atariage.com/forums/topic/209210-complete-ntsc-pal-color-palettes/
// These three assign statements generated by Atari7800/palettes.py
assign red_palette = {4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0};
assign rbuf = red_palette[uv];

assign green_palette = {4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h1, 4'h0, 4'h0, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h1, 4'h0, 4'h0, 4'h0, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h0, 4'h0, 4'h0, 4'h0, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'he, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0};
assign gbuf = green_palette[uv];

assign blue_palette = {4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'ha, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'hf, 4'hf, 4'hf, 4'hf, 4'hd, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h4, 4'h3, 4'h2, 4'h1, 4'hf, 4'he, 4'hc, 4'hb, 4'ha, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'hb, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'ha, 4'h9, 4'h8, 4'h7, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hf, 4'hf, 4'he, 4'hd, 4'hc, 4'hb, 4'ha, 4'h8, 4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0};
assign bbuf = blue_palette[uv];

endmodule
