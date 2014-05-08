all: HDLC

test: HDLC HDLC_tb

HDLC.o: HDLC.vhd
	ghdl -a HDLC.vhd

HDLC: HDLC.o
	ghdl -e HDLC

HDLC_tb.o: HDLC_tb.vhd
	ghdl -a HDLC_tb.vhd

HDLC_tb: HDLC_tb.o HDLC.o
	ghdl -e HDLC_tb
	ghdl -r HDLC_tb	--vcd=HDLC_tb.vcd
	gtkwave HDLC_tb.vcd