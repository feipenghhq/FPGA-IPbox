# =============================
# Design specific Variable
# =============================

# Verilog src path
RTL_PATH = ../rtl/
TB_PATH  = ./

ALL_SRC_FILES = $(shell find $(RTL_PATH) -type f)

ifeq ($(TOP),)
	TOP_DESIGN	= codec_transceiver
else
	TOP_DESIGN	= $(TOP)
endif

TOP_FILE 	= $(RTL_PATH)$(TOP_DESIGN).v
TB_TOP		= $(TOP_DESIGN)_tb.v
WAVE		= $(TOP_DESIGN).vcd

include ../../script/makefile_iverilog.mk
