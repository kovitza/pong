LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;    

use ieee.std_logic_textio.all;
use std.textio.all;                            

ENTITY game_tb IS
END game_tb;
ARCHITECTURE Test OF game_tb IS


constant CLK_PERIOD : time := 20 ns  ;
constant VGA_CLK_PERIOD : time := 15.3846 ns  ;                                               
-- signals                                                   
SIGNAL clk_50MHz : STD_LOGIC :='1';
signal reset: std_logic := '1';

signal button_left_up: std_logic := '1';
signal button_left_down: std_logic := '1';
signal button_right_up: std_logic := '1';
signal button_right_down: std_logic := '1';

signal clk_out: std_logic;
signal hsync: std_logic;
signal vsync: std_logic;
signal sync_n: std_logic;
signal blank_n: std_logic;

signal Rout: std_logic_vector(7 downto 0);
signal Gout: std_logic_vector(7 downto 0);
signal Bout: std_logic_vector(7 downto 0);
		
signal points_left: std_logic_vector(6 downto 0);
signal points_right: std_logic_vector(6 downto 0);

component game is

		port (
			clk_50MHz: in std_logic;
            reset: in std_logic;
		
            button_left_up      : in std_logic;
            button_left_down    : in std_logic;
            button_right_up     : in std_logic;
            button_right_down   : in std_logic;
            
            clk_out : out std_logic;
            hsync   : out std_logic;
            vsync   : out std_logic;
            sync_n  : out std_logic;
            blank_n : out std_logic;
            
            Rout    : out std_logic_vector(7 downto 0);
            Gout    : out std_logic_vector(7 downto 0);
            Bout    : out std_logic_vector(7 downto 0);
            
            points_left : out std_logic_vector(6 downto 0);
            points_right: out std_logic_vector(6 downto 0)
		);

	end component game;
BEGIN
	DUT: game
		port map (
			clk_50MHz => clk_50MHz,
			reset => reset,
			
			button_left_up      => button_left_up,
			button_left_down    => button_left_down,
			button_right_up     => button_right_up,
			button_right_down   => button_right_down,
			
			clk_out => clk_out,
			hsync   => hsync,
			vsync   => vsync,
			sync_n  => sync_n,
			blank_n => blank_n,
            
			Rout => Rout,
			Gout => Gout,
			Bout => Bout,
			
			points_left => points_left,
            points_right => points_right
		);

clk_50MHz <= not clk_50MHz after CLK_PERIOD/2;                                           

always : PROCESS                                    
BEGIN                                                         
	reset <= '1';
	wait for CLK_PERIOD;
	reset <= '0';
--	wait for 5*VGA_CLK_PERIOD;
	wait for 17 ms;
   	button_right_up <= '0';
	wait for 100 ms;
	button_right_up <= '1';
	wait for 3*VGA_CLK_PERIOD;
	button_left_down <= '0';
	wait for 3*17 ms;
	button_left_down <= '1';
	button_right_up <= '0';
	wait for 4*17 ms;
	button_left_down <= '0';
	button_left_down <= '0';
	wait for 17 ms;
	button_left_down <= '1';
	WAIT;                                                        
END PROCESS always;  

process (clk_out)
    file file_pointer: text open WRITE_MODE is "D:\Fax\7. semestar\UPV\dimitrije\vga_signals.txt";
    variable line_el: line;
begin

    if rising_edge(clk_out) then

        -- Write the time
        --write(line_el, now); -- write the line.
	write(line_el, now/ns); -- write the line.
	write(line_el, string'(" ns:"));-- write the line.

        -- Write the hsync
        write(line_el, string'(" "));
        write(line_el, std_logic(hsync)); -- write the line.

        -- Write the vsync
        write(line_el, string'(" "));
        write(line_el, std_logic(vsync)); -- write the line.

        -- Write the red
        write(line_el, string'(" "));
        write(line_el, std_logic_vector(Rout)); -- write the line.

        -- Write the green
        write(line_el, string'(" "));
        write(line_el, std_logic_vector(Gout)); -- write the line.

        -- Write the blue
        write(line_el, string'(" "));
        write(line_el, std_logic_vector(Bout)); -- write the line.

        writeline(file_pointer, line_el); -- write the contents into the file.

    end if;
end process;
                                        
END Test;
