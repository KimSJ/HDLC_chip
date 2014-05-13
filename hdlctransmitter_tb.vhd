library IEEE;
use IEEE.STD_LOGIC_1164.All;
use IEEE.NUMERIC_STD.all;
-- debug libraries
use std.textio.all;
use ieee.std_logic_textio.all;

entity HdlcTransmitter_tb is
end HdlcTransmitter_tb;

architecture behavioural of HdlcTransmitter_tb is

	component HdlcTransmitter is
		generic (
			TxReqChainSize  : integer := 2 -- defines length of metastability chain; must be at least two.
		);
		port (
			-- microprocesser interface
			Din :	in		Std_Logic_Vector (7 downto 0); -- Tx register
			TxLast : in 	Std_Logic;
			TxWR : 	in	 	Std_Logic;
			TxReq : out		Std_Logic; -- high if space in register

			TxRST :	in		Std_Logic;

			-- bit clock := '0'
			TxCLK :	in		Std_Logic;

			-- line interface := '0'
			TxD :	buffer	Std_Logic;
			TxEn :	buffer	Std_Logic
		);
	end component HdlcTransmitter;

	signal 	Din :	Std_Logic_Vector (7 downto 0); -- Tx register
	signal	TxLast : Std_Logic := '0';
	signal	TxWR : 	Std_Logic := '0';
	signal	TxReq : Std_Logic; -- high if space in register

	signal	TxRST :	Std_Logic := '0';

	-- bit clock
	signal	TxCLK :	Std_Logic;

	-- line interface
	signal	TxD :	Std_Logic;
	signal	TxEn :	Std_Logic;

	signal byteCount : integer := 0;


begin
	transmitter : HdlcTransmitter PORT MAP (Din, TxLast, TxWR , TxReq, TxRST, TxCLK, TxD, TxEn);

	process
	-- drive the txClock
	begin
	 		txCLK <= '0';
	 		wait for 20 us;
	 		txCLK <= '1';
	 		wait for 20 us;
	end process;		

	TxRST <= '0' after 0 us, '1' after 1 us, '0' after 2 us;

	process (TxReq)
	-- write another byte
	type tDataStream is array (0 to 6) of Std_Logic_Vector(7 downto 0);
	variable dataStream : tDataStream :=
		(
			x"AA",
			x"00",
			x"3C",
			x"FF",
			x"0F",
			x"F0",
			x"55"
		);
	begin
		if rising_edge(TxReq) then
		byteCount <= (byteCount + 1) mod 7;
			if byteCount > 5 then
				TxLast <= '1';
			end if;
			Din <= datastream(byteCount);
			TxWR <= '1' after 10 ns, '0' after 100 ns;
		end if;
	-- Din   <= "00001000" after 0 us,   "00000000" after 100 us,  "00001111" after 200 us,  "00001010" after 300 us,  "00000000" after 500 us,  "00000000" after 600 us;
	end process;


end behavioural;