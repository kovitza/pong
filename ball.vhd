-------------------------------------------------------------------------------------------------------------------------------
--Trebalo bi da je fajl koji iscrtava i pomera REKET
-- moram ubaciti signal koalizije odnosno da izbacim signal reket valid 
-------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ball is
    generic (
        BALL_DIM      : integer := 32;
        BALL_H_START  : integer := 495;
        BALL_V_START  : integer := 368
    );
    port (
        hpos : in integer range 0 to 1023;
        vpos : in integer range 0 to 767;
        hspeed : in integer range -20 to 20;
        vspeed : in integer range -20 to 20;
        
        reset   : in std_logic;
        clk     : in std_logic;

        ref_tick        : in std_logic;     --moving_active treba koristiti kao enable signal za lopticu 
        moving_active   : in std_logic;     --game_start iz game govori da niko nije stisnuo nista
        
      
        ball_hpos   : out integer range -BALL_DIM to 1023 + BALL_DIM;   --signali potrebni za odbijanje od reketa
        ball_vpos   : out integer range -BALL_DIM to 767 + BALL_DIM;
        ball_valid  : out std_logic     --potreban za iscrtavanje
    );
end ball;
--treba da stoji na stoji na sredini pre nego sto neko pipne dugme
--treba da stoji na sredini kad neko da poen
architecture Behavioral of ball is
	
	signal ball_xpos  : integer range -BALL_DIM to 1023 + BALL_DIM;
	signal ball_ypos  : integer range -BALL_DIM to 767 + BALL_DIM;
-- signal racket_was_active : std_logic := '0';
    
--    type State_t is (init, push);
--	signal next_state, state_reg: State_t;
    
    --signal temp : std_logic;

begin

--  NEPOTREBNO ZBOG RAMA
--	r_out <= BALL_COLOR(23 downto 16);
--	g_out <= BALL_COLOR(15 downto 8);
--	b_out <= BALL_COLOR(7 downto 0);
    
	--OVO BI TREBALO DA ISCRTAVA LOPTICU
	ball_valid <= '1' when ((hpos > ball_xpos and hpos <= ball_xpos + BALL_DIM) and 
                            (vpos > ball_ypos and vpos <= ball_ypos + BALL_DIM)) 
                else'0';
    
process(clk, reset)
begin   
	if (reset = '1') then       --KAD JE RESET 1 ONDA CRTA LOPTICU NA POCETNOJ POZICIJI
		ball_ypos <= BALL_V_START;
        ball_xpos <= BALL_H_START;
       -- temp <= '0';
	elsif (rising_edge(clk)) then
--        if moving_active = '1' then
--            temp <='1';
--        end if;
        
        if (ref_tick = '1') then            --ZNACI KRAJ FREJMA
            if moving_active = '1' then
                ball_xpos <= ball_xpos + hspeed;    --kaze da je neki reket bio aktivan i nastavlja sa pomeranjem
                ball_ypos <= ball_ypos + vspeed;
                --temp <= '0';
            else                          --U slucaju da je moving_active = '0' i da je racket_was_active '0', 
                ball_ypos <= BALL_V_START;      --To znaci da nije pocela partija i lopta bi trebalo da ostane na sredini
                ball_xpos <= BALL_H_START;
            end if;
        end if;
    end if;
end process;

ball_hpos <= ball_xpos;
ball_vpos <= ball_ypos;
 
end Behavioral;
