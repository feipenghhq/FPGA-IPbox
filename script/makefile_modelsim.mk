# =================================================================
#
# Copyright 2020 by Heqing Huang (feipenghhq@gamil.com)
#
# Makefile for running Modelsim flow
# Author: Heqing Huang
# Date Created: 11/07/2020
#
# Need to setup the following variable from the source makefile
#
# 	RTL_PATH	: RTL source directories
# 	TOP_DESIGN	: Top level rtl module name
# 	TOP_FILE 	: Top level rtl file
# 	TB_FILE		: Testbench top level file
# 	WAVE		: vcd dump name
#
# Check this page for more modelsim command:
# http://people.cs.pitt.edu/~don/coe1502/Reference/vsim_quickref.pdf
#
# =================================================================

# =============================
# Tool Variable
# =============================
COMPILE 	= vlog
EXECUTE     = vsim
GTKWAVE 	= gtkwave
VERILATOR	= verilator

# =============================
# Variable
# =============================
OUT_DIR		  = output

ALL_SRC_FILES = $(shell find $(RTL_PATH) -name "*.v" -type f)
ALL_TB_FILES  = $(shell find $(TB_PATH) -name "*.v" -type f)
LIB 		  = $(TOP_DESIGN)_lib
RTL_OUT		  = $(LIB)/$(TOP_DESIGN)
TB_OUT		  = $(LIB)/$(TOP_DESIGN)_tb


# =============================
# Command
# =============================

.PHONY: clean help wave run tb rtl lib lint clean

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
	$(EXECUTE) $(TB_OUT)

run_gui: $(TB_OUT) $(RTL_OUT)
	$(EXECUTE) -lib $(LIB) $(TOP_DESIGN)_tb

run: $(TB_OUT) $(RTL_OUT)
	$(EXECUTE) -lib $(LIB) $(TOP_DESIGN)_tb  -c -do "run -all"

tb: $(LIB) $(TB_OUT)

$(TB_OUT): $(TB_FILE) $(TOP_FILE) $(ALL_SRC_FILES) $(ALL_TB_FILES) $(LIB)
	$(COMPILE) $(TB_FILE) -work $(LIB) -y $(RTL_PATH) -y $(TB_PATH) +incdir+$(RTL_INCDIR_PATH) +libext+.v+.sv

rtl: $(LIB) $(RTL_OUT)

$(RTL_OUT):	$(TOP_FILE) $(ALL_SRC_FILES)
	$(COMPILE) $(TOP_FILE) -work $(LIB) -y $(RTL_PATH) +incdir+$(RTL_INCDIR_PATH) -lint

$(LIB):
	vlib $(LIB)


lint:
	@verilator  -Wall -lint-only $(TOP_FILE) -y $(RTL_PATH)
	@echo "No Issue Found"

clean:
	rm -rf $(LIB) *.vcd transcript
