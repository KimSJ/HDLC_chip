GHDL_OPTS = --ieee=synopsys


all: HDLC

test: HDLC HDLC_tb

current: HDLC HdlcTransmitter_tb.o
	ghdl -e $(GHDL_OPTS) HdlcTransmitter_tb
	#./hdlctransmitter_tb
	ghdl -r  $(GHDL_OPTS) HdlcTransmitter_tb --vcd=HdlcTransmitter_tb.vcd --stop-time=1000us
	#gtkwave HdlcTransmitter_tb.vcd

#HDLC.o: HDLC.vhd
#	ghdl -a $(GHDL_OPTS) HDLC.vhd

HDLC: HDLC.o
	ghdl -e $(GHDL_OPTS) HDLC

*.o: *.vhd
	ghdl -a  $(GHDL_OPTS) $?


HDLC_tb: HDLC_tb.o HDLC.o
	ghdl -e  $(GHDL_OPTS) HDLC_tb
	ghdl -r  $(GHDL_OPTS) HDLC_tb --vcd=HDLC_tb.vcd
	gtkwave HDLC_tb.vcd