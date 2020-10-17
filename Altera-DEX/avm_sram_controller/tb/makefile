# =============================
# Design specific Variable
# =============================

# Verilog src path
SRC_PATH = ../rtl/

ALL_SRC_FILES = $(shell find $(SRC_PATH) -type f)

TOP_DESIGN	= avm_sram_controller
TOP_FILE 	= $(SRC_PATH)$(TOP_DESIGN).v
TB_TOP		= $(TOP_DESIGN)_tb.v
WAVE		= dump.vcd

include ../../../script/makefile_iverilog.mk
