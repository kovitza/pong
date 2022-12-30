library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity racket_tb is 
end racket_tb;

architecture test of racket_tb is
component racket is
    generic (
    RACKET_DIM      : integer := 8;
	RACKET_H_START  : integer := 10;
	RACKET_V_START  : integer := 368
    );
    port (
        hpos : in integer range 0 to 1023;
        vpos : in integer range 0 to 767;
        
        reset : in std_logic;
        clk : in std_logic;
        move_up : in std_logic;
        move_down: in std_logic;
        ref_tick : in std_logic;
        R_out, G_out, B_out : out std_logic_vector(7 downto 0);  
--        racket_hpos  : out integer range -RACKET_DIM to 1023 + RACKET_DIM;
--        racket_vpos  : out integer range -RACKET_DIM to 767 + RACKET_DIM;    
        racket_valid : out std_logic
    );
end component;

signal hpos : integer range 0 to 1023;
signal vpos : integer range 0 to 767;

signal reset : std_logic := '1';
signal clk : std_logic:= '0' ;
signal ref_tick : std_logic := '0';

signal move_up : std_logic := '1';
signal move_down : std_logic:= '1';

signal Rout, Gout, Bout : std_logic_vector(7 downto 0);
signal racket_valid : std_logic;

signal racket_hpos : integer range -8 to 1031;
signal racket_vpos : integer range -8 to 775;

constant CLK_PERIOD : time := 20 ns;

begin
    DUT: racket port map(
        hpos, vpos, reset, clk, move_up, move_down, ref_tick, Rout, Gout, Bout, --racket_hpos, racket_vpos, 
        racket_valid
    );
    
clk <= not clk after CLK_PERIOD/2;

POS_GENERATE: process (clk) is
	begin
		if rising_edge(clk) then
			if hpos = 1023 then
				hpos <= 0;
				if vpos = 767 then
					vpos <= 0;
				else
					vpos <= vpos + 1;
				end if;
			else
				hpos <= hpos + 1;
			end if;
		end if;
end process POS_GENERATE;
	
REF_TICK_GENERATE: process (hpos, vpos) is
	begin
		if hpos = 1023 and vpos = 767 then
			ref_tick <= '1';
		else
			ref_tick <= '0';
		end if;
end process REF_TICK_GENERATE;

STIMULUS: process is
	begin
		wait for 3 * CLK_PERIOD;
		reset <= '0';
		wait for 1024 * 768 * CLK_PERIOD;
		move_down <= '0';
		wait for 1024 * 768 * CLK_PERIOD;
		move_down <= '1';
		wait for 1024 * 768 * CLK_PERIOD;
		move_down <= '0';
--		wait for CLK_PERIOD;
--		move_down <= '1';

--		wait for 1024 * 768 * CLK_PERIOD;
--		move_down <= '0';
--		wait for 1024 * 768 * CLK_PERIOD;
--		move_down <= '1';
		wait;
	end process;
    
end test;