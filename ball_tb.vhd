library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ball_tb is 
end ball_tb;

architecture test of ball_tb is

component ball is
    generic (
        BALL_DIM      : integer := 16;
        BALL_H_START  : integer := 495;
        BALL_V_START  : integer := 368
    );
    port (
        hpos : in integer range 0 to 1023;
        vpos : in integer range 0 to 767;
        xspeed : in integer range -20 to 20;
        yspeed : in integer range -20 to 20;
        
        
        reset : in std_logic;
        clk : in std_logic;

        ref_tick : in std_logic;
        racket_active : in std_logic;
        poen : in std_logic;
        
        r_out, g_out, b_out : out std_logic_vector(7 downto 0);     
        
        
        ball_hpos   : out integer range -BALL_DIM to 1023 + BALL_DIM;
        ball_vpos   : out integer range -BALL_DIM to 767 + BALL_DIM;
        ball_valid  : out std_logic
    );
end component;

signal hpos : integer range 0 to 1023;
signal vpos : integer range 0 to 767;

signal reset : std_logic := '1';
signal clk : std_logic:= '0' ;
signal ref_tick : std_logic := '0';
signal racket_active : std_logic := '0';
signal xspeed : integer := 1;
signal yspeed : integer := 1;
signal poen : std_logic := '0';
signal Rout, Gout, Bout : std_logic_vector(7 downto 0);
signal ball_hpos   : integer range -16 to 1023 + 16;
signal ball_vpos   : integer range -16 to 767 + 16;
signal ball_valid  : std_logic;

constant CLK_PERIOD : time := 20 ns;

begin
    DUT: ball port map(
        hpos, vpos, xspeed, yspeed, poen, reset, clk, ref_tick, racket_active, Rout, Gout, Bout, ball_hpos, ball_vpos, ball_valid
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
		reset <= '1';
		wait for 1024 * 768 * CLK_PERIOD;
        reset <= '0';
        wait for 1024 * 768 * CLK_PERIOD;
		yspeed <= 5;
        xspeed <= 5;
		wait for 1024 * 768 * CLK_PERIOD;
        racket_active <= '1';
		wait for 2 * 1024 * 768 * CLK_PERIOD;
		xspeed <= 0;
		wait for 1024 * 768 * CLK_PERIOD;
		yspeed <= 9;
		wait;
	end process;
    
end test;