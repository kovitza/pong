library ieee;
use ieee.std_logic_1164.all;


entity lfsr_6b is

	generic (   
		G_SEED: std_logic_vector(5 downto 0) := "101001"   
	);
	port (
		clk: in std_logic;
		reset: in std_logic;
		
		lfsr_out: out std_logic_vector(5 downto 0)     
	);

end entity lfsr_6b;

architecture RTL of lfsr_6b is

	signal lfsrOut: std_logic_vector(5 downto 0);

begin

lfsr_out <= lfsrOut;


GENERATE_PROC: process (clk, reset) is
begin
	if reset = '1' then
		lfsrOut <= G_SEED;
	else
		if rising_edge(clk) then
			lfsrOut(5) <= lfsrOut(0);
			lfsrOut(4) <= lfsrOut(5) xor lfsrOut(0);
			lfsrOut(3) <= lfsrOut(4);
			lfsrOut(2) <= lfsrOut(3);
			lfsrOut(1) <= lfsrOut(2);
			lfsrOut(0) <= lfsrOut(1);
		end if;
	end if;
end process GENERATE_PROC;

end architecture RTL;
