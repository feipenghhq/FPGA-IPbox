# =============================
# Design specific Variable
# =============================

# Verilog src path
RTL_PATH = ../rtl/
RTL_INCDIR_PATH = $(RTL_PATH)
TB_PATH  = ./

ALL_SRC_FILES = $(shell find $(RTL_PATH) -type f)

ifeq ($(TOP),)
	TOP_DESIGN	= avm_vram_controller
else
	TOP_DESIGN	= $(TOP)
endif

TOP_FILE 	= $(RTL_PATH)$(TOP_DESIGN).v
TB_FILE		= $(TOP_DESIGN)_tb.v
WAVE		= $(TOP_DESIGN).vcd

# Select simulator
MK_FILE = makefile_iverilog.mk

ifeq ($(SIM), modelsim)
	MK_FILE = makefile_modelsim.mk
endif

include ../../script/$(MK_FILE)
