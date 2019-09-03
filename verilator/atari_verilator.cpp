//
// ff_verilator.cpp
//
//

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vatari_verilator.h"
#include "vga.h"

#include <iostream>

#ifdef COSIM
#include "cosim.h"
#endif

Vatari_verilator *top;                     	  // Instantiation of module
//Vatari_verilator_ff_verilator *topv;

//static unsigned long long main_time = 0;  // Current simulation time
static vluint64_t main_time = 0;  // Current simulation time

void init_roms(void);

double sc_time_stamp () {       // Called by $time in Verilog
	return main_time;
}

#define MAX_LAST_PC 128
struct last_pc_s {
	uint32_t pc;
	uint32_t fill;
	unsigned long long t;
} last_pc[MAX_LAST_PC];
uint32_t last_pc_index;
uint32_t last_pc_value;
unsigned last_pc_stuck;
uint32_t cycles;
uint32_t waitstate_count;

void
dump_last_pc(void)
{
	int i, c;

	i = last_pc_index;
	for (c = 0; c < MAX_LAST_PC; c++) {
		VL_PRINTF("%llu; pc=%08x\n", last_pc[i].t, last_pc[i].pc);
		i++;
		if (i >= MAX_LAST_PC)
			i = 0;
	}
	printf("------\n");
}

/* public */
#define RESET	top->ff_verilator__DOT__reset
#define vsw	top->ff_verilator__DOT__sw
#define vsw1	top->ff_verilator__DOT__sw1
#define js top->ff_verilator__DOT__js_analog

#define vCLK	top->ff_verilator__DOT__CLK
#define vclk25	top->ff_verilator__DOT__clk25
#define vclk12  top->ff_verilator__DOT__clk12
#define vclk6   top->ff_verilator__DOT__clk6

/* private */
#define LED1 	top->ff_verilator__DOT__uut__DOT__ff__DOT__led1
#define LED2	top->ff_verilator__DOT__uut__DOT__ff__DOT__led2
//#define S_6MHZ	top->ff_verilator__DOT__uut__DOT__ff__DOT__s_6mhz
#define S_6MHZ	top->ff_verilator__DOT__clk_6mhz_o

#define UDS_N	top->ff_verilator__DOT__uut__DOT__ff__DOT__uds_n
#define LDS_N	top->ff_verilator__DOT__uut__DOT__ff__DOT__lds_n
#define AS_N	top->ff_verilator__DOT__uut__DOT__ff__DOT__as_n
#define R_W_N	top->ff_verilator__DOT__uut__DOT__ff__DOT__r_w_n
#define RAM0_N	top->ff_verilator__DOT__uut__DOT__ff__DOT__ram0_n
#define RAM1_N	top->ff_verilator__DOT__uut__DOT__ff__DOT__ram1_n
#define ROM_OUT	top->ff_verilator__DOT__uut__DOT__ff__DOT__mb_out_rom
#define OUT_RAM top->ff_verilator__DOT__uut__DOT__ff__DOT__mb_out_ram

#define ROM_PIA_CS    top->ff_verilator__DOT__uut__DOT__rom_pia_cs
#define ROM_PIA_RS    top->ff_verilator__DOT__uut__DOT__rom_pia_rs
#define ROM_PIA_WRITE top->ff_verilator__DOT__uut__DOT__rom_pia_write
#define MPU_DATA_OUT  top->ff_verilator__DOT__uut__DOT__mpu_data_out

#define SCAN_RAM top->ff_verilator__DOT__scanconv__DOT__scan_ram__DOT__ram
#define PFRAM_H  top->ff_verilator__DOT__uut__DOT__ff__DOT__pfram__DOT__ramh
#define PFRAM_L  top->ff_verilator__DOT__uut__DOT__ff__DOT__pfram__DOT__raml
#define MORAM_H  top->ff_verilator__DOT__uut__DOT__ff__DOT__moram__DOT__ramh__DOT__ram
#define MORAM_L  top->ff_verilator__DOT__uut__DOT__ff__DOT__moram__DOT__raml__DOT__ram
#define COLORAM  top->ff_verilator__DOT__uut__DOT__ff__DOT__coloram__DOT__ram

#ifndef no_cpu
#define PC	 top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__pc_out
#define PC_OUT	 top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__pc_out
#define DATA_OUT top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__data_out

#define DR	top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__i_datareg__DOT__dr
#define AR	top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__i_adrreg__DOT__ar
#define SSP	top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__i_adrreg__DOT__ssp
#define USP	top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__i_adrreg__DOT__usp

