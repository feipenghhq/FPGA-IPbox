# =================================================================
# Makefile for running iverilog flow
# Author: Heqing Huang
# Date Created: 10/10/2020
#
# Need to setup the following variable from the source makefile
#
# 	SRC_PATH	: RTL source directories
# 	TOP_DESIGN	: Top level rtl module name
# 	TOP_FILE 	: Top level rtl file
# 	TB_TOP		: Testbench top level file
# 	WAVE		: vcd dump name
#
# =================================================================

# =============================
# Tool Variable
# =============================
IVERILOG 	= iverilog
VVP 		= vvp
GTKWAVE 	= gtkwave
VERILATOR	= verilator

# =============================
# Variable
# =============================

ALL_SRC_FILES = $(shell find $(SRC_PATH) -type f)
RTL_OUT		  = $(TOP_DESIGN)
TB_OUT		  = $(TOP_DESIGN)_tb

# =============================
# Command
# =============================

.PHONY: clean help wave run tb rtl lint clean

help:
	@echo 	"Usage: "
	@echo	"make help 	- print this message"
	@echo	"make wave 	- run all the process and open waveform"
	@echo	"make run  	- run the excutable"
	@echo 	"make tb   	- compile source rtl and testbench"
	@echo	"make rtl  	- compile rtl"
	@echo   "make clean	- clean all the output"
	@echo	"make lint	- lint the design using verilator"

wave: $(WAVE)
	gtkwave $(WAVE)

$(WAVE): $(TB_OUT)
	$(VVP) $(TB_OUT)

run: $(TB_OUT)
	./$(TB_OUT)

tb: $(TB_OUT)

$(TB_OUT): $(TB_TOP) $(TOP_FILE) $(ALL_SRC_FILES)
	$(IVERILOG) -o $(TB_OUT) $(TB_TOP) -y $(SRC_PATH)

rtl: $(RTL_OUT)

$(RTL_OUT):	$(TOP_FILE) $(ALL_SRC_FILES)
	$(IVERILOG) -o $(RTL_OUT) $(TOP_FILE) -y $(SRC_PATH)

lint:
	@verilator  -Wall -lint-only $(TOP_FILE) -y SRC_PATH
	@echo "No Issue Found"

clean:
	rm -rf $(TB_OUT) $(RTL_OUT) *.out *.vcd
