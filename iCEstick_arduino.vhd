-- iCEcube top-level file
-- Generic file for iCEstick
--
-- Notes:
--	OSCI is 12 MHz on pin 2 of USB chip

--
library IEEE;
use IEEE.STD_LOGIC_1164.All;

entity iCEstick_arduino is
	port (
		-- J1 ("top")
			PIO0_02 :							inout Std_Logic;	-- J1 p3  
			PIO0_03 :							inout Std_Logic;	-- J1 p4  
			PIO0_04 :							inout Std_Logic;	-- J1 p5  
			PIO0_05 :							inout Std_Logic;	-- J1 p6  
			PIO0_06 :							inout Std_Logic;	-- J1 p7  
			PIO0_07 :							inout Std_Logic;	-- J1 p8  
			PIO0_08 :							inout Std_Logic;	-- J1 p9  
			PIO0_09 :							inout Std_Logic;	-- J1 p10 

		-- J2 (Pmod socket)
			PIO1_02 :							inout Std_Logic;	-- connector p1
			PIO1_03 :							inout Std_Logic;	-- connector p2
			PIO1_04 :							inout Std_Logic;	-- connector p3
			PIO1_05 :							inout Std_Logic;	-- connector p4
			PIO1_06 :							inout Std_Logic;	-- connector p7 
			PIO1_07 :							inout Std_Logic;	-- connector p8 
			PIO1_08 :							inout Std_Logic;	-- connector p9 
			PIO1_09 :							inout Std_Logic;	-- connector p10

		-- J3 ("bottom")
			PIO2_17 :							inout Std_Logic;	-- J3 p3  
			PIO2_16 :							inout Std_Logic;	-- J3 p4  
			PIO2_15 :							inout Std_Logic;	-- J3 p5  
			PIO2_14 :							inout Std_Logic;	-- J3 p6  
			PIO2_13 :							inout Std_Logic;	-- J3 p7  
			PIO2_12 :							inout Std_Logic;	-- J3 p8  
			PIO2_11 :							inout Std_Logic;	-- J3 p9  
			PIO2_10 :							inout Std_Logic;	-- J3 p10 

		-- LED port
			-- red LEDs numbered clockwise
			LED1 :								inout Std_Logic;	-- PIO1_14 Red
			LED2 :								inout Std_Logic;	-- PIO1_13 Red
			LED3 :								inout Std_Logic;	-- PIO1_12 Red
			LED4 :								inout Std_Logic;	-- PIO1_11 Red
			-- green LED
			LED5 :								inout Std_Logic;	-- PIO1_10 Green

		-- IrDA
			RXD :					 			inout Std_Logic;	-- PIO1_19 Receive data pin
			TXD :					 			inout Std_Logic;	-- PIO1_18 Transmit data pin
			SD :					  			inout Std_Logic;	-- PIO1_20 Shut down

		-- RS232 (connection to USB chip)
			RS232_Rx_TTL :						inout Std_Logic;
			RS232_Tx_TTL :						inout Std_Logic;
			RTSn :								inout Std_Logic;
			DTRn :								inout Std_Logic;
			CTSn :								inout Std_Logic;
			DSRn :								inout Std_Logic;
			DCDn :								inout Std_Logic;

		-- SPI/Config
			SPI_SCK :							inout Std_Logic;
			SPI_SI :							inout Std_Logic;
			SPI_SO :							inout Std_Logic;
			SPI_SS_B :							inout Std_Logic;
			CDONE :							 	inout Std_Logic;
			CREST :						 		inout Std_Logic;

		-- pin 21 is driven from iCE_CLK -- 12MHz osc.
		clk :								 inout Std_Logic

		);
end iCEstick_arduino;

architecture behavioural of iCEstick_arduino is

	component arduinointerface is
		port (
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
	end component arduinointerface;
begin

	top : arduinointerface
	port map (
			-- arduino pins on the Pmod socket
			data(0)	=>	PIO1_02,
			data(1)	=>	PIO1_03,
			data(2)	=>	PIO1_04,
			data(3)	=>	PIO1_05,
			strb 	=>	PIO1_06,
			RnW 	=>	PIO1_07,
			clk 	=>	PIO1_08,
			rst 	=>	PIO1_09,
			-- io pins
			rd 		=>	PIO2_11, -- J3 p9
			wr 		=>	PIO2_10,  -- J3 p10

			q(7)	=>	PIO2_17,
			q(6)	=>	PIO2_16,
			q(5)	=>	PIO2_15,
			q(4)	=>	LED5,
			q(3)	=>	LED4,
			q(2)	=>	LED3,
			q(1)	=>	LED2,
			q(0)	=>	LED1, -- J3 and LEDs

			i(7)	=>	PIO0_09,
			i(6)	=>	PIO0_08,
			i(5)	=>	PIO0_07,
			i(4)	=>	PIO0_06,
			i(3)	=>	PIO0_05,
			i(2)	=>	PIO0_04,
			i(1)	=>	PIO0_02,
			i(0)	=>	PIO0_02 -- J1
	);

end behavioural;










