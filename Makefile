# use the library version which includes std_logic_textio:
GHDL_OPTS = --ieee=synopsys

STOP_TIME = 10000us

all: hdlc

clean:
	rm *.o *.cf *.vcd

current: hdlctransmitter_tb
# hdlctransmitter
	#./hdlctransmitter_tb
#	ghdl -r  $(GHDL_OPTS) hdlctransmitter_tb --vcd=hdlctransmitter_tb.vcd --stop-time=10000us
	#gtkwave hdlctransmitter_tb.vcd

%_tb: %_tb.o %.o
#	ghdl -e $(GHDL_OPTS) $*
	ghdl -e $(GHDL_OPTS) $@
	ghdl -r  $(GHDL_OPTS) $@ --vcd=$@.vcd --stop-time=$(STOP_TIME)
	# To start a new gtkwave session:
	#    gtkwave $@.vcd

%: %.o
	ghdl -e $(GHDL_OPTS) $@

%.o: %.vhd
	ghdl -a  $(GHDL_OPTS) $?

.PRECIOUS: %.o