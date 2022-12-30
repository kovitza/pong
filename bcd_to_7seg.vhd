library ieee;
use ieee.std_logic_1164.all;

entity bcd_to_7seg is

	port (
		digit : in std_logic_vector(3 downto 0);
		
		display : out std_logic_vector(6 downto 0)
	);

end entity bcd_to_7seg;

architecture Behavioral of bcd_to_7seg is

begin
	process (digit) is
	begin
		case digit is
			when "0000" => display <= not "0111111";    --0
			when "0001" => display <= not "0000110";    --1
			when "0010" => display <= not "1011011";    --2
			when "0011" => display <= not "1001111";    --3
			when "0100" => display <= not "1100110";    --4
			when "0101" => display <= not "1101101";    --5
			when "0110" => display <= not "1111101";    --6
			when "0111" => display <= not "0000111";    --7
			when "1000" => display <= not "1111111";    --8
			when "1001" => display <= not "1101111";    --9
			when others => display <= not "1111111";    --off
		end case;
	end process;
end architecture Behavioral;