# =============================
# Design specific Variable
# =============================

# Verilog src path
RTL_PATH = ../rtl/
RTL_INCDIR_PATH = $(RTL_PATH)
TB_PATH  = ./

ALL_SRC_FILES = $(shell find $(RTL_PATH) -type f)

TOP_DESIGN	= i2c_master
TOP_FILE 	= $(RTL_PATH)$(TOP_DESIGN).v
TB_FILE		= $(TOP_DESIGN)_tb.v
WAVE		= dump.vcd

include ../../script/makefile_iverilog.mk
