-- hdlctransmitter.vhd
--
-- takes 8-bit parallel data and sends frame
-- Frame ends when data value is written with "txLast" set.

library IEEE;
use IEEE.STD_LOGIC_1164.All;
use IEEE.NUMERIC_STD.all;
-- debug libraries
use std.textio.all;
use ieee.std_logic_textio.all;

entity HdlcTransmitter is
	generic (
		TxReqChainSize  : integer := 2 -- defines length of metastability chain; must be at least two.
	);
	port (
		-- microprocesser interface
		Din :	in		Std_Logic_Vector (7 downto 0); -- Tx register
		txLast : in 	Std_Logic;
		txWR : 	in	 	Std_Logic;
		txReq : out		Std_Logic; -- high if space in register

		txRST :	in		Std_Logic;

		-- bit clock
		txCLK :	in		Std_Logic;

		-- line interface
		txD :	buffer	Std_Logic;
		txEn :	buffer	Std_Logic
	);
-- translate_off
-- check bounds of generics -- error reported only on execution
begin
	assert( txReqChainSize > 1 )
	report "txReqChainSize should be at least 2!"
	severity ERROR;
-- translate_on
end HdlcTransmitter;

architecture behavioural of HdlcTransmitter is

	type txStateType is (Idle, StartFlag, SendData, SendLast, SendCRC1, SendCRC2, FinalFlag);
	signal txState, txNextState : txStateType;

	signal txFIFO, txShiftReg : Std_Logic_Vector (7 downto 0);
	signal txBitCount : Std_Logic_Vector (2 downto 0);
	signal txOneCount : Std_Logic_Vector (2 downto 0);

	signal txShiftEnable : Std_Logic;
	signal txShiftClk, dontSwallow: Std_Logic;

	signal txRq : Std_Logic_Vector (txReqChainSize-1 downto 0); 	-- shifted through to minimise metastability;
													-- 0 means reg is full
													-- processor watches top bit, HDLC watches bit 0
	-- calculate an initialisation vector for txRq chain (all-ones)
    signal txReqChainEmpty : Std_Logic_Vector (txReqChainSize-1 downto 0) := (others => '1');

	signal crcReg : Std_Logic_Vector (15 downto 0) := x"AAAA";
	signal zeroIns : Std_Logic; -- output of state machine indicating that zero insertion after five 1's is active

	-- handy alias
	signal DataWaiting : boolean;

	component crc16 is 
		port (clk, reset, ce, din: in std_logic; 
			  crc_sum: out std_logic_vector(15 downto 0)); 
	end component crc16;
	signal txCrcEn : Std_Logic;
	signal crcReset : Std_Logic;

	-- translate_off
		-- stuff for debugging simulations
		signal stateDecode : integer;
		signal nextStateDecode : integer;
	-- translate_on



