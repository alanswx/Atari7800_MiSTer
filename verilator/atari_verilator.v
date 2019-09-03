//
// top end ff for verilator
//

//`define sdl_display
`define USE_VGA
//`define USE_CGA

module top(VGA_R,VGA_B,VGA_G,VGA_HS,VGA_VS,reset,clk_sys,clk_vid,ioctl_download,ioctl_addr,ioctl_dout,ioctl_index,ioctl_wait,ioctl_wr);

   input clk_sys/*verilator public_flat*/;
   input clk_vid/*verilator public_flat*/;
   input reset/*verilator public_flat*/;

   output [7:0] VGA_R/*verilator public_flat*/;
   output [7:0] VGA_G/*verilator public_flat*/;
   output [7:0] VGA_B/*verilator public_flat*/;
   
   output VGA_HS;
   output VGA_VS;
   
   input        ioctl_download;
   input        ioctl_wr;
   input [24:0] ioctl_addr;
   input [7:0] ioctl_dout;
   input [7:0]  ioctl_index;
   output  reg     ioctl_wait=1'b0;
   
   

   
   //-------------------------------------------------------------------

wire cart_download = ioctl_download & (ioctl_index != 8'd0);
wire bios_download = ioctl_download & (ioctl_index == 8'd0);


reg old_cart_download;
reg initial_pause = 1'b1;

always @(posedge clk_sys) begin
	old_cart_download <= cart_download;
	if (old_cart_download & ~cart_download) initial_pause <= 1'b0;
end

////////////////////////////  HPS I/O  //////////////////////////////////

wire  [1:0] buttons;
wire [31:0] status;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        ioctl_download;
wire [24:0] ioctl_addr;
wire [7:0] ioctl_dout;
wire        ioctl_wr;
wire [7:0]  ioctl_index;

wire [15:0] joy0,joy1;

/*
reg [7:0]RR=8'b0;
reg [7:0]GG=8'b0;
reg [7:0]BB=8'b11111111;
assign VGA_R=RR;
assign VGA_G=GG;
assign VGA_B=BB;
wire [7:0] VGA_R2;
wire [7:0] VGA_G2;
wire [7:0] VGA_B2;
always @(posedge clk_sys) begin
	$display("vga: %x %x %x", VGA_R,VGA_G,VGA_B);
end
*/

wire [3:0]RR;
wire [3:0]GG;
wire [3:0]BB;
assign VGA_R= {RR,RR};
assign VGA_G= {GG,GG};
assign VGA_B= {BB,BB};
Atari7800 main
(
	.sysclk_7_143 (clk_sys),
	.clock_25     (clk_vid),
	.reset        (reset),
	.locked       (1'b1/*clock_locked*/),
	.memclk_o     (clk_mem),
	.pclk_0       (pclk_0),
	.loading      (ioctl_download),

	// Video
	.RED          (RR),
	.GREEN        (GG),
	.BLUE         (BB),
	.HSync        (VGA_HS),
	.VSync        (VGA_VS),
	.HBlank       (HBlank),
	.VBlank       (VBlank),
	.ce_pix       (),

	// Audio
	.AUDIO        (AUDIO_R), // 16 bit

	// Cart Interface
	.cart_sel     (cart_sel),
	.cart_out     (cart_data),
	.cart_size    (cart_size),
	.cart_addr_out(cart_addr),
	.cart_flags   (cart_flags[9:0]),
	.cart_region  (cart_region[0]),

	// BIOS
	.bios_sel     (bios_sel),
	.bios_out     (bios_data),
	.AB           (bios_addr), // Address
	.RW           (), // inverted write

	// Debug
	.ld           (ld), // LED control

	// Tia
	.idump        (idump),  // Paddle {A0, B0, A1, B1}
	.ilatch       (ilatch), // Buttons {FireB, FireA}
	.tia_en       (tia_en),

	// RIOT
	.PAin         (PAin),  // Direction {RA, LA, DA, UA, RB, LB, DB, UB}
	.PBin         (PBin),  // Port B input
	.PAout        (PAout), // Port A output
	.PBout        (PBout)  // Peanut butter
);

wire [7:0] ld;
assign AUDIO_L = AUDIO_R;


////////////////////////////  MEMORY  ///////////////////////////////////

wire [16:0] bios_addr;
reg [7:0] cart_data, bios_data;
wire cart_sel, bios_sel;
wire clk_mem;
wire pclk_0;
reg [7:0] joy0_type, joy1_type, cart_region, cart_save;

logic [15:0] cart_flags;
logic [39:0] cart_header;
logic [31:0] hcart_size, cart_size;
logic [17:0] cart_addr;

wire cart_is_7800 = (cart_header == "ATARI");

always_ff @(posedge clk_sys) begin
	logic old_cart_download;
	logic [24:0] old_addr;

if (cart_download)
	$display("cart_download: writing x's %b @ %x", ioctl_dout, ioctl_addr);

	old_cart_download <= cart_download;
	if (old_cart_download & ~cart_download)
		cart_size <= (old_addr - (cart_is_7800 ? 8'd128 : 1'b0)) + 1; // 32 bit 1
	if (cart_download) begin
		old_addr <= ioctl_addr;
		case (ioctl_addr)
			'd01: cart_header[39:32] <= ioctl_dout;
			'd02: cart_header[31:24] <= ioctl_dout;
			'd03: cart_header[23:16] <= ioctl_dout;
			'd04: cart_header[15:8] <= ioctl_dout;
			'd05: cart_header[7:0] <= ioctl_dout;
			'd49: hcart_size[31:24] <= ioctl_dout; //This appears to be useless.
			'd50: hcart_size[23:16] <= ioctl_dout;
			'd51: hcart_size[15:8] <= ioctl_dout;
			'd52: hcart_size[7:0] <= ioctl_dout;
			'd53: cart_flags[15:8] <= ioctl_dout;
			'd54: cart_flags[7:0] <= ioctl_dout;
			'd55: joy0_type <= ioctl_dout;   // 0=none, 1=joystick, 2=lightgun
			'd56: joy1_type <= ioctl_dout;
			'd57: cart_region <= ioctl_dout; // 0=ntsc, 1=pal
			'd58: cart_save <= ioctl_dout;   // 0=none, 1=high score cart, 2=savekey
		endcase
	end
end

logic [17:0] cart_write_addr, fixed_addr;
assign cart_write_addr = (ioctl_addr >= 8'd128) && cart_is_7800 ? (ioctl_addr[17:0] - 8'd128) : ioctl_addr[17:0];

dpram_dc #(.widthad_a(18)) cart
(

	.address_a(cart_write_addr),
	.clock_a(clk_sys),
	.data_a(ioctl_dout),
	.wren_a(ioctl_wr & cart_download),
	.byteena_a(1'b1),

	.address_b(cart_addr),
	.clock_b(pclk_0),
	.byteena_b(~cart_download),
	.q_b(cart_data)

);

/*
always_ff @(posedge clk_mem) begin
if (bios_sel & ~bios_download)
	$display("bios: reading x's %b @ %x", bios_data, bios_addr[11:0]);
end
*/

always_ff @(posedge clk_sys) begin
if (ioctl_wr & bios_download)
	$display("wrbios: writing x's %b @ %x", ioctl_dout,ioctl_addr);
end

dpram_dc #(.widthad_a(12)) bios
(

	.address_a(ioctl_addr[11:0]),
	.clock_a(clk_sys),
	.data_a(ioctl_dout),
	.wren_a(ioctl_wr & bios_download),
	.byteena_a(1'b1),

	.address_b(bios_addr[11:0]),
	.clock_b(clk_mem),
	.byteena_b(bios_sel & ~bios_download),
	.q_b(bios_data)

);

//////////////////////////////  IO  /////////////////////////////////////

logic tia_en;
logic [3:0] idump;

logic [1:0] ilatch;
logic [7:0] PAin, PBin, PAout, PBout;

wire joya_b2 = ~PBout[2] & ~tia_en;
wire joyb_b2 = ~PBout[4] & ~tia_en;

logic [15:0] joya, joyb;
assign joya = status[7] ? joy1 : joy0;
assign joyb = status[7] ? joy0 : joy1;

// RIOT Ports:
// 4 bits of PA are used for first stick, other 4 bits for second stick.
// 2600: Bits PB 0,1,4,6,7 are used for reset, select, b/w, left diffculty, right diff
// 7800: Bits PB 0,1,3,6,7 are used for reset, select, pause, left diffculty, right diff
// 7800: Bits PB 2 & 4 are used for output to select 2 button mode.

//assign PBin[7] = status[13];              // Right diff
//assign PBin[6] = status[14];              // Left diff
assign PBin[5] = 1'b1;                     // Unused
assign PBin[4] = 1'b1;                     // 2600 B/W?
//assign PBin[3] = (~joya[6] & ~joyb[6]);    // Pause
assign PBin[2] = 1'b1;                     // Unused
//assign PBin[1] = (~joya[7] & ~joyb[7]);    // Select
//assign PBin[0] = (~joya[8] & ~joyb[8]);    // Start/Reset 

assign PBin[7] = 1'b1;
assign PBin[6] = 1'b1;
assign PBin[3] = 1'b1;
assign PBin[1] = 1'b1;
assign PBin[0] = 1'b1;

assign PAin[7:4] = {~joya[0], ~joya[1], ~joya[2], ~joya[3]}; // P1: R L D U or PA PB 1 1
assign PAin[3:0] = {~joyb[0], ~joyb[1], ~joyb[2], ~joyb[3]}; // P2: R L D U or PA PB 1 1

//assign ilatch[0] = ~joya[4]; // P1 Fire
//assign ilatch[1] = ~joyb[4]; // P2 Fire
assign ilatch[0] = 1'b1;
assign ilatch[1] = 1'b1;

wire pada_0 = joya_b2 ? joya[4] : joya[9];
wire pada_1 = joya_b2 ? joya[5] : joya[10];
wire padb_0 = joyb_b2 ? joyb[4] : joyb[9];
wire padb_1 = joyb_b2 ? joyb[5] : joyb[10];

assign idump = {padb_0, padb_1, pada_0, pada_1}; // // P2 F1, P2 F2, P1 F1, P1 F2 (or analog?)

////////////////////////////  VIDEO  ////////////////////////////////////

wire HBlank;
wire VBlank;
wire ce_pix = 1'b1;




   
endmodule // ff_cpu_test

