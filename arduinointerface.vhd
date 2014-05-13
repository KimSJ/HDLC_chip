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

entity arduinointerface is
	port (
		-- arduino pins
		data:	inout Std_Logic_Vector (3 downto 0);
		strb:	in Std_Logic;
		RnW:	in Std_Logic;
		clk:	in Std_Logic;
		-- io pins
		q:		out Std_Logic_Vector (7 downto 0);
		i:		in  Std_Logic_Vector (7 downto 0)
	);
end arduinointerface;

architecture behavioural of arduinointerface is
	signal RnWin  : Std_Logic_Vector (2 downto 0); -- metastability chain -> shifting down (low bit is "last" value)
	signal strbin : Std_Logic_Vector (2 downto 0); -- metastability chain -> shifting down (low bit is "last" value)

	signal dout   : Std_Logic_Vector (3 downto 0); -- wire for 
begin
	process (clk, strb, RnW)
	begin
		if rising_edge(clk) then
			RnWin <= RnW & RnWin (RnWin'length-1 downto 1);
			strbin <= strb & strbin (strbin'length-1 downto 1);
			if strbin(0) /= strbin(1) then -- we have a strobe event
				if RnWin(1) = '0' then -- we are being written
					if strbin(1) = '1' then -- latch the high nibble
						q(7 downto 4) <= data;
					else -- latch the low nibble
						q(3 downto 0) <= data;
					end if;
				end if;
			end if;
		end if;
	end process;

	tristate : process (RnWin(1), strbin(1), data)	-- Behavioral representation
	begin							-- of tri-states.
		if RnWin(1) = '1' then -- we are being read
			if strbin(1) = '0' then -- read the low nibble
				data <= i(3 downto 0);
			else 					-- read the high nibble
				data <= i(7 downto 4);
			end if;
		else -- we are being written
			data <= "ZZZZ";
		end if;
	end process;

end behavioural;