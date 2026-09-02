PROBLEM ?= 01_async_fifo
TOPMODULE ?= tb_async_fifo
FILELIST ?= ./filelists/$(PROBLEM).f
INCLUDE_DIR ?= $(CURDIR)
VCS ?= $(shell command -v vcs 2>/dev/null || printf '%s' /tools/synopsys/vcs/S-2021.09/bin/vcs)
VCS_HOME ?= $(patsubst %/bin/vcs,%,$(VCS))
VCS_COM ?= $(CURDIR)/scripts/vcs1_glibc231.sh
VCS_RUNNER ?= $(CURDIR)/scripts/with_synopsys_license.sh
export VCS_HOME
export VCS_COM
export PATH := $(VCS_HOME)/bin:$(PATH)

M_DIR := ./csrc/$(PROBLEM)
SIMV := ./out/simv_$(PROBLEM)
SIMV_DAIDIR := $(SIMV).daidir
WAVE := ./out/$(PROBLEM).vcd
LEGACY_VVP := ./out/$(PROBLEM).vvp
MIN_VVP := ./out/$(PROBLEM)_min.vvp
COMPILE_LOG := ./log/$(PROBLEM)_compile.log
RUN_LOG := ./log/$(PROBLEM)_run.log

.PHONY: all run compile lint regress prepare list clean

all: run

prepare:
	@mkdir -p ./out ./log "$(M_DIR)"
	@test -f "$(FILELIST)" || { echo "ERROR: missing $(FILELIST)"; exit 2; }

list: prepare
	@echo "PROBLEM=$(PROBLEM)"
	@echo "TOPMODULE=$(TOPMODULE)"
	@echo "FILELIST=$(FILELIST)"
	@sed -n '/^[[:space:]]*\($$\|#\|\/\/\)/!p' "$(FILELIST)"

compile: prepare
	@src_count=$$(sed '/^[[:space:]]*\($$\|#\|\/\/\)/d' "$(FILELIST)" | wc -l); \
	if [ "$$src_count" -eq 0 ]; then \
		echo "SKIP compile: $(FILELIST) has no user source entries"; \
		exit 0; \
	elif command -v "$(VCS)" >/dev/null 2>&1; then \
		"$(VCS_RUNNER)" "$(VCS)" -full64 -sverilog \
			+warn=noLNX_OS_VERUN +warn=noNS \
			+incdir+$(INCLUDE_DIR) -timescale=1ns/1ps \
			-top "$(TOPMODULE)" -Mdir="$(M_DIR)" -kdb -debug_access+all \
			+lint=all -l "$(COMPILE_LOG)" -o "$(SIMV)" -f "$(FILELIST)"; \
	else \
		echo "BLOCKED: VCS executable not found: $(VCS)"; \
		exit 3; \
	fi

run: compile
	@if [ -x "$(SIMV)" ]; then \
		"$(VCS_RUNNER)" "$(SIMV)" -l "$(RUN_LOG)"; \
	else \
		echo "SKIP run: no compiled image for $(PROBLEM)"; \
		exit 4; \
	fi
	@test -s "$(WAVE)" || { echo "ERROR: waveform was not generated: $(WAVE)"; exit 5; }
	@echo "Waveform: $(WAVE)"

lint: prepare
	@srcs=$$(sed '/^[[:space:]]*\($$\|#\|\/\/\)/d' "$(FILELIST)"); \
	if [ -z "$$srcs" ]; then \
		echo "SKIP lint: $(FILELIST) has no user source entries"; \
	elif ! command -v verible-verilog-lint >/dev/null 2>&1; then \
		echo "BLOCKED lint: verible-verilog-lint not found"; \
		exit 3; \
	else \
		verible-verilog-lint --rules_config_search $$srcs; \
	fi

regress:
	@./scripts/regress_make.sh

clean:
	@rm -rf -- "$(M_DIR)" "$(SIMV)" "$(SIMV_DAIDIR)"
	@rm -f -- "$(COMPILE_LOG)" "$(RUN_LOG)" "$(WAVE)" \
		"$(LEGACY_VVP)" "$(MIN_VVP)" ./out/verdi_config_file \
		./ucli.key ./vcs.key
	@echo "Cleaned generated files for $(PROBLEM)"
