-- HDLC_orig.vhd
--
-- The chip pins and register bits of the original 68B54
--


library IEEE;
use IEEE.STD_LOGIC_1164.All;

entity HDLC is
port (
	-- microprocessor input
	D :		inout 	Std_Logic_Vector (7 downto 0);
	E : 	in	 	Std_Logic;	-- system clock
	nCS :	in		Std_Logic;
	RS :	in		Std_Logic_Vector (1 downto 0);
	RnW :	in		Std_Logic;
	nRST :	in		Std_Logic;
	nIRQ :	out		Std_Logic;

	-- clock and data or transmitter and receiver
	TxC :	in		Std_Logic;
	RxC :	in		Std_Logic;
	TxD :	out		Std_Logic;
	RxD :	in		Std_Logic;

	-- Peripheral/Modem control
	nRTS :	out		Std_Logic;
	nCTS :	in		Std_Logic;
	nDCD :	in		Std_Logic;
	nLOCnDTR : out	Std_Logic;

	-- DMA interface
	RDSR :	buffer	Std_Logic; -- Rx FIFO requests service
	TDSR :	out		Std_Logic  -- Tx FIFO requests service
	);
end HDLC;

architecture behavioural of HDLC is

	-- Status Reg 1
		-- b0 RDA == RDSR
		-- b1 == Status #2 Read request
		-- b2 Loop
		-- b3 Flag detected (when enabled)
		-- b4 == nCTS
		-- b5 TxUnderrun
		-- b6 == TDRA -> Frame Complete
		-- b7 IRQ Present

	-- Status Reg 2
		-- b0 Address Present
		-- b1 Frame Valid
		-- b2 Inactive Idle Received
		-- b3 Abort Received
		-- b4 FCS Error
		-- b5 == nDCD
		-- b6 Rx Overrun
		-- b7 RDA (Receive data available)

	-- Control Reg 1
		-- b0 Address Control (AC)
		-- b1 Rx Interrupt Enable RIE
		-- b2 Tx Interrupt Enable TIE
		-- b3 RDSR Mode (DMA)
		-- b4 TDSR Mode (DMA)
		-- b5 Rx Frame Discontinue
		-- b6 Rx Reset
		-- b7 Tx Reset

	-- Control Reg 2a
		-- b0 Rpioritised Status Enable
		-- b1 2 byte/1 byte transfer
		-- b2 Flag/Mark Idle
		-- b3 Frame Complete/TDRA Select
		-- b4 Transmit Last Data
		-- b5 CLR Rx Status
		-- b6 CLR Tx Status
		-- b7 RTS control

	-- Control Reg 2b
		-- b0 Logical Control Field Select
		-- b1 Extended Control Field Select
		-- b2  Auto Address Extension Mode
		-- b3 01/11 idel
		-- b4 Flag Detected Status Enable
		-- b5 Loop/Non-loop mode
		-- b6 Go Active on Poll/Test
		-- b7 Loop On-line Control DTR

	-- Control Reg 4
		-- b0 Double Flag/Single Flag Interframe Control
		-- b1 Word length Select Tx # 1
		-- b2 Word length Select Tx # 2
		-- b3 Word length Select Rx # 1
		-- b4 Word length Select Rx # 2
		-- b5 Tx Abort
		-- b6 Abort Extend
		-- b7 NRZI/NRZ


	signal 
begin
end behavioural;