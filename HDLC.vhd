-- HDLC.vhd
--
-- The internal of the original 68B54, exposed
-- however, only implements the functionality needed
--
-- Frame data format
--
--  FLAG | Dest Addr (16 bits) | Src Addr (16 bits) | Data (may be empty) | CRC (16 bits) | FLAG


library IEEE;
use IEEE.STD_LOGIC_1164.All;

entity HDLC is
port (
	-- microprocessor interface
		Din :	in		Std_Logic_Vector (7 downto 0); -- Tx register
		Dout :	out 	Std_Logic_Vector (7 downto 0); -- Rx register

		TxWR : 	in	 	Std_Logic;
		RxRD :	in		Std_Logic;

		nRST :	in		Std_Logic;

		-- nIRQ :	out		Std_Logic;

	-- clock and data or transmitter and receiver
		TxC :	in		Std_Logic;
		RxC :	in		Std_Logic;
		TxD :	out		Std_Logic;
		RxD :	in		Std_Logic;

	-- Peripheral/Modem control
		-- these are connected directly to microcontroller I/O pins
		-- nRTS :	out		Std_Logic;
		-- nCTS :	in		Std_Logic;
		-- nDCD :	in		Std_Logic;
		-- nLOCnDTR : out	Std_Logic;

	-- DMA interface
		RDSR :	buffer	Std_Logic;  -- Rx FIFO requests service
		TDSR :	out		Std_Logic;  -- Tx FIFO requests service

	-- Control and status
		L_back : buffer Std_Logic; -- sr1 b2 Loop / cr2b b5 Loop/Non-loop mode
		FlgDet : buffer Std_Logic; -- sr1 b3 Flag detected (when enabled)
		TxUrun : buffer Std_Logic  -- sr1 b5 TxUnderrun
		-- b6 == TDRA -> Frame Complete

	-- Status Reg 2
		-- sr2 b0 Address Present
		-- sr2 b1 Frame Valid
		-- sr2 b2 Inactive Idle Received
		-- sr2 b3 Abort Received
		-- sr2 b4 FCS Error
		-- sr2 b5 == nDCD
		-- sr2 b6 Rx Overrun
		-- sr2 b7 RDA (Receive data available)

	-- Control Reg 1
		-- cr1 b0 Address Control (AC)
		-- cr1 b1 Rx Interrupt Enable RIE
		-- cr1 b2 Tx Interrupt Enable TIE
		-- cr1 b3 RDSR Mode (DMA)
		-- cr1 b4 TDSR Mode (DMA)
		-- cr1 b5 Rx Frame Discontinue
		-- cr1 b6 Rx Reset
		-- cr1 b7 Tx Reset

	-- Control Reg 2a
		-- cr2a b0 Rpioritised Status Enable
		-- cr2a b1 2 byte/1 byte transfer
		-- cr2a b2 Flag/Mark Idle
		-- cr2a b3 Frame Complete/TDRA Select
		-- cr2a b4 Transmit Last Data
		-- cr2a b5 CLR Rx Status
		-- cr2a b6 CLR Tx Status
		-- cr2a b7 RTS control

	-- Control Reg 2b
		-- cr2b b0 Logical Control Field Select
		-- cr2b b1 Extended Control Field Select
		-- cr2b b2  Auto Address Extension Mode
		-- cr2b b3 01/11 idel
		-- cr2b b4 Flag Detected Status Enable
		-- cr2b b6 Go Active on Poll/Test
		-- cr2b b7 Loop On-line Control DTR

	-- Control Reg 4
		-- cr4 b0 Double Flag/Single Flag Interframe Control
		-- cr4 b1 Word length Select Tx # 1
		-- cr4 b2 Word length Select Tx # 2
		-- cr4 b3 Word length Select Rx # 1
		-- cr4 b4 Word length Select Rx # 2
		-- cr4 b5 Tx Abort
		-- cr4 b6 Abort Extend
		-- cr4 b7 NRZI/NRZ

	);
end HDLC;

architecture behavioural of HDLC is

begin
end behavioural;

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
		LastByte : in 	Std_Logic;
		TxWR : 	in	 	Std_Logic;
		TxReq : out		Std_Logic; -- high if space in register

		TxRST :	in		Std_Logic;

		-- bit clock
		TxCLK :	in		Std_Logic;

		-- line interface
		TxD :	out		Std_Logic;
		TxEn :	buffer	Std_Logic
	);
-- translate_off
-- check bounds of generics -- error reported only on execution
begin
	assert( TxReqChainSize > 1 )
	report "TxReqChainSize should be at least 2!"
	severity ERROR;
-- translate_on
end HdlcTransmitter;

architecture behavioural of HdlcTransmitter is

	type txStateType is (Idle, StartFlag, SendData, SendLast, SendCRC1, SendCRC2, FinalFlag);
	signal txState, txNextState : txStateType;

	signal TxFIFO, TxShiftReg : Std_Logic_Vector (7 downto 0);
	signal TxBitCount : Std_Logic_Vector (2 downto 0);
	signal TxOneCount : Std_Logic_Vector (2 downto 0);

	signal TxShiftEnable : Std_Logic;

	-- calculate an initialisation vector for TxReqChain (all-ones)
