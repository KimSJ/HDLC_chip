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
--		read the value of b3..b0
--		set strb 1 (11 = command "read high-nibble)
--		read the value of b7..b4 in the low bits of the data you read.
-- for multi-byte reads, repeat last four steps
-- Note: always read the low nibble first, because the high nibble is latched at the same time
			-- make sure you wait at least three cycles between writes and reads:
			-- 	OUT <port>, <regA>
			--	ORI <regA>, 0x10				// take the opportunity to set up next out value 
			--	NOP
			--	IN <regB>, <port>				// read the low nibble
			--  OUT <port>, <regA>				// set up hi nibble read
			--  ANDI <regB>, 0x0F				// extract low nibble
			--	ANDI <regA>, 0xEF				// take the opportunity to set up next out value 
			--	IN <regC>, <port>				// read the high nibble
			--	ANDI <regC>, 0x0F
			--	SWAP
			--  OR <RegC>, <RegB>				// build the byte
			--	<store it>
			--	<check for more data available, then loop>
		-- this code should be able to input about one byte/microsecond with 16MHz processor.

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
		rst:	in Std_Logic;
		-- io pins
		rd, wr: out Std_Logic := '0';
		q:		out Std_Logic_Vector (7 downto 0);
		i:		in  Std_Logic_Vector (7 downto 0)
	);
end arduinointerface;

architecture behavioural of arduinointerface is
	signal RnWin  : Std_Logic_Vector (2 downto 0); -- metastability chain -> shifting down (low bit is "last" value)
	signal strbin : Std_Logic_Vector (2 downto 0); -- metastability chain -> shifting down (low bit is "last" value)

	signal dout   : Std_Logic_Vector (3 downto 0); -- latch for high nibble when low nibble is read
begin

	process (clk, strb, RnW, rst)
	begin
		if rst = '1' then
			wr <= '0';
			rd <= '0';
			RnWin <= (others => '0');
			strbin <= (others => '0');
			q <= (others => '0');
			dout <= (others => '0');
		elsif rising_edge(clk) then
			-- strobes output for use by peripheral, indicating a read or write has taken place.
			wr <= (strbin(1) and not strbin(0)) and not RnWin(1); -- positive-going write pulse edge generated when second nibble written
			rd <= (strbin(1) and not strbin(0)) and RnWin(1);	  -- poistive-going read pulse generated when host requests second nibble

			-- shift the metastability chains down
			RnWin <= RnW & RnWin (RnWin'length-1 downto 1);
			strbin <= strb & strbin (strbin'length-1 downto 1);

			-- deal with strobe events
			if strbin(1) /= strbin(0) then -- we have a strobe event
				if RnWin(1) = '0' then -- we are being written
					if strbin(1) = '1' then -- latch the high nibble
						q(7 downto 4) <= data;
					else -- latch the low nibble
						q(3 downto 0) <= data;
					end if;
				else
					if strbin(1) = '0' then -- we're reading the low nibble, so...
						dout <= i(7 downto 4); -- ... latch the high nibble at the same time
					end if;
				end if;
			end if;
		end if;
	end process;

	tristate : process (RnWin(1), strbin(1), data)	-- Behavioral representation of tri-states.
	begin											-- pattern from http://www.altera.co.uk/support/examples/vhdl/v_bidir.html
		if RnWin(1) = '1' then -- we are being read
			if strbin(1) = '0' then -- read the low nibble
				data <= i(3 downto 0);
			else 					-- read the high nibble
				data <= dout;
			end if;
		else -- we are being written
			data <= "ZZZZ";
		end if;
	end process;

end behavioural;