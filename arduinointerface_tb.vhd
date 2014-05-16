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

entity arduinointerface_tb is

end entity arduinointerface_tb;

architecture behavioural of arduinointerface_tb is
	signal RnW  : Std_Logic := '1';
	signal strb : Std_Logic := '1';
	signal clock: Std_Logic;
	signal	rst:  Std_Logic :='1';
	
	signal bidir : Std_Logic_Vector (3 downto 0) := "ZZZZ"; -- the databus 

	signal rd, wr: Std_Logic;
	signal q, i	:  Std_Logic_Vector (7 downto 0) := x"A5"; -- i is the values read on input, q is values output by write

	signal cycle : integer :=0;

	component arduinointerface is
		port (
			-- arduino pins
			data:	inout Std_Logic_Vector (3 downto 0);
			strb:	in Std_Logic;
			RnW:	in Std_Logic;
			clk:	in Std_Logic;
			rst:	in Std_Logic;
				-- io pins
			rd, wr: out Std_Logic;
			q:		out Std_Logic_Vector (7 downto 0);
			i:		in  Std_Logic_Vector (7 downto 0)
		);
	end component arduinointerface;

	subtype nibble is Std_Logic_Vector(3 downto 0);

	type tDataItem is record
		d: nibble;
		RnW, strb: Std_Logic; 
	end record tDataItem;

	type tDataList is array (0 to 5) of tDataItem;

	constant dataList : tDataList := (
		-- d, RnW, strb
		-- read cycle
		("ZZZZ", '1', '1'),
		("ZZZZ", '1', '0'),
		("ZZZZ", '1', '1'),
		-- write cycle
		("ZZZZ", '0', '1'),
		("0001", '0', '0'),
		("0010", '0', '1')
		);

begin

	iface : arduinointerface
	port map (
		data => bidir,
		strb => strb,
		RnW => RnW,
		clk => clock,
		rst => rst,

		rd => rd,
		wr => wr,
		q => q,	
		i => i	
	);

	rst <= '1' after 0 ns, '0' after 100 ns; 
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
	 		cycle <= (cycle + 1) mod (10 * dataList'length);
	 		if cycle = 0 then
	 			i <= (i(0) & i(7 downto 1)) xor "0" & i(0) & "00" & i(0) & "0" & i(0) & "0";
	 		end if;
	 		if (cycle mod 10) = 0 then
				bidir <= dataList(cycle/10).d;
				RnW   <= dataList(cycle/10).RnW;
				strb  <= dataList(cycle/10).strb;
			end if;
		end if;
	end process;

end behavioural;