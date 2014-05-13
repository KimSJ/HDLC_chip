-- hdlcreceiver.vhd
--
-- takes 8-bit parallel data and sends frame
-- Frame ends when data value is written with "rxLast" set.

library IEEE;
use IEEE.STD_LOGIC_1164.All;
use IEEE.NUMERIC_STD.all;
-- debug libraries
use std.textio.all;
use ieee.std_logic_textio.all;

entity HdlcTransmitter is
	generic (
		rxReqChainSize  : integer := 2 -- defines length of metastability chain; must be at least two.
	);
	port (
		-- microprocesser interface
		Dout :		out	Std_Logic_Vector (7 downto 0); -- rx register
		rxLast : 	in 	Std_Logic;
		rxRD : 		in	Std_Logic; -- read strobe
		rxReq : 	out	Std_Logic; -- high if data available

		rxRST :		in	Std_Logic;

		-- bit clock
		sysClk :	in	Std_Logic; -- 16MHz

		-- line interface
		rxD :		buffer	Std_Logic;
		rxEn :		buffer	Std_Logic
	);
-- translate_off
-- check bounds of generics -- error reported only on execution
begin
	assert( rxReqChainSize > 1 )
	report "rxReqChainSize should be at least 2!"
	severity ERROR;
-- translate_on
end HdlcTransmitter;

architecture behavioural of HdlcTransmitter is

begin
end behavioural;
