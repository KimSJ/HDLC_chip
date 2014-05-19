-- arduinointerface.vhd
--
-- takes 8-bit parallel data and sends frame
-- Frame ends when data value is written with "rxLast" set.

-- connect data to low 4 bits of port
-- connect strb to b4 of port (configured as output)
-- connect RnW to b5 of port (configured as output)

-- to read this peripheral:
--		(assuming strb is left high between accesses)
--		set port low bits to input
--      set RmW, strb to 1, 0 (10 = command "read low-nibble")
--		read the value
--		set strb 1 (11 = command "read high-nibble)
--		read the value
-- for multi-byte reads, repeat last four steps

-- to write this peripheral:
--		(assuming strb is left high between accesses)
--      set RnW to 0 (strb no change, so no write yet; output buffers now disabled)
--		set port low bits to output
--		write the lo-nibble value, with b5, b4 = 00
--		write the hi-nibble value, with b5, b4 = 01
-- for multi-byte writes, repeat last two steps


library IEEE;
use IEEE.STD_LOGIC_1164.All;
use IEEE.NUMERIC_STD.all;
-- debug libraries
use std.textio.all;
use ieee.std_logic_textio.all;

entity hdlcreceiver_tb is

end entity hdlcreceiver_tb;

architecture behavioural of hdlcreceiver_tb is
	signal q	:  	Std_Logic_Vector (7 downto 0); -- q is the values read
	signal rxLast : Std_Logic; -- the databus 
	signal rxRD  : 	Std_Logic := '1';
	signal rxReq : 	Std_Logic;
	signal rst:  	Std_Logic :='1';
	signal rxErr : 	Std_Logic; -- high if CRC error
	signal rxUnderrun : Std_Logic; -- high if byte not read in time
	signal rxAbort : Std_Logic; -- high if Abort received mid-frame
	
	signal clock: 	Std_Logic := '1';

	signal rxD, rxEn: Std_Logic;

	signal cycle : 	integer :=0;

	component hdlcreceiver is
	generic (
		rxReqChainSize  : integer := 2
	);
	port (
		-- microprocesser interface
		Dout :		out	Std_Logic_Vector (7 downto 0); -- rx register
		rxLast : 	out 	Std_Logic;
		rxRD : 		in	Std_Logic; -- read strobe
		rxReq : 	out	Std_Logic; -- high if data available
		rxErr : 	out Std_Logic; -- high if CRC error
		rxUnderrun : out Std_Logic; -- high if byte not read in time
		rxAbort : 	out Std_Logic; -- high if Abort received mid-frame

		rxRST :		in	Std_Logic;

		-- bit clock
		sysClk :	in	Std_Logic; -- 16MHz

		-- line interface
		rxD :		in	Std_Logic;
		rxEn :		buffer	Std_Logic
	);
	end component hdlcreceiver;

	type tDataItem is record
		rxD: 	Std_Logic;
		rxRST: 	Std_Logic;
		rxRD: 	Std_Logic;
	end record tDataItem;

	type tDataList is array (0 to 44) of tDataItem;

	constant dataList : tDataList := (
		-- test abort (10 values)
			('0','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
		-- test reset to abort clear (1 value)
			('0','1','0'),
		-- test flag detect (8 values)
			('0','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('0','0','0'),
		-- test inserted bit removal (9 values)
			('0','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('0','0','0'),
			('0','0','0'),
			('1','0','0'),
		-- test normal data -- 0xAA (8 values)
			('0','0','0'),
			('1','0','0'),
			('0','0','0'),
			('1','0','0'),
			('0','0','0'),
			('1','0','0'),
			('0','0','0'),
			('1','0','0'),
			-- test frame-end flag detect (8 values)
			('0','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('1','0','0'),
			('0','0','0')
);

begin

	iface : hdlcreceiver
	port map (
		Dout		 => q,
		rxLast		 => rxLast,
		rxRD		 => rxRd,
		rxReq		 => rxReq,
		rxErr 	 	 => rxErr,
		rxUnderrun 	 => rxUnderrun,
		rxAbort  	 => rxAbort,

		rxRST => rst,

		-- bit clock
		sysClk => clock,

		-- line interface
		rxD => rxD,
		rxEn => rxEn
	);

--	rst <= '1' after 0 ns, '0' after 100 ns; 
	process
	-- drive the txClock
	begin
	 		clock <= '0';
	 		wait for 62 ns;
	 		clock <= '1';
	 		wait for 63 ns;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
	 		cycle <= (cycle + 1) mod (64 * dataList'length);
	 		if cycle = 0 then
--	 			i <= (i(0) & i(7 downto 1)) xor "0" & i(0) & "00" & i(0) & "0" & i(0) & "0";
	 		end if;
	 		if (cycle mod 64) = 0 then
				rxD <= dataList(cycle/64).rxD;
				rst <= dataList(cycle/64).rxRST;
			end if;
		end if;
	end process;
end behavioural;