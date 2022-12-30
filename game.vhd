-------------------------------------------------------------------------------------------------------------------------------
--Projekat 14. PONG
--Luka Kovandzic
--
--
--Igru je potrebno restartovati da bi igraci igrali opet
--ZA SUTRA UBACITI RAM MEMORIJU
--SREDITI BALL
--UBACITI LFSR  
-------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity game is 
    port (
        clk_50MHz   : in std_logic;
		reset       : in std_logic;
		
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
end game;

architecture rtl of game is 

component racket is
    generic (
        RACKET_DIM      : integer := 16;
        RACKET_H_START  : integer := 10;
        RACKET_V_START  : integer := 368
    );
    port (
        hpos : in integer range 0 to 1023;
        vpos : in integer range 0 to 767;
        
        reset : in std_logic;
        clk : in std_logic;
        
        move_up  : in std_logic;
        move_down: in std_logic;
        
        ref_tick : in std_logic; 
        racket_hpos  : out integer range -RACKET_DIM to 1023 + RACKET_DIM;
        racket_vpos  : out integer range -RACKET_DIM to 767 + RACKET_DIM;  
        racket_valid : out std_logic
    );
end component;

component ball is
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

        ref_tick        : in std_logic;
        moving_active   : in std_logic;
        
        ball_hpos   : out integer range -BALL_DIM to 1023 + BALL_DIM;
        ball_vpos   : out integer range -BALL_DIM to 767 + BALL_DIM;
        ball_valid  : out std_logic
    );
end component;

component vga_sync is
	generic (
		-- Default display mode is 1024x768@60Hz
		-- Horizontal line
		H_SYNC	    : integer := 136;		-- sync pulse in pixels
		H_BP		: integer := 160;		-- back porch in pixels
		H_FP		: integer := 24;		-- front porch in pixels
		H_DISPLAY   : integer := 1024;	-- visible pixels
		-- Vertical line
		V_SYNC	    : integer := 6;		-- sync pulse in pixels
		V_BP		: integer := 29;		-- back porch in pixels
		V_FP		: integer := 3;		-- front porch in pixels
		V_DISPLAY   : integer := 768		-- visible pixels
	);
	port (
		clk     : in std_logic;
		reset   : in std_logic;
        
		hsync, vsync    : out std_logic;
		sync_n, blank_n : out std_logic;
        
		hpos : out integer range 0 to H_DISPLAY - 1;
		vpos : out integer range 0 to V_DISPLAY - 1;
        
		Rin, Gin, Bin       : in std_logic_vector(7 downto 0);
		Rout, Gout, Bout    : out std_logic_vector(7 downto 0);
		
        ref_tick : out std_logic
	);
end component;

component pll is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic         -- outclk0.clk
	); 
end component;

component bcd_to_7seg is

	port (
		digit : in std_logic_vector(3 downto 0);
		
		display : out std_logic_vector(6 downto 0)
	);

end component;

component lfsr_6b is

	generic (   
		G_SEED: std_logic_vector(5 downto 0) := "101001"   
	);
	port (
		clk: in std_logic;
		reset: in std_logic;
		
		lfsr_out: out std_logic_vector(5 downto 0)     
	);

end component;


