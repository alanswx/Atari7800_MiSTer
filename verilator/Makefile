#
#
#

V = verilator
#V = /usr/local/bin/verilator
#V = /usr/local/src/verilator-3.876/bin/verilator
COSIM = n

TOP = --top-module top
RTL = ../code
CPU = ../m68k
ROM = ../roms/v3
V_INC = +incdir+$(RTL) +incdir+$(CPU) +incdir+$(ROM)

V_DEFINE = +define+debug=1 +define+SIMULATION=1
V_DEFINE += --converge-limit 2000 -Wno-WIDTH -Wno-IMPLICIT -Wno-MODDUP -Wno-UNSIGNED -Wno-CASEINCOMPLETE -Wno-CASEX -Wno-SYMRSVDWORD -Wno-COMBDLY -Wno-INITIALDLY -Wno-BLKANDNBLK -Wno-UNOPTFLAT -Wno-SELRANGE -Wno-CMPCONST -Wno-CASEOVERLAP -Wno-PINMISSING -Wno-MULTIDRIVEN

CFLAGS = "$(CC_OPT) $(CC_DEFINE)  `sdl2-config --cflags`"
LDFLAGS = " -lSDL2 -lpthread `sdl2-config --libs` -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo "
EXE = ./tmp/Vtop
#V_OPT = -O2 
#CC_OPT = -O
V_OPT = 
CC_OPT =  -g

ifeq ($(COSIM),y)
CC_DEFINE = -DCOSIM=1
COSIM_SRC = cosim.cpp
else
CC_DEFINE =
COSIM_SRC =
endif

#V_DEFINE = +define+debug=1 +define+SIMULATION=1 +define+no_cpu=1
#V_OPT =
#CC_DEFINE = -Dno_cpu=1
#CC_OPT =

V_SRC = \
	../sim/spram.sv \
	../sim/dpram_dc.sv \
	atari_verilator.v \
	$(RTL)/ALU.v $(RTL)/cpu.v $(RTL)/tia.v $(RTL)/cart.sv $(RTL)/riot.v \
	$(RTL)/audio.sv $(RTL)/Maria/timing_ctrl.sv $(RTL)/Maria/memory_map.sv \
	$(RTL)/Maria/maria.sv $(RTL)/Maria/line_ram.sv $(RTL)/Maria/dma_ctrl.sv \
	$(RTL)/POKEY.sv $(RTL)/uv_vga.sv $(RTL)/top.sv 

V_DEP = \
	$(CPU)/wf68k00ip_address_registers.v \
	$(CPU)/wf68k00ip_alu.v \
	$(CPU)/wf68k00ip_bus_interface.v \
	$(CPU)/wf68k00ip_control.v \
	$(CPU)/wf68k00ip_data_registers.v \
	$(CPU)/wf68k00ip_interrupt_controller.v \
	$(CPU)/wf68k00ip_opcode_decoder.v \
	$(CPU)/wf68k00ip_shifter.v \
	$(CPU)/wf68k00ip_top_soc.v \
	$(CPU)/wf68k00ip_top.v

AC_SRC = \
	atari_verilator.cpp $(COSIM_SRC) vga.cpp
C_SRC = \
	sim_main.cpp  imgui/imgui_impl_sdl.cpp imgui/imgui_impl_opengl2.cpp imgui/imgui_draw.cpp imgui/imgui_widgets.cpp imgui/imgui.cpp
VOUT = tmp/Vtop.cpp

all: $(EXE)

$(VOUT): $(V_SRC)  Makefile
	$V -cc $(V_OPT) -LDFLAGS $(LDFLAGS) -exe --trace --Mdir ./tmp $(V_DEFINE) $(V_INC) $(TOP) -CFLAGS $(CFLAGS) $(V_SRC) $(C_SRC)

$(EXE): $(VOUT) $(C_SRC)
#	(cd tmp; make OPT="-fauto-inc-dec -fdce -fdefer-pop -fdse -ftree-ccp -ftree-ch -ftree-fre -ftree-dce -ftree-dse" -f Vtop.mk)
	(cd tmp; make -f Vtop.mk)

fast:
	(cd tmp; rm -f *.o ; make OPT="-fcompare-elim -fcprop-registers -fguess-branch-probability -fauto-inc-dec -fif-conversion2 -fif-conversion -fipa-pure-const -fdce -fipa-profile -fipa-reference -fmerge-constants -fsplit-wide-types -fdefer-pop -fdse -ftree-ccp -ftree-ch -ftree-fre -ftree-dce -ftree-dse -ftree-builtin-call-dce -ftree-copyrename -ftree-dominator-opts -ftree-forwprop -ftree-phiprop -ftree-sra -ftree-pta -ftree-ter -funit-at-a-time -ftree-bit-ccp -falign-functions  -falign-jumps -falign-loops  -falign-labels -fcaller-saves -fcrossjumping -fcse-follow-jumps -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize -fexpensive-optimizations -fgcse  -fgcse-lm -finline-small-functions -findirect-inlining -fipa-sra -foptimize-sibling-calls -fpartial-inlining -fpeephole2 -fregmove -freorder-blocks  -freorder-functions -frerun-cse-after-loop -fsched-interblock  -fsched-spec -fschedule-insns -fschedule-insns2 -fstrict-aliasing -fstrict-overflow -ftree-switch-conversion -ftree-pre -ftree-vrp" -f Vtop.mk)

clean:
	rm -f tmp/*
