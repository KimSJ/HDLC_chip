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
			LastByte : in 	Std_Logic;
			TxWR : 	in	 	Std_Logic;
			TxReq : out		Std_Logic; -- high if space in register

			TxRST :	in		Std_Logic;

			-- bit clock := '0'
			TxCLK :	in		Std_Logic;

			-- line interface := '0'
			TxD :	out		Std_Logic;
			TxEn :	buffer	Std_Logic
		);
	end component HdlcTransmitter;

	signal 	Din :	Std_Logic_Vector (7 downto 0); -- Tx register
	signal	LastByte : Std_Logic := '0';
	signal	TxWR : 	Std_Logic := '0';
	signal	TxReq : Std_Logic; -- high if space in register

	signal	TxRST :	Std_Logic := '0';

	-- bit clock
	signal	TxCLK :	Std_Logic;

	-- line interface
	signal	TxD :	Std_Logic;
	signal	TxEn :	Std_Logic;



begin
	transmitter : HdlcTransmitter PORT MAP (Din, LastByte, TxWR , TxReq, TxRST, TxCLK, TxD, TxEn);

process
begin
 		txCLK <= '0';
 		wait for 20 us;
 		txCLK <= '1';
 		wait for 20 us;
end process;		

	TxRST <= '0' after 0 us, '1' after 1 us, '0' after 2 us;
	TxWR <= '0' after 0 us, '1' after 10 us, '0' after 11 us;
	Din   <= "00001000" after 0 us,   "00000000" after 100 us,  "00001111" after 200 us,  "00001010" after 300 us,  "00000000" after 500 us,  "00000000" after 600 us;


end behavioural;