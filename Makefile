# Makefile
###############################################################
# General VHDL makefile
#   edit "all:"" and "current:" targets to suit your project
###############################################################

# use the library version which includes std_logic_textio:
GHDL_OPTS = --ieee=synopsys

# see http://home.gna.org/ghdl/ghdl/Simulation-options.html#Simulation-options
# for details of simulation options, including --stop_time
STOP_TIME = 10000us
ifdef STOP_TIME
	R_OPTS += --stop-time=$(STOP_TIME)
endif


all: hdlc

# mark the top level as depending on all .o files
hdlc: *.o hdlc.o
	ghdl -e $(GHDL_OPTS) hdlc

current: hdlctransmitter_tb

hdlctransmitter_tb: hdlctransmitter.o crc16.o hdlctransmitter_tb.o
	ghdl -e $(GHDL_OPTS) hdlctransmitter_tb
	ghdl -r $(GHDL_OPTS) $@ --vcd=$@.vcd $(R_OPTS)

clean:
	rm *.o *.cf *.vcd

%_tb: %_tb.o %.o
	ghdl -e $(GHDL_OPTS) $@
	ghdl -r $(GHDL_OPTS) $@ --vcd=$@.vcd $(R_OPTS)
	# To start a new gtkwave session:
	#    gtkwave $@.vcd &

%: %.o
	ghdl -e $(GHDL_OPTS) $@

%.o: %.vhd
	ghdl -a  $(GHDL_OPTS) $?

# the following rule stops make considering .o files as
# "intermediate", and thus prevents it deleting them
.PRECIOUS: %.o