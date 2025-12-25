# Makefile for UART Matrix Project
# Icarus Verilog 12.0 (Verilog-1995 syntax)

IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Default parameters
W = 8
DIV = 3
PAR = 0

# Source files
SOURCES = main.v transmitter.v receiver.v
TEST_SOURCES = test_main.v

# Targets
all: compile

compile: $(SOURCES)
	$(IVERILOG) -o main.vvp $(SOURCES) 2>&1 | head -20

test: $(SOURCES) $(TEST_SOURCES)
	$(IVERILOG) -o test.vvp $(TEST_SOURCES) $(SOURCES)
	$(VVP) test.vvp
	@echo "Test completed, VCD file generated"

view:
	$(GTKWAVE) test.vcd &

clean:
	rm -f *.vvp *.vcd

.PHONY: all compile test view clean
