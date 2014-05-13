------------------------------------------------------------------------- 
-- 16-bit Serial CRC-CCITT Generator. 
------------------------------------------------------------------------- 
library ieee; 

use ieee.std_logic_1164.all; 

entity crc16 is 
	port (clk, reset, ce, din: in std_logic; 
		  crc_sum: out std_logic_vector(15 downto 0)); 
end crc16; 
       
architecture behavior of crc16 is 
    signal X: std_logic_vector(15 downto 0); 
    
begin 
	reg:process(reset, clk, ce) 
	begin 
	if reset = '1' then 
		X <= (others => '1'); 
	elsif ce = '1' then 
		if falling_edge(clk) then
			X(0)  <= Din  xor X(15); 
			X(1)  <= X(0); 
			X(2)  <= X(1); 
			X(3)  <= X(2); 
			X(4)  <= X(3); 
			X(5)  <= X(4) xor (din xor X(15)); 
			X(6)  <= X(5); 
			X(7)  <= X(6); 
			X(8)  <= X(7); 
			X(9)  <= X(8); 
			X(10) <= X(9); 
			X(11) <= X(10); 
			X(12) <= X(11) xor (din xor X(15)); 
			X(13) <= X(12); 
			X(14) <= X(13); 
			X(15) <= X(14); 
	   end if; 
	end if; 
	end process; 
	crc_sum <= X; 
end behavior;