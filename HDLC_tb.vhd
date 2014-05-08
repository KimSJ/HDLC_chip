-- HDLC_tb.vhd

library IEEE;
use IEEE.STD_LOGIC_1164.All;

entity HDLC_tb is
end HDLC_tb;

architecture behavioural of HDLC_tb is

component HDLC
port (
	-- microprocessor input
	D :		inout 	Std_Logic_Vector (7 downto 0);
	E : 	in	 	Std_Logic;	-- system clock
	nCS :	in		Std_Logic;
	RS :	in		Std_Logic_Vector (1 downto 0);
	RnW :	in		Std_Logic;
	nRST :	in		Std_Logic;
	nIRQ :	out		Std_Logic;

	-- clock and data or transmitter and receiver
	TxC :	in		Std_Logic;
	RxC :	in		Std_Logic;
	TxD :	out		Std_Logic;
	RxD :	in		Std_Logic;

	-- Peripheral/Modem control
	nRTS :	out		Std_Logic;
	nCTS :	in		Std_Logic;
	nDCD :	in		Std_Logic;
	nLOCnDTR : out	Std_Logic;

	-- DMA interface
	RDSR :	out		Std_Logic; -- Rx FIFO requests service
	TDSR :	out		Std_Logic  -- Tx FIFO requests service
	);
end component;

signal A, B : Std_Logic_Vector (7 downto 0);
signal R    : Std_Logic;

begin
	u0: HDLC PORT MAP (B, R); 
	A   <= "00001000" after 0 ns,   "00000000" after 10 ns,  "00001111" after 20 ns,  "00001010" after 30 ns,  "00000000" after 50 ns,  "00000000" after 60 ns;

end behavioural;