begin
	-- translate_off
		-- stuff for debugging simulations
		process (txState) begin
			if txState = Idle then
				stateDecode <= 0;	
			elsif txState = StartFlag then
				stateDecode <= 1;
			elsif txState = SendData then
				stateDecode <= 2;
			elsif txState = SendLast then
				stateDecode <= 3;
			elsif txState = SendCRC1 then
				stateDecode <= 4;
			elsif txState = SendCRC2 then
				stateDecode <= 5;
			elsif txState = FinalFlag then
				stateDecode <= 6;
			end if;
		end process;
		process (txNextState) begin
			if txNextState = Idle then
				nextStateDecode <= 0;	
			elsif txNextState = StartFlag then
				nextStateDecode <= 1;
			elsif txNextState = SendData then
				nextStateDecode <= 2;
			elsif txNextState = SendLast then
				nextStateDecode <= 3;
			elsif txNextState = SendCRC1 then
				nextStateDecode <= 4;
			elsif txNextState = SendCRC2 then
				nextStateDecode <= 5;
			elsif txNextState = FinalFlag then
				nextStateDecode <= 6;
			end if;
		end process;
	-- translate_on

	txReq <= txRq(txReqChainSize-1) AND NOT txRST; -- use top bit so it appears full to processor as soon as reg is written. De-assert when reset
	txD <= txShiftReg(0);
	DataWaiting <= txRq(0) = '0';

	-- pulse dontSwallower: removes a txCLK pulse when zero insertion required
	txShiftClk <= txClk and dontSwallow;
	pTxShiftClk : process(txCLK, txOneCount)
	begin
		if falling_edge(txCLK) then
			if txOneCount="100" and txD = '1' and zeroIns = '1' then
				dontSwallow <= '0';
			else
				dontSwallow <= '1';
			end if;
		end if;
	end process pTxShiftClk;

	-- latching data into tx holding reg (FIFO)
	pTxFIFO : process(txRST, txWR)
	begin
		if txRST = '1' then
			txFIFO <= "00000000";
		elsif rising_edge(txWR) then
			txFIFO <= Din;
		end if;
	end process pTxFIFO;

	-- txEn
	pTxEn : process(txRST, txCLK)
	begin
		if txRST = '1' then
			txEn <= '0';
		elsif rising_edge(txCLK) then
			if txState = Idle then 
				txEn <= '0';
			else
				txEn <= '1';
			end if;
		end if;
	end process pTxEn;

	-- ZeroIns
	pZeroIns : process(txRST, txCLK)
	begin
		if txRST = '1' then
			zeroIns <= '0';
		elsif rising_edge(txCLK) then
			case txState is
				when Idle | StartFlag | FinalFlag => zeroIns <= '0';
				when others =>zeroIns <= '1';
			end case;
		end if;
	end process pZeroIns;

	-- generate Tx request signal for processor
	pTxRq : process(txRST, txWR, txCLK)
	begin
		if txRST = '1' then
			txRq <= txReqChainEmpty; -- mark reg empty
		elsif rising_edge(txWR) then
			txRq (txReqChainSize-1) <= '0'; -- insert "full" signal at top of metastab chain
		elsif rising_edge(txCLK) and dontSwallow = '1' then
			if txBitCount = "000" and (txState = SendData OR txState = SendLast) then -- loading byte into shift reg
				txRq <= txReqChainEmpty; -- signal that we've taken the data
			else
				txRq(txReqChainSize-2 downto 0) <= txRq(txReqChainSize-1 downto 1); -- shift the "full" signal through metastab chain
			end if;
		end if;
	end process pTxRq;

	-- mark where crc should be calculated
	process (txState, txShiftClk)
	begin
		if rising_edge(txShiftClk) then
			if txState = SendData or txState = SendLast then
				txCrcEn <= '1';
				crcReset <= '0';
			else
				txCrcEn <= '0';
				if txState = idle then
					crcReset <='1';
				else
					crcReset <='0';
				end if;
			end if;
		end if;
	end process;


	-- calculate CRC -- instantiate CRC engine
	TxCrcGen : crc16  
	port map (  clk => txShiftClk,
				reset => crcReset,
				ce => txCrcEn,
				din => txD,
				crc_sum => crcReg
			); 


	-- ******* Main state machine *********
	-- register
	process(txShiftClk, txRST)
	-- clocked on bit count rolling over (8 bits tx'd)
	begin
		if txRST = '1' then
			txState <= Idle;
		elsif rising_edge(txShiftClk) then
			if txBitCount = "000" then
				txState <= txNextState;
			else
				txState <= txState;
			end if;
		end if;
	end process;

	-- state register inputs
	process
		( DataWaiting, txState -- 
		 )
	begin
		case txState is
			when Idle =>
				if DataWaiting then
					txNextState <= StartFlag;
				else
					txNextState <= Idle;
				end if;
			when StartFlag =>
				txNextState <= SendData;
			when SendData =>
				if txLast = '1' then
					txNextState <= SendLast;
				else
					txNextState <= SendData;
				end if;
			when SendLast =>
				txNextState <= SendCRC1;
			when SendCRC1 =>
				txNextState <= SendCRC2;
			when SendCRC2 =>
				txNextState <= FinalFlag;
			when FinalFlag =>
				txNextState <= Idle;
		end case;
	end process;

	-- clocking data into shift reg (out of tx holding reg, CRC, flag or abort)
	pTxData : process(txRST, txRq, txCLK, txShiftEnable)
	begin
		if txRST = '1' then
			txBitCount <= "000";
		elsif rising_edge(txCLK) then
			if txOneCount = "100" and txD ='1' and ZeroIns = '1' then
				txShiftReg(0) <= '0';
				-- note we're not incrementing the bit count whilst we insert the extra zero
			else
				txBitCount <= Std_Logic_Vector(unsigned(txBitCount) + 1); -- increment bit count
				if txBitCount = "000" and dontSwallow = '1' then -- we've reached a byte boundary
					case txState is
						when Idle | StartFlag | FinalFlag =>
							txShiftReg <= "01111110";
						when SendData | SendLast =>
							if txRq(0) = '1' then
								-- we have underrun
								-- TODO: insert underrun handling
							else
								-- load in next byte
								txShiftReg <= txFIFO;
							end if;
						when SendCRC1 => 
							txShiftReg <= crcReg (15 downto 8);
						when SendCRC2 =>
							txShiftReg <= crcReg (7 downto 0);
					end case;
				else -- we need to shift out next bit
					txShiftReg (6 downto 0) <= txShiftReg (7 downto 1);
				end if;
			end if;
		end if;
	end process pTxData;

	-- Ones counter counts successive ones when enabled
	pTxOneCount : process(txCLK, txRST, txEn)
	begin
		if txRST = '1' OR txEn = '0' then
			txOneCount <= "000";
		elsif rising_edge(txCLK) then
			if txShiftReg (0) = '0' then
				txOneCount <= "000";
			else
				txOneCount <= Std_Logic_Vector(unsigned(txOneCount) + 1);
			end if;
		end if;
	end process pTxOneCount;			

end behavioural;