#define FC_OUT_I   top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__fc_out_i
#define EXEC_STATE top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__i_ctrl__DOT__exec_state
#define CHK_PC_I   top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__chk_pc_i
#define WAITSTATES top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__i_bus_if__DOT__waitstates
#define ADR_I	    top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__adr_i
#define TRAP_AERR_I top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__trap_aerr_i
#define HALT_IN	    top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__halt_in
#define STATUS_REG_I top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__status_reg_i

#define EX_STATE    top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__i_irq_ctrl__DOT__ex_state
#define VECTOR_NO   top->ff_verilator__DOT__uut__DOT__ff__DOT__cpu__DOT__wf68k00ip_top__DOT__i_68k00__DOT__i_irq_ctrl__DOT__vector_no
#else
#define PC_OUT	 0
#endif // no_cpu

void
dump_regs(void)
{
#ifndef no_cpu
	VL_PRINTF("%10llu; pc=%04x sr=%04x\n",
		  main_time, PC_OUT, STATUS_REG_I);

	VL_PRINTF("            d0=%08x d1=%08x d2=%08x d3=%08x d4=%08x d5=%08x d6=%08x d7=%08x %s\n",
		  DR[0], DR[1], DR[2], DR[3], DR[4], DR[5], DR[6], DR[7],
		  RESET ? "(reset)" : "");

	VL_PRINTF("            a0=%08x a1=%08x a2=%08x a3=%08x a4=%08x a5=%08x a6=%08x ssp=%08x\n",
		  AR[0], AR[1], AR[2], AR[3], AR[4], AR[5], AR[6], SSP);
#endif
}

int
dump_rams(char *filename)
{
	int i;
	FILE *f;

	printf("dumping video rams to %s...\n", filename);

	f = fopen(filename, "w");
	if (f == NULL) {
		printf("can't open file '%s'n", filename);
		perror(filename);
		return -1;
	}

	// pf ram - 1kx8
	for (i = 0; i < 1024; i++) {
		fprintf(f, "pf %x %02x %02x\n", 
			i,
			PFRAM_H[i],
			PFRAM_L[i]);
	}

	// moram - 256x4
	for (i = 0; i < 256; i++) {
		fprintf(f, "mo %x %x %x %x %x\n", 
			i,
			(MORAM_H[i] >> 4) & 0xf,
			(MORAM_H[i] >> 0) & 0xf,
			(MORAM_L[i] >> 4) & 0xf,
			(MORAM_L[i] >> 0) & 0xf);
	}

	// color ram - 256x4
	for (i = 0; i < 256; i++) {
		fprintf(f, "co %x %x %x\n", 
			i,
			(COLORAM[i] >> 4) & 0xf,
			(COLORAM[i] >> 0) & 0xf
			);
	}

	fclose(f);
	printf("done.\n");
	return 0;
}

int
read_rams(char *filename)
{
	int i, n, a, v1, v2, v3, v4;
	FILE *f;
	char line[256];

	printf("reading video rams from %s...\n", filename);

	f = fopen(filename, "r");
	if (f == NULL) {
		printf("can't open file '%s'n", filename);
		perror(filename);
		return -1;
	}

	while (fgets(line, sizeof(line), f)) {
		if (line[0] == '#')
			continue;

		if (line[0] == 'p' && line[1] == 'f') {
			n = sscanf(line, "pf %x %x %x\n", &a, &v1, &v2);
			if (0) printf("pf (n %d, %x %x %x)\n", n, a, v1, v2);

			PFRAM_H[a] = v1;
			PFRAM_L[a] = v2;
		}

		if (line[0] == 'm' && line[1] == 'o') {
			n = sscanf(line, "mo %x %x %x %x %x\n", &a, &v1, &v2, &v3, &v4);
			if (0) printf("mo (n %d, %x %x %x %x %x)\n", n, a, v1, v2, v3, v4);

			MORAM_H[a] = (v1 << 4) | (v2 << 0);
			MORAM_L[a] = (v3 << 4) | (v4 << 0);
		}

		if (line[0] == 'c' && line[1] == 'o') {
			n = sscanf(line, "co %x %x %x\n", &a, &v1, &v2);
			if (0) printf("co (n %d, %x %x %x)\n", n, a, v1, v2);

			COLORAM[a] = (v1 << 4) | v2;
		}
	}

	fclose(f);
	printf("done.\n");

	return 0;
}

void init_roms(void)
{
}

void
sw_assert(int s)
{
	vsw &= ~(1<<s);
}

void
sw_deassert(int s)
{
	vsw |= 1<<s;
}


