PROBLEM ?= 01_async_fifo
TOPMODULE ?= tb_async_fifo
FILELIST ?= ./filelists/$(PROBLEM).f
INCLUDE_DIR ?= $(CURDIR)

M_DIR := ./csrc/$(PROBLEM)
SIMV := ./out/simv_$(PROBLEM)
VVP := ./out/$(PROBLEM).vvp
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
	elif command -v vcs >/dev/null 2>&1; then \
		vcs -full64 -sverilog +incdir+$(INCLUDE_DIR) -timescale=1ns/1ps \
			-top "$(TOPMODULE)" -Mdir="$(M_DIR)" -kdb -debug_access+all \
			+lint=all -l "$(COMPILE_LOG)" -o "$(SIMV)" -f "$(FILELIST)"; \
	elif command -v iverilog >/dev/null 2>&1; then \
		iverilog -g2012 -Wall -s "$(TOPMODULE)" -o "$(VVP)" -f "$(FILELIST)" \
			2>&1 | tee "$(COMPILE_LOG)"; \
	else \
		echo "BLOCKED: neither VCS nor Icarus is available"; \
		exit 3; \
	fi

run: compile
	@if [ -x "$(SIMV)" ]; then \
		"$(SIMV)" -l "$(RUN_LOG)"; \
	elif [ -f "$(VVP)" ]; then \
		vvp "$(VVP)" 2>&1 | tee "$(RUN_LOG)"; \
	else \
		echo "SKIP run: no compiled image for $(PROBLEM)"; \
	fi

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
	@rm -rf -- "$(M_DIR)" "$(SIMV)" "$(VVP)"
	@rm -f -- "$(COMPILE_LOG)" "$(RUN_LOG)"
	@echo "Cleaned generated files for $(PROBLEM)"
