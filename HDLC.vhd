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

--entity HDLC is
--port (
--	-- microprocessor interface
--		Din :	in		Std_Logic_Vector (7 downto 0); -- Tx register
--		Dout :	out 	Std_Logic_Vector (7 downto 0); -- Rx register
--
--		TxWR : 	in	 	Std_Logic;
--		RxRD :	in		Std_Logic;
--
--		nRST :	in		Std_Logic;
--
--		-- nIRQ :	out		Std_Logic;
--
--	-- clock and data or transmitter and receiver
--		TxC :	in		Std_Logic;
--		RxC :	in		Std_Logic;
--		TxD :	out		Std_Logic;
--		RxD :	in		Std_Logic;
--
--	-- Peripheral/Modem control
--		-- these are connected directly to microcontroller I/O pins
--		-- nRTS :	out		Std_Logic;
--		-- nCTS :	in		Std_Logic;
--		-- nDCD :	in		Std_Logic;
--		-- nLOCnDTR : out	Std_Logic;
--
--	-- DMA interface
--		RDSR :	buffer	Std_Logic;  -- Rx FIFO requests service
--		TDSR :	out		Std_Logic;  -- Tx FIFO requests service
--
--	-- Control and status
--		L_back : buffer Std_Logic; -- sr1 b2 Loop / cr2b b5 Loop/Non-loop mode
--		FlgDet : buffer Std_Logic; -- sr1 b3 Flag detected (when enabled)
--		TxUrun : buffer Std_Logic  -- sr1 b5 TxUnderrun
--		-- b6 == TDRA -> Frame Complete
--
--	-- Status Reg 2
--		-- sr2 b0 Address Present
--		-- sr2 b1 Frame Valid
--		-- sr2 b2 Inactive Idle Received
--		-- sr2 b3 Abort Received
--		-- sr2 b4 FCS Error
--		-- sr2 b5 == nDCD
--		-- sr2 b6 Rx Overrun
--		-- sr2 b7 RDA (Receive data available)
--
--	-- Control Reg 1
--		-- cr1 b0 Address Control (AC)
--		-- cr1 b1 Rx Interrupt Enable RIE
--		-- cr1 b2 Tx Interrupt Enable TIE
--		-- cr1 b3 RDSR Mode (DMA)
--		-- cr1 b4 TDSR Mode (DMA)
--		-- cr1 b5 Rx Frame Discontinue
--		-- cr1 b6 Rx Reset
--		-- cr1 b7 Tx Reset
--
--	-- Control Reg 2a
--		-- cr2a b0 Rpioritised Status Enable
--		-- cr2a b1 2 byte/1 byte transfer
--		-- cr2a b2 Flag/Mark Idle
--		-- cr2a b3 Frame Complete/TDRA Select
--		-- cr2a b4 Transmit Last Data
--		-- cr2a b5 CLR Rx Status
--		-- cr2a b6 CLR Tx Status
--		-- cr2a b7 RTS control
--
--	-- Control Reg 2b
--		-- cr2b b0 Logical Control Field Select
--		-- cr2b b1 Extended Control Field Select
--		-- cr2b b2  Auto Address Extension Mode
--		-- cr2b b3 01/11 idel
--		-- cr2b b4 Flag Detected Status Enable
--		-- cr2b b6 Go Active on Poll/Test
--		-- cr2b b7 Loop On-line Control DTR
--
--	-- Control Reg 4
--		-- cr4 b0 Double Flag/Single Flag Interframe Control
--		-- cr4 b1 Word length Select Tx # 1
--		-- cr4 b2 Word length Select Tx # 2
--		-- cr4 b3 Word length Select Rx # 1
--		-- cr4 b4 Word length Select Rx # 2
--		-- cr4 b5 Tx Abort
--		-- cr4 b6 Abort Extend
--		-- cr4 b7 NRZI/NRZ
--
--	);
--end HDLC;
--
--architecture behavioural of HDLC is
--
--begin
--end behavioural;


entity HdlcTransmitter is
	port (
		-- microprocesser interface
		Din :	in		Std_Logic_Vector (7 downto 0); -- Tx register
		TxWR : 	in	 	Std_Logic;
		TxRq :  buffer	Std_Logic; -- high if space in register

		RST :	in		Std_Logic;

		-- bit clock
		TxCLK :	in		Std_Logic;

		-- line interface
		TxD :	out		Std_Logic;
		TxEn :	out		Std_Logic
	);
end HdlcTransmitter;

architecture behavioural of HdlcTransmitter is

	type txStateType is (TxRST, TxMarkIdle, TxF, TxA, TxC, TxLC, TxABT, TxI, TxFCS);
	signal txState, txNextState : txStateType;

	signal TxFIFO, TxShiftReg : Std_Logic_Vector (7 downto 0);
	signal TxBitCount : Std_Logic_Vector (2 downto 0);

	signal TxDataEnable : Std_Logic;

begin

	-- FIFO
	TxDataReg : process(RST, TxWR)
	begin
		if RST = '1' then
			TxFIFO <= "00000000";
			TxRq <= '1';
		elsif rising_edge(TxWR) then
			TxFIFO <= Din;
			TxRq <= '0';
		end if;
	end process TxDataReg;

	TxDataTx : process(RST, TxRq, TxCLK, TxDataEnable)
	begin
		if RST = '1' then
			TxBitCount <= "000";
		elsif rising_edge(TxCLK) then
			if TxBitCount = "000" and TxRq = '0' then
				TxShiftReg <= TxFIFO;
				TxRq <= '1';
			end if;
		end if;
	end process TxDataTx;

end behavioural;