int show_cosim_io;

int main(int argc, char** argv)
{
    VerilatedVcdC* tfp = NULL;
    Verilated::commandArgs(argc, argv);   // Remember args

    int show_waves = 0;
    int show_pc = 0;
    int show_regs = 0;
    int show_loops = 0;
    int show_ram = 0;
    int show_rom = 0;

    int show_min_time = 0;
    int show_max_time = 0;
    int max_time = 0;
    int result = 0;
    int do_throw1 = 0;
    int do_start1 = 0;
    int do_coin1 = 0;
    int do_cosim = 0;
    int do_ramdump = 0;
    int do_ramload = 0;
    int do_halt = 0;

    show_cosim_io = 0;
    char *filename = (char *)"ramdump.txt";

    top = new Vatari_verilator;             // Create instance
//    topv = top->v;

    printf("built on: %s %s\n", __DATE__, __TIME__);

    // process local args
    for (int i = 0; i < argc; i++) {
	    if (argv[i][0] == '+') {
		    switch (argv[i][1]) {
		    case 'b': show_min_time = atoi(argv[i]+2); break;
		    case 'c': do_cosim++; break;
		    case 'e': show_max_time = atoi(argv[i]+2); break;
		    case 'i': show_cosim_io++; break;
		    case 'm': max_time = atoi(argv[i]+2); break;
		    case 'p': show_pc++; break;
		    case 'r': show_regs++; break;
		    case 'v': show_loops++; break;
		    case 'w': show_waves++; break;
		    case 'H': do_halt++; break;
		    case 'S': do_start1++; break;
		    case 'T': do_throw1++; break;
		    case 'C': do_coin1++; break;
		    case 'D':
			    do_ramdump++;
			    if (argv[i][2]) filename = strdup(&argv[i][2]);
			    break;
		    case 'R':
			    do_ramload++;
			    if (argv[i][2]) filename = strdup(&argv[i][2]);
			    break;
		    default:
			    fprintf(stderr, "bad arg? %s\n", argv[i]);
			    exit(1);
		    }
	    }
    }

#ifdef VM_TRACE
    if (show_waves) {
	    Verilated::traceEverOn(true);
	    VL_PRINTF("Enabling waves...\n");
	    tfp = new VerilatedVcdC;
	    top->trace(tfp, 99);	// Trace 99 levels of hierarchy
	    tfp->open("verilator.vcd");	// Open the dump file

	    if (show_min_time)
		    printf("show_min_time=%d\n", (int)show_min_time);
	    if (show_max_time)
		    printf("show_max_time=%d\n", (int)show_max_time);
    }
#endif

    int old_clk = 1;
    int old_6mhz = 1;
    int old_led1 = 0;
    int old_led2 = 0;
    int old_as_n = 0;
    int old_ram0_n = 0;
    int old_ram1_n = 0;

    int drop_as_n = 0;
    int drop_ram0_n = 0;
    int drop_ram1_n = 0;
    int falling_clk;

    init_roms();

    vsw  = 0xffff /*0x3ff*/;
    vsw1 = 0xbf /*0xffff*/ /*0x0*/;

    vCLK = 0;
    vclk25 = 0;
    vclk12 = 0;
    vclk6 = 1;

    // main loop
    while (!Verilated::gotFinish()) {

#ifndef no_cpu
        if (do_halt) {
		HALT_IN = 0;
	}
#endif

	if (do_ramload && main_time == 1) {
		read_rams(filename);
	}

	if (main_time == 1) {
		int i;
		for (i = 0; i < 129072; i++)
			SCAN_RAM[i] = rand() & 0xff;
	}

	if (show_loops) {
		VL_PRINTF("%llu; CLK=%d clk25=%d clk12=%d clk6=%d reset=%x sw=%x sw1=%x\n",
			  main_time,
			  vCLK,
			  vclk25,
			  vclk12,
			  vclk6,
			  RESET,
			  vsw,
			  vsw1);
	}

#define COIN_TIME	0
#define COIN_DUR	0
#define THROW_TIME	(2000000*2) //25mhz = *2
#define THROW_DUR	(200000*2)
#define START_TIME	(3000000*2)
#define START_DUR	(200000*2)

	// coin
	if (do_coin1) {
		if (COIN_TIME && main_time >= COIN_TIME) {
			sw_assert(7);
			if (main_time == COIN_TIME) printf("DO COIN1!\n");
		}
		if (main_time == (COIN_TIME+COIN_DUR)) printf("UNDO COIN1!\n");
		if (main_time > (COIN_TIME+COIN_DUR)) {
			sw_deassert(7);
		}
	}

        if (joystick_fire())
		sw_assert(2);
	else
		sw_deassert(2);

	// start
	if (do_start1) {
		// start
		if (START_TIME && main_time >= START_TIME) {
			sw_assert(5);
			if (main_time == START_TIME) printf("DO START1!\n");
		}
		if (main_time == (START_TIME+START_DUR)) printf("UNDO START1!\n");
		if (main_time > (START_TIME+START_DUR)) {
			sw_deassert(5);
		}
	}

	// throw
	if (do_throw1) {
		// start
		if (THROW_TIME && main_time >= THROW_TIME) {
			sw_assert(2);
			if (main_time == THROW_TIME) printf("DO THROW1!\n");
		}
		if (main_time == (THROW_TIME+THROW_DUR)) printf("UNDO THROW1!\n");
		if (main_time > (THROW_TIME+THROW_DUR)) {
			sw_deassert(2);
		}
	}

	// toggle clock(s)
#if 0 // 50mhz
	vCLK = vCLK ? 0 : 1;
	if (vCLK) {
		vclk25 = vclk25 ? 0 : 1;

		if (vclk25)
			vclk12 = vclk12 ? 0 : 1;

		if (vclk12)
			vclk6 = vclk6 ? 0 : 1;
	}
#endif
#if 1 // 25mhz
	vCLK = vCLK ? 0 : 1;
	vclk25 = vCLK;

	if (vclk25) {
		vclk12 = vclk12 ? 0 : 1;

		if (vclk12)
			vclk6 = vclk6 ? 0 : 1;
	}
#endif
#if 0 // 12mhz
	vCLK = vCLK ? 0 : 1;

	vclk25 = 0;
	vclk12 = vCLK;

	if (vclk12)
		vclk6 = vclk6 ? 0 : 1;
#endif

	if (0)
		VL_PRINTF("clk 50m %d, 25m %d, 12m %d, 6m %d\n",
			  vCLK, vclk25, vclk12, vclk6);

	//
	if (main_time < 100)
		RESET = 0;
	else
		if (main_time < 500)
			RESET = 1;
		else
			RESET = 0;

#ifndef no_cpu
//?
top->ff_verilator__DOT__uut__DOT__ff__DOT__reset_n = RESET ? 0 : 1;
#endif

	// evaluate model
        top->eval();

#if 0
	//
	if (ROM_PIA_CS &&
	    ROM_PIA_WRITE)
	{
		VL_PRINTF("%llu; pc=%04x rom_pia write %x %02x\n",
			  main_time,
			  PC,
			  ROM_PIA_RS,
			  MPU_DATA_OUT);
	}
#endif

#ifndef no_cpu
	if (S_6MHZ && old_6mhz == 0 &&
	    TRAP_AERR_I)
	{
		int i, c;
		printf("trap %x", TRAP_AERR_I);
		dump_last_pc();
	}

	if (0 &&
	    S_6MHZ && old_6mhz == 0 &&
	    PC_OUT >= 0x46a &&
	    PC_OUT <= 0x478)
	{
		int i, c;
		printf("loop @ %08x\n",
		       PC_OUT);
		dump_last_pc();
		vl_finish("ff_verilator.cpp",__LINE__,"");
	}

	if (S_6MHZ && old_6mhz == 0 &&
	    SSP && (SSP < 0x14000 || SSP > 0x1bfff))
	{
		int i, c;
		printf("SSP out of bounds %08x",
		       SSP);
		dump_last_pc();
		vl_finish("ff_verilator.cpp",__LINE__,"");
	}

	//
	if (S_6MHZ && old_6mhz == 0) {
		if (WAITSTATES) {
			waitstate_count++;
			if (waitstate_count >= 5000) {
				printf("%llu; stuck waitstates; no dtack? pc=%x, addr=%x\n",
				       main_time, PC_OUT, ADR_I);

				dump_regs();
				dump_last_pc();
				vl_finish("ff_verilator.cpp",__LINE__,"");
				result = 4;
				break;
			}
		} else {
			waitstate_count = 0;
		}
	}

	//
	if (S_6MHZ && old_6mhz == 0 &&
	    FC_OUT_I == 0x6 &&
	    EXEC_STATE == 1 &&
	    CHK_PC_I)
	{
		uint32_t next_pc_value;

		next_pc_value = PC_OUT;

		//
		cycles++;
		if ((cycles % 10000) == 0)
			printf("cycles: %u, time %llu (pc=%x)\n", cycles, main_time, next_pc_value);

		//
		if (next_pc_value != last_pc_value) {
			last_pc_stuck = 0;
		} else {
			last_pc_stuck++;
			if (last_pc_stuck >= 100) {
				printf("%llu; pc not progressing, pc=%x\n",
				       main_time, next_pc_value);
				dump_regs();
				dump_last_pc();
				vl_finish("ff_verilator.cpp",__LINE__,"");
				result = 3;
				break;
			}
		}
		last_pc_value = next_pc_value;

		//
		last_pc[last_pc_index].pc = next_pc_value;
		last_pc[last_pc_index].t = main_time;
		last_pc_index++;
		if (last_pc_index >= MAX_LAST_PC)
			last_pc_index = 0;

		if (show_pc) {
			dump_regs();
		}

		if (show_regs) {
			dump_regs();
		}
	}

	//
	if (S_6MHZ && old_6mhz == 0) {
		if (LED1 != old_led1) {
			printf("led: led1 %s\n", LED1 ? "on" : "off");
		}
		if (LED2 != old_led2) {
			printf("led: led2 %s\n", LED2 ? "on" : "off");
		}

		old_led1 = LED1;
		old_led2 = LED2;
	}

	falling_clk = S_6MHZ == 0 && old_6mhz == 1;

	if (falling_clk && show_rom) {
		if (drop_as_n) {
			drop_as_n = 0;
			if ((UDS_N == 0 ||
			     LDS_N == 0) &&
			    ADR_I < 0x14000)
			{
				printf("rtl rom: %x -> %04x; pc=%x\n",
				       ADR_I,
				       ROM_OUT,
				       PC_OUT);
			}
		}

		if (AS_N == 0 && old_as_n == 1)
			drop_as_n = 1;

		old_as_n = AS_N;
	}

	if (falling_clk && show_ram) {
		if (drop_ram0_n || drop_ram1_n) {
			drop_ram0_n = 0;
			drop_ram1_n = 0;
			if (UDS_N == 0 ||
			    LDS_N == 0)
			{
				if (R_W_N == 0)
					printf("rtl ram: %x <- %x; pc=%x\n",
					       ADR_I,
					       DATA_OUT,
					       PC_OUT);
				else
					printf("rtl ram: %x -> %x; pc=%x\n",
					       ADR_I,
					       OUT_RAM,
					       PC_OUT);
			}
		}

		if (RAM0_N == 0 && old_ram0_n == 1)
			drop_ram0_n = 1;
		old_ram0_n = RAM0_N;

		if (RAM1_N == 0 && old_ram1_n == 1)
			drop_ram1_n = 1;
		old_ram1_n = RAM1_N;
	}


#ifdef COSIM
	if (S_6MHZ == 1 && old_6mhz == 0 &&
	    EX_STATE== 9/*STACK_STATUS*/) {
		printf("rtl: vector_no %x\n", VECTOR_NO);
		cosim_int_event(PC_OUT, VECTOR_NO);
	}

	if (S_6MHZ && old_6mhz == 0 &&
	    FC_OUT_I == 0x6 &&
	    EXEC_STATE == 1 &&
	    CHK_PC_I &&
	    do_cosim)
	{
		cosim_m68k(top, main_time,
			   RESET, PC_OUT, STATUS_REG_I,
			   DR[0], DR[1], DR[2], DR[3], DR[4], DR[5], DR[6], DR[7],
			   AR[0], AR[1], AR[2], AR[3], AR[4], AR[5], AR[6], SSP, USP);

	}
#endif
#endif // no_cpu

	old_6mhz = S_6MHZ;

	if (max_time && main_time > max_time) {
		VL_PRINTF("%llu; MAX TIME pc %08x\n",
			  main_time,
			  PC_OUT);

		dump_regs();
		dump_last_pc();

		if (do_ramdump) {
			dump_rams(filename);
		}

		vl_finish("ff_verilator.cpp",__LINE__,"");
		result = 2;
	}

#ifdef VM_TRACE
	if (tfp) {
		if (show_min_time == 0 && show_max_time == 0)
			tfp->dump(main_time);
		else
			if (show_min_time && main_time > show_min_time)
				tfp->dump(main_time);

		if (show_max_time && main_time > show_max_time)
			vl_finish("ff_verilator.cpp",__LINE__,"");
	}
#endif

        main_time++;
    }

    VL_PRINTF("%llu; exit simulation; pc %08x\n", main_time, PC_OUT);

    top->final();

    if (tfp)
	    tfp->close();

    if (result)
	    exit(result);

    exit(0);
}