component racketRom is
	port
	(
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
end component;

component ballRom is
	port
	(
		address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
end component;

    --VGA SIGNALI
    signal hpos: integer range 0 to 1023;                   
	signal vpos: integer range 0 to 767;
	
	signal Rin: std_logic_vector(7 downto 0);
	signal Gin: std_logic_vector(7 downto 0);
	signal Bin: std_logic_vector(7 downto 0);
	
	signal clk      : std_logic;
	signal ref_tick : std_logic;                            --SIGNAL KOJI SE GENERISE ZA KRAJ FREJMA
    
    --NEKI GLOBALNI KORISNI SIGNALI
    constant RACKET_DIMC : integer := 16;                   --KONSTANTE ZA VELICINU LOPTE I REKETA
    constant BALL_DIMC   : integer := 32;
	
    signal poen : std_logic := '0';                         --GOVORI DA JE U PARTIJI ZADAT POEN i trebalo bi da zavrsi rundu
    signal poenL, poenR  : integer range 0 to 9;            --OVO BI TREBALO DA SU POENI ZA IGRACE
    
    signal game_start   : std_logic := '0';                      --game_start = neko je nesto pritisnuo igra pocinje 
    signal game_end     : std_logic := '1';                      --game_end = neki igrac je sakupio 9 poena
                         
    type State_t is (init, moving);                     --TREBALO BI DA JE MASINA STANJA, INIT SVE STOJI, MOVING JE DOK NEKO
    signal next_state, state_reg, state_hold: State_t;  --state_hold drzi pocetnu vrednost sve do sledeceg ref_tick
    signal state_num : std_logic;           --bice 0 ako je u init-u, 1 ako je u moving stanju
   
    --BCD SIGNALI
    signal dig_left  : std_logic_vector(3 downto 0);        --ULAZ U bcd_to_7seg logiku
    signal dig_right : std_logic_vector(3 downto 0);
    
    --SIGNALI ZA REKETE 
    signal Left_racket_valid : std_logic;  
    signal Right_racket_valid : std_logic;
    signal left_hpos : integer range -32 to 1023 + 32;
    signal left_vpos : integer range -32 to 1023 + 32;
    signal right_hpos : integer range -32 to 1023 + 32;
    signal right_vpos : integer range -32 to 1023 + 32;
     
    --SIGNALI ZA LOPTICU    
    signal ball_hpos : integer range -BALL_DIMC to 1023 + BALL_DIMC;
    signal ball_vpos : integer range -BALL_DIMC to 767 + BALL_DIMC;
    
    signal xspeed, yspeed  : integer range -20 to 20;                --INPUT LOPTICE
    signal xspeed_ball, yspeed_ball  : integer range -20 to 20;      --SIGNALI KOJI SE GENERISU UPOTREBOM LFSR
    signal xspeed_ball1, xspeed_ball2, yspeed_ball1, yspeed_ball2 : std_logic_vector (5 downto 0);
    
    signal ball_valid       : std_logic;
--    signal racket_is_active : std_logic   ;           --SIGNAL KOJI JE 1 AKO SE NEKI OD REKETA U TOM TRENUTKU POMERA
                                                        --NE TREBA MI OVAJ SIGNAL JER IMAM GAME_START
    signal R_ball: std_logic_vector(7 downto 0);
	signal G_ball: std_logic_vector(7 downto 0);
	signal B_ball: std_logic_vector(7 downto 0);
   
   
--  signali za ROM memorije
    signal datamemBall, datamemRacket: std_logic_vector(11 downto 0);			
	signal addressLeft, addressRight, address_temp: unsigned(10 downto 0);
    signal addressBall : unsigned(9 downto 0);
begin

--instanciranje PLL i VGA
PLL_inst: pll port map (clk_50MHz, reset, clk);

VGASYNC: vga_sync port map (clk, reset, hsync, vsync, sync_n, blank_n, hpos, vpos, Rin, Gin, Bin, Rout, Gout, Bout, ref_tick);

--Instanciranje LOPTE
ball_inst: ball generic map(BALL_DIM => 32, BALL_H_START =>495, BALL_V_START =>368)  --bilo na 495, 368
    port map(hpos, vpos, xspeed, yspeed, reset, clk, ref_tick, state_num , ball_hpos, ball_vpos, ball_valid);  
                                                            --ovde je iznad bio game_start
--INSTANCIRANJE REKETA, dodeljeni lefti right RGB kao i racket valid signali
left_racket : racket generic map (RACKET_DIM => 16,   RACKET_H_START => 10,   RACKET_V_START => 320) 
    port map (hpos, vpos, reset, clk, button_left_up, button_left_down, ref_tick, left_hpos, left_vpos, Left_racket_valid); 
    
right_racket : racket generic map (RACKET_DIM => 16,   RACKET_H_START => 997,   RACKET_V_START => 320)
    port map (hpos, vpos, reset, clk, button_right_up, button_right_down, ref_tick, right_hpos, right_vpos, Right_racket_valid); 

--    racket_is_active <= not(button_left_down and button_left_up and button_right_down and button_right_up);

--INSTANCIRANJE ISPISA NA 7 SEG DISPLAY
LEFT_BCD: bcd_to_7seg port map (dig_left, points_left);
RIGHT_BCD: bcd_to_7seg port map (dig_right, points_right);

--INSTANCIRANJE LFSR
xspeed_ball_gen1: lfsr_6b generic map ("101001")
		port map (clk, reset, xspeed_ball1);
--INSTANCIRANJE LFSR
xspeed_ball_gen2: lfsr_6b generic map ("010101")
		port map (clk, reset, xspeed_ball2);
--INSTANCIRANJE LFSR
yspeed_ball_gen1: lfsr_6b generic map ("110100")
		port map (clk, reset, yspeed_ball1);
--INSTANCIRANJE LFSR
yspeed_ball_gen2: lfsr_6b generic map ("100110")
		port map (clk, reset, yspeed_ball2);

--INSTANCIRANJE ROM MEMORIJA       
ballMem: ballRom port map (std_logic_vector(addressBall), clk, datamemBall);
racketMem: racketRom port map (std_logic_vector(address_temp), clk, datamemRacket);
 
--TREBALO BI DA SAMO ISPISE BCD 
    dig_left    <= std_logic_vector(to_unsigned(poenL, 4)); -- 4bit ulaz 
    dig_right   <= std_logic_vector(to_unsigned(poenR, 4)); -- 4bit ulaz
    
    clk_out <= clk;         --samo izbacivanje 65 MHz
    
    --DODELJIVANJE RANDOM VREDNOSTI BRZINI LOPTE
    xspeed_ball <= to_integer(unsigned(xspeed_ball1(5 downto 2))) + to_integer(unsigned(xspeed_ball2(1 downto 0))) - 9;
    yspeed_ball <= to_integer(unsigned(yspeed_ball1(5 downto 2))) + to_integer(unsigned(yspeed_ball2(1 downto 0))) - 9;
    
    STATE_TRANSITION: process (clk, reset) is
	begin
		if reset = '1' then
			state_reg <= init;      --PO RESETU NALAZIMO SE U POCETNOM STANJU
            state_hold <= init;
        else
			if rising_edge(clk) then
				if game_end = '1' then  --AKO JE NEKI IGRAC SAKUPIO 9 POENA VRACAMO SE NA POCETAK
					state_reg <= init;
				else
					state_reg <= next_state;
--                    if ref_tick = '1' then
--                        state_reg <= next_state;       --proveriti da ne mora mozda state_reg --JA PROMENIO NA STATE_REG
--                    end if;                             --ne bi trebalo da mora state_reg zato sto je gore vec dodeljen
				end if;
                if ref_tick = '1' then
                    state_hold <= state_reg;
--                else
--                    state_hold 
                end if;
			end if;
		end if;
	end process STATE_TRANSITION;
    
--PROBA LOGIKE ZA ODBIJANJE
    NEXT_STATE_LOGIC: process (next_state, state_reg, state_hold, game_start, poen, state_num) is
    begin
        case state_reg is 
            when init =>
                if game_start = '1' then
                    if state_hold = init then
                        next_state <= moving;
                    else
                        next_state <= init;
                    end if;
                else                    --Ovo bi trebalo da udje u moving kad je racket_is_active i da ostane u moving dok
                    next_state <= init; --neko ne da poen. Ako niko nije pomerao reket na pocetku runde treba da ostane u init
                end if;
                state_num <= '0';
            when moving =>              --TREBALO BI DA SE VRTI U MOVING SVE DOK NEKO NE DA POEN
                if poen = '1' then
                    next_state <= init;
                    --poen <= '0'; ne moze ovde dodela
                else
                    next_state <= moving;       
                end if;
                state_num <= '1';
        end case;
    end process NEXT_STATE_LOGIC;    
    
    
  --DODELJIVANJE BRZINE LOPTICE
--    BALL_MOVING: process(clk, reset, game_end, poen) is
--    begin
--        if rising_edge(clk) then
--            if ((reset = '1') or (game_end = '1') or (poen = '1')) then
--                xspeed <= 0;
--                yspeed <= 0;
--            elsif (poen = '1') then
--                xspeed <= xspeed_ball;      --OVDE TREBA UBACITI RENDOM BRZINU
--                yspeed <= yspeed_ball;
--            end if;
--        end if;
--    end process BALL_SPEED_PROC;
    
    
    REBOUND_LOGIC: process(clk, state_reg, xspeed, yspeed, poen, reset, poenL, poenR, ball_hpos, ball_vpos) is
    begin
        if reset = '1' then
            xspeed <= 0; yspeed <= 0;                                   --SVE BRZINE I SVI POENI SU 0
            poenL <= 0; poenR <= 0;                                     
            poen <= '0';
        elsif rising_edge(clk) then
            if (poen = '1') then      --AKO JE POEN ili RESET ili GAME_END = 1
                if (game_end = '1') then
                    poenL <= 0; poenR <= 0;
                end if;     --AKO JE POEN 1 AUTOMATSKI SALJEM xspeed i yspeed KAO 0 U BALL
                xspeed <= 0; yspeed <= 0;                                   --SVE BRZINE I SVI POENI SU 0                                   
                if ref_tick = '1' then
                    poen <= '0';
                end if;
            --    ball_vpos <= BALL_V_START; ball_hpos <= BALL_H_START;     --LOPTICA SE VRACA NA SREDINU TJ POCETAK
            else                                                            --Ovo bi trebalo u ball ubaciti
                case state_reg is
                    when init =>
                        if next_state = moving then --ovde treba dodeliti one rendom brzine
                            if xspeed_ball = 0 then
                                xspeed <= xspeed_ball + 5;  --nije bas random, ali ako se desi
                            else
                                xspeed <= xspeed_ball;
                            end if;
                            yspeed <= yspeed_ball;
                        end if;
                        poen <= '0';
                    when moving =>
--                        ODBIJANJE OD DESNOG REKETA:
--UKOLIKO LOPTICA IDE KA DOLE DESNO:REKET SE KRECE NA GORE, LOPTICA DOBIJA KAO BACKSPIN I SPORIJE CE ICI PO Y 
--                                  REKET SE KRECE NA DOLE, LOPTICA DOBIJA TOPSPIN I BRZE IDE PO Y OSI
--                                  REKET SE NE KRECE, LOPTICA SE SAMO ODBIJA po x
--PRETPOSTAVLJAM DA SE KOD MOZE DOSTA SMANJITI ALI NE UMEM
--LEPO JE REKLA JELENA POPOVIC BOZOVIC, KOD VISESTRUKIH IF THEN ELSOVA KORISTITI CASE NAREDBU DA BI SE SINTETISALO MANJE HARDVERA 
--LOGIKA ZA ODBITAK JE ISTA SAMO URADJENA ZA SVA 4 SLUCAJA
                        if ball_valid = '1' then
                            if ((ball_hpos >= 965) and (xspeed > 0) and (yspeed >= 0) and (right_racket_valid = '1')) then
                                if (button_right_up = '0') then
                                    xspeed <= - xspeed; 
                                    yspeed <= yspeed - 10;  
                                elsif (button_right_down = '0') then
                                    xspeed <= - xspeed;
                                    yspeed <= yspeed + 5;   
                                elsif ((button_right_down = '1') and (button_right_up = '1')) then
                                    xspeed <= -xspeed;
                                end if;
                                
                                --OVDE STALI, UBACITI ball_valid
                                
                                
                            elsif ((ball_hpos >= 965) and (xspeed > 0) and (yspeed <= 0) and (right_racket_valid = '1')) then 
                                if (button_right_up = '0') then
                                    xspeed <= - xspeed;
                                    yspeed <= yspeed - 5;
                                elsif (button_right_down = '0') then
                                    xspeed <= - xspeed;
                                    yspeed <= yspeed + 10;
                                elsif ((button_right_down = '1') and (button_right_up = '1')) then
                                    xspeed <= -xspeed;
                                end if;
 
--ODBITAK LEVI REKET ISTA LOGIKA KAO ZA DESNI                
                            elsif ((ball_hpos <= 25) and (xspeed < 0) and (yspeed >= 0) and (left_racket_valid = '1')) then
                                if (button_left_up = '0') then
                                    xspeed <= - xspeed;
                                    yspeed <= yspeed - 10;
                                elsif (button_left_down = '0') then
                                    xspeed <= - xspeed;
                                    yspeed <= yspeed + 5;
                                elsif ((button_left_down = '1') and (button_left_up = '1')) then
                                    xspeed <= -xspeed;
                                end if;
                            elsif ((ball_hpos <= 25) and (xspeed < 0) and (yspeed <= 0) and (left_racket_valid = '1')) then 
                                if (button_left_up = '0') then
                                    xspeed <= - xspeed;
                                    yspeed <= yspeed - 5;
                                elsif (button_left_down = '0') then
                                    xspeed <= - xspeed;
                                    yspeed <= yspeed + 10;
                                elsif ((button_right_down = '1') and (button_right_up = '1')) then
                                    xspeed <= -xspeed;
                                end if;
                                
--OVAJ DEO JE KADA LOPTICA PRODJE REKET I REKET JE UDARI COSKOM                           
--                            elsif (((ball_hpos >= 967) and (xspeed > 0)) or ((ball_hpos <= 25) and (xspeed < 0))) then
----                                if (left_racket_valid = '1') or (right_racket_valid = '1') then                      
----                                    xspeed <= -xspeed/3;  
----                                    yspeed <= -3*yspeed;
                            elsif ((ball_hpos >= 1013) and (xspeed > 0) and (poen = '0')) then
                                poenL <= poenL + 1;
                                poen <= '1';
                            elsif ((ball_hpos <= -23) and (xspeed < 0) and (poen = '0')) then
                                poenR <= poenR + 1;
                                poen <= '1';
                            end if;
                        end if;
--ODBIJANJE OD GORNJE ILI DONJE IVICE EKRANA                        
                    if (((ball_vpos >= 735) and (yspeed > 0)) or ((ball_vpos < 1) and (yspeed < 0))) then
                            yspeed <= -yspeed;
                    end if;
                end case;
            end if;
        end if;
    end process REBOUND_LOGIC;
    
--LOGIKA ZA GAME_END
GAME_END_LOGIC: process (clk, poenL, poenR, reset) is     
    begin
        if reset = '1' then
            game_end <= '1';
        elsif rising_edge(clk) then
            if ((poenR = 9) or (poenL = 9)) then    
                game_end <= '1';    --AKO NI JEDAN IGRAC NIJE DOSAO DO 9
            elsif (game_start = '0') then              --AKO JE PRITISNUT RESET
                game_end <= '0';    --I AKO IGRA JOS NIJE POCELA
            end if;
        end if;
    end process GAME_END_LOGIC;
    
--PROCESS KOJI DRZI LOPTICU NA SREDINI DOK NEKO NESTO NE PRITISNE I GENERISE GAME_START SIGNAL
    GAME_START_LOGIC: process(clk, reset, ref_tick, poen, button_left_down, button_left_up, button_right_down, button_right_up) is
    begin 
        if reset = '1' then
            game_start <= '0';
        elsif rising_edge(clk) then
            if (game_start = '0') then --and game_end = '1'
                if ((button_left_down = '0') or (button_left_up = '0') or (button_right_down = '0') or (button_right_up = '0')) then
                    game_start <= '1';
                end if;
--            elsif poen = '1' then
--                game_start <= '0';
            elsif ((poen = '1') and (ref_tick = '1')) then 
                game_start <= '0';
            end if;
        end if;
    end process GAME_START_LOGIC;

    
--    COLOR_PROC: process(reset, left_racket_valid, right_racket_valid, ball_valid) is
--    begin
--        if reset = '1' then
--            Rin <= (others => '0');
--            Gin <= (others => '0');
--            Bin <= (others => '0');
--        else
--            if left_racket_valid = '1' then
--                Rin <= (others => '1');
--                Gin <= (others => '1');
--                Bin <= (others => '1');
--            elsif right_racket_valid = '1' then
--                Rin <= (others => '1');
--                Gin <= (others => '1');
--                Bin <= (others => '1');
--            elsif ball_valid = '1' then
--                Rin <= (others => '1');
--                Gin <= (others => '1');
--                Bin <= (others => '1');
--            else
--                Rin <= x"7b";
--                Gin <= x"15";
--                Bin <= x"18";
--            end if;
--        end if;
--    end process COLOR_PROC;
    
	ADDRESS_CALC: process(clk, reset)
    begin
		if (reset = '1') then
			addressBall <= (others => '0');         --Pri resetu se sve adrese vracaju na nulu(pocetak)
			        
		elsif (rising_edge(clk)) then
			if (ball_valid = '1') then  --Dalje se pitamo gde se nalazi piksel, ako je na glavi, inkrementira se adresa za glavu
				if ((hpos = ball_hpos + 31) and (vpos = ball_vpos + 32 )) then
					addressBall <= (others => '0'); --Dada dodje do poslednje adrese iz ROM memorije, adresa se vraca na 0
				else                           --da bi bila spremna za citanje za naredni frejm
					addressBall <= addressBall + 1;
				end if;
			elsif left_racket_valid = '1' then --Analogno tome, pitamo se za svaki deo tela i inkrementira se samo njegova adresa
					if ((hpos = left_hpos + 15) and (vpos = left_vpos + 128 )) then
						addressLeft <= (others => '0');
					else
						addressLeft <= addressLeft + 1;
					end if;
			elsif right_racket_valid = '1' then
					if ((hpos = right_hpos + 15) and (vpos = right_vpos + 128)) then
						addressRight <= (others => '0');
					else
						addressRight <= addressRight + 1;
					end if;
			end if;
		end if;
	end process;
	
	COLOR_PROC: process(reset, left_racket_valid, right_racket_valid,
    ball_valid, datamemRacket, datamemBall) is
	begin
		if (reset = '1') then
            Rin <= (others => '0');
            Gin <= (others => '0');
            Bin <= (others => '0');
		else
			if (left_racket_valid = '1') or (right_racket_valid = '1') then  
                if datamemRacket /= x"FFF" then 						--Ako je boja iz memorije razlicita od bele, iscrtava se piksel
                    Rin <= datamemRacket(11 downto 8) & x"0";  --ali samo iz ROM-a za kretanje u levo, analogno tome za sva ostala stanja
                    Gin <= datamemRacket(7 downto 4) & x"0";
                    Bin <= datamemRacket(3 downto 0) & x"0";
                else
                    Rin <= x"7b";     --U suprotnom iscrtava se pozadina koja je u ovom slucaju crne boje
                    Gin <= x"15";
                    Bin <= x"18";
                end if;
			elsif ball_valid = '1' then
				if datamemBall /= x"FFF" then
					Rin <= datamemBall(11 downto 8) & x"0";  --ali samo iz ROM-a za kretanje u levo, analogno tome za sva ostala stanja
                    Gin <= datamemBall(7 downto 4) & x"0";
                    Bin <= datamemBall(3 downto 0) & x"0";
				else
					Rin <= x"7b";     --U suprotnom iscrtava se pozadina koja je u ovom slucaju crne boje
                    Gin <= x"15";
                    Bin <= x"18";
				end if;
            else
                Rin <= x"7b";     --U suprotnom iscrtava se pozadina koja je u ovom slucaju crne boje
                Gin <= x"15";
                Bin <= x"18";
			end if;
		end if;
	end process COLOR_PROC;
	
	ADD_CALC: process (left_racket_valid, right_racket_valid, addressLeft, addressRight) is
	begin
        if left_racket_valid = '1' then
            address_temp <= addressLeft;
        elsif right_racket_valid = '1' then
            address_temp <= addressRight;
		else
			address_temp <= (others => '0');
		end if;
	end process;
end rtl;