--    constant TxReqChainEmpty : Std_Logic_Vector (TxReqChainSize-1 downto 0) := Std_Logic_Vector(to_signed(-1,TxReqChainSize));
    signal TxReqChainEmpty : Std_Logic_Vector (TxReqChainSize-1 downto 0) := Std_Logic_Vector(to_signed(-1,TxReqChainSize));

	signal TxRq : Std_Logic_Vector (TxReqChainSize-1 downto 0); 	-- shifted through to minimise metastability;
													-- 0 means reg is full
													-- processor watches top bit, HDLC watches bit 0
	signal crcReg : Std_Logic_Vector (15 downto 0);
	signal zeroIns : Std_Logic; -- output of state machine indicating that zero insertion after five 1's is active

	-- handy alias
	signal DataWaiting : boolean;

	-- translate_off
	signal stateDecode : integer;
	signal nextStateDecode : integer;
	-- translate_on

begin
	-- translate_off
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

	TxReq <= TxRq(TxReqChainSize-1); -- use top bit so it appears full to processor as soon as reg is written
	TxD <= TxShiftReg(0);
	DataWaiting <= TxRq(0) = '0';

	-- latching data into Tx holding reg (FIFO)
	TxDataReg : process(TxRST, TxWR)
	begin
		if TxRST = '1' then
			TxFIFO <= "00000000";
		elsif rising_edge(TxWR) then
			TxFIFO <= Din;
		end if;
	end process TxDataReg;

	pTxRq : process(TxRST, TxWR, TxCLK)
	begin
		if TxRST = '1' then
			TxRq <= TxReqChainEmpty; -- mark reg empty
		elsif rising_edge(TxWR) then
			TxRq (TxReqChainSize-1) <= '0'; -- insert "full" signal at top of metastab chain
		elsif rising_edge(TxCLK) then
			if TxBitCount = "000" and (TxState = SendData OR TxState = SendLast) then -- loading byte into shift reg
				TxRq <= TxReqChainEmpty; -- signal that we've taken the data
			else
				TxRq(TxReqChainSize-2 downto 0) <= TxRq(TxReqChainSize-1 downto 1); -- shift the "full" signal through metastab chain
			end if;
		end if;
	end process pTxRq;

	-- ******* Main state machine *********
	-- register
	process(TxBitCount(2), TxRST)
	-- clocked on bit count rolling over (8 bits tx'd)
	begin
		if TxRST = '1' then
			TxState <= Idle;
		elsif falling_edge(TxBitCount(2)) then
			TxState <= txNextState;
		end if;
	end process;

	-- state register inputs
	process
		( DataWaiting -- 
		 )
	begin
		case TxState is
			when Idle =>
				if DataWaiting then
					TxNextState <= StartFlag;
				else
					TxNextState <= Idle;
				end if;
			when StartFlag =>
				TxNextState <= SendData;
			when SendData =>
				if LastByte = '1' then
					TxNextState <= SendLast;
				else
					TxNextState <= SendData;
				end if;
			when SendLast =>
				TxNextState <= SendCRC1;
			when SendCRC1 =>
				TxNextState <= SendCRC2;
			when SendCRC2 =>
				TxNextState <= FinalFlag;
			when FinalFlag =>
				TxNextState <= Idle;
		end case;
	end process;

	-- clocking data into shift reg (out of Tx holding reg, CRC, flag or abort)
	TxDataTx : process(TxRST, TxRq, TxCLK, TxShiftEnable)
	begin
		if TxRST = '1' then
			TxBitCount <= "000";
			TxOneCount <= "000";
		elsif rising_edge(TxCLK) then
			if TxOneCount = "101" AND ZeroIns = '1' then
				TxShiftReg(0) <= '0';
				TxOneCount <= "000";
				-- note we're not incrementing the bit count whilst we insert the extra zero
			else
				TxBitCount <= Std_Logic_Vector(unsigned(TxBitCount) + 1); -- increment bit count
				if TxBitCount = "000" then -- we've reached a byte boundary
					case TxState is
						when Idle => null;
						when StartFlag | FinalFlag =>
							TxShiftReg <= "01111110";
						when SendData | SendLast =>
							if TxRq(0) = '1' then
								-- we have underrun
								-- TODO: insert underrun handling
							else
								-- load in next byte
								TxShiftReg <= TxFIFO;
							end if;
						when SendCRC1 => 
							TxShiftReg <= crcReg (15 downto 8);
						when SendCRC2 =>
							TxShiftReg <= crcReg (7 downto 0);
					end case;
				else -- we need to shift out next bit
					TxShiftReg (6 downto 0) <= TxShiftReg (7 downto 1);
				end if;
			end if;
		end if;
	end process TxDataTx;

	-- Ones counter counts successive ones when enabled
	pTxOneCount : process(TxCLK, TxRST, TxEn)
	begin
		if TxRST = '1' OR TxEn = '0' then
			TxOneCount <= "000";
		elsif rising_edge(TxCLK) then
			if TxShiftReg (0) = '0' then
				TxOneCount <= "000";
			else
				TxOneCount <= Std_Logic_Vector(unsigned(TxOneCount) + 1);
			end if;
		end if;
	end process pTxOneCount;			

end behavioural;
