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
		rxLast : 	out Std_Logic; -- high if rx frame complete
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


	type rxState_type is (sReset, sIdle, sStartFlags, sRxData, sRxDone, sRxErr, sRxAbort, sRxUnderrun);

	type reg_type is record
		state :		rxState_type;
		-- registered outputs
		rxLast : 	Std_Logic; -- high if rx frame complete
		rxReq : 	Std_Logic; -- high if data available
		rxErr : 	Std_Logic; -- high if CRC error
		rxUnderrun : Std_Logic; -- high if byte not read in time
		rxAbort : 	Std_Logic; -- high if Abort received mid-frame
	end record;

	signal r, rin : reg_type;

	constant r0 : reg_type := (
		state => sReset,
		rxLast => '0',
		rxReq => '0',
		rxErr => '0',
		rxUnderrun => '0',
		rxAbort => '0'
	);

	-- translate_off
		-- stuff for debugging simulations
		signal stateDecode : integer;
		signal nextStateDecode : integer;
	-- translate_on

	signal debug_v : Std_Logic_Vector(2 downto 0);
	signal debug : Std_Logic := '0';

begin
	-- translate_off
		-- stuff for debugging simulations
		with r.state select
			stateDecode <=	0 when sReset,
							1 when sIdle,
							2 when sStartFlags,
							3 when sRxData,
							4 when sRxDone,
							5 when sRxErr,
							6 when sRxAbort,
							7 when sRxUnderrun;

		with rin.state select
		nextStateDecode <= 0 when sReset,
						1 when sIdle,
						2 when sStartFlags,
						3 when sRxData,
						4 when sRxDone,
						5 when sRxErr,
						6 when sRxAbort,
						7 when sRxUnderrun;
	-- translate_on

	-- *************** Main state machine ****************
	comb : process (bitCount, r)
	begin
		rxLast <= r.rxLast;
		rxReq <= r.rxReq;
		rxErr <= r.rxErr;
		rxUnderrun <= r.rxUnderrun;
		rxAbort <= r.rxAbort;

		case r.state is
			when sReset =>
				rin.state <= sIdle; -- held reset by reset, until released
				rin.rxErr <= r.rxErr;
				rin.rxUnderrun <= r.rxUnderrun;
				rin.rxAbort <= r.rxAbort;
			when sIdle =>
				if bitCount = "000" and flagRx = '1' then
					rin.state <= sStartFlags;
--				else
--					rin.state <= r.state;
				end if;
--				rin.rxErr <= r.rxErr;
--				rin.rxUnderrun <= r.rxUnderrun;
--				rin.rxAbort <= r.rxAbort;
			when sStartFlags =>
				if abortRx = '1' then
					rin.state <= sIdle;
				elsif bitCount = "000" and flagRx = '0' then
					rin.state <= sRxData;
				end if;
--				rin.rxErr <= r.rxErr;
--				rin.rxUnderrun <= r.rxUnderrun;
--				rin.rxAbort <= r.rxAbort;
			when sRxData =>
				if abortRx = '1' then
					rin.state <= sRxAbort;
				elsif bitCount = "000" and flagRx = '1' then
					rin.state <= sRxDone;
				else
--					rin.state <= r.state;
--					rin.rxErr <= r.rxErr;
--					rin.rxUnderrun <= r.rxUnderrun;
--					rin.rxAbort <= r.rxAbort;
				end if;
			when sRxDone | sRxErr | sRxAbort | sRxUnderrun => -- hold state until reset
--				rin.state <= r.state;
--				rin.rxErr <= r.rxErr;
--				rin.rxUnderrun <= r.rxUnderrun;
--				rin.rxAbort <= r.rxAbort;
		end case;

	end process comb;

	reg : process (bitClk, rxRST)
	begin
		if rxRST = '1' then
			r <= r0;
		elsif rising_edge(bitClk) and not skipBit then
			r <= rin; 
		end if;
	end process reg;

	-- *************** Clock recovery ********************

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

	-- ************* Data/flag recovery *****************

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
