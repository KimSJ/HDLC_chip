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

entity HdlcReceiver is
	generic (
		rxReqChainSize  : integer := 2 -- defines length of metastability chain; must be at least two.
	);
	port (
		-- microprocesser interface
		Dout :		out	Std_Logic_Vector (7 downto 0); -- rx register
		rxLast : 	out Std_Logic;
		rxRD : 		in	Std_Logic; -- read strobe
		rxReq : 	out	Std_Logic; -- high if data available

		rxRST :		in	Std_Logic;

		-- bit clock
		sysClk :	in	Std_Logic; -- 16MHz

		-- line interface
		rxD :		in	Std_Logic;
		rxEn :		buffer	Std_Logic
	);
-- translate_off
-- check bounds of generics -- error reported only on execution
begin
	assert( rxReqChainSize > 1 )
	report "rxReqChainSize should be at least 2!"
	severity ERROR;
-- translate_on
end HdlcReceiver;

architecture behavioural of HdlcReceiver is

	signal shiftReg :	Std_Logic_Vector (7 downto 0);
	signal bitClk :		Std_Logic;
	signal bitCount :	Std_Logic_Vector (2 downto 0);
	signal onesCount :	Std_Logic_Vector (2 downto 0);
	signal flagRx, abortRx : Std_Logic;

	signal clkDiv : Std_Logic_Vector(5 downto 0);
	signal data_change : boolean;
	signal data_was : Std_Logic := '1';
	signal skipBit : boolean;
	signal skippedBit : boolean;
	signal flagSpotted : boolean;


	function To_Std_Logic(L: BOOLEAN) return std_ulogic is 
    begin 
		if L then 
			return('1'); 
		else 
			return('0'); 
		end if; 
    end function To_Std_Logic;

    function IncrementSLV(V: Std_Logic_Vector) return Std_Logic_Vector is
    begin
    	return Std_Logic_Vector(unsigned(V) + unsigned'("1"));
	end function IncrementSLV;


begin
	pBitClk: process (sysClk)
		variable edge_detect : Std_Logic_Vector (2 downto 0);
	begin
		bitClk <= clkDiv(5);
		data_change <= data_was /= edge_detect(2) and data_was /= edge_detect(1) and data_was /= edge_detect(0);
		if rising_edge(sysClk) then
			edge_detect := rxD & edge_detect(2 downto 1);
			if data_change then
				clkDiv <= "000011";
				data_was <= not data_was;
			else
				clkDiv <= IncrementSLV(clkDiv);
			end if;
		end if;
	end process pBitClk;

	pShiftReg: process (bitClk, rxRST)
	begin
		skipBit <= shiftReg(7 downto 2) = "111110" and rxD = '0' and not skippedBit;
		flagSpotted <= onesCount = "110" and rxD = '0'; -- "01111110" received
		if rxRST='1' then
			shiftReg <= (others => '1');
			onesCount <= (others => '0');
			flagRx <= '0';
			abortRx <= '0';
			bitCount <= (others => '0');
		else		
			if rising_edge(bitClk) and not skipBit then
				shiftReg <= rxD & shiftReg(7 downto 1);
				if flagSpotted then
					bitCount <= "000";
				else
					bitCount <= incrementSLV(bitCount);
				end if;
				if bitCount <= "000" then
					Dout <= shiftReg;
				end if;
			end if;
			if rising_edge(bitClk) then
				skippedBit <= skipBit;
				if onesCount /= "111" then -- count to 7 then stop
					if rxD = '0' then
						onesCount <= "000";
					else
						onesCount <= Std_Logic_Vector(unsigned(onesCount) + unsigned'("1"));
					end if;
				end if;
				flagRx <= To_Std_Logic(flagSpotted); -- latch flag spotted
				abortRx <= To_Std_Logic((onesCount = "110" and rxD = '1') or onesCount = "111"); -- seven or more '1's received
			end if;
		end if;

	end process pShiftReg;

end behavioural;
