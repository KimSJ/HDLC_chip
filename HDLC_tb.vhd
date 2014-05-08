-- HDLC_tb.vhd

library IEEE;
use IEEE.STD_LOGIC_1164.All;

entity HDLC_tb is
end HDLC_tb;

architecture behavioural of HDLC_tb is

component HDLC
port (
	dOut : out Std_Logic_Vector (7 downto 0);
	dRdy : out Std_Logic
	);
end component;

signal A, B : Std_Logic_Vector (7 downto 0);
signal R    : Std_Logic;

begin
	u0: HDLC PORT MAP (B, R); 
	A   <= "00001000" after 0 ns,   "00000000" after 10 ns,  "00001111" after 20 ns,  "00001010" after 30 ns,  "00000000" after 50 ns,  "00000000" after 60 ns;

end behavioural;