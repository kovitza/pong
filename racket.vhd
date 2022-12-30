-------------------------------------------------------------------------------------------------------------------------------
--Trebalo bi da je fajl koji iscrtava i pomera REKET 
-------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity racket is
    generic (
        RACKET_DIM      : integer := 16;
        RACKET_H_START  : integer := 10;
        RACKET_V_START  : integer := 320
    );
    port (
        hpos : in integer range 0 to 1023;
        vpos : in integer range 0 to 767;
        
        reset : in std_logic;
        clk : in std_logic;
        
        move_up  : in std_logic;
        move_down: in std_logic;
        
        ref_tick : in std_logic;
        
--        r_out, g_out, b_out : out std_logic_vector(7 downto 0);      
       
        racket_hpos  : out integer range -RACKET_DIM to 1023 + RACKET_DIM;
        racket_vpos  : out integer range -RACKET_DIM to 767 + RACKET_DIM;
        racket_valid : out std_logic
    );
end racket;

architecture Behavioral of racket is
	
	constant RACKET_COLOR : std_logic_vector(23 downto 0) := x"A1A1A1";    --boja reketa, nadam se ona svetla siva
	
	signal racket_xpos  : integer range -RACKET_DIM to 1023 + RACKET_DIM;
	signal racket_ypos  : integer range -RACKET_DIM to 767 + RACKET_DIM;

    type State_t is (init, push);
	signal next_state, state_reg: State_t;
    
    signal move_up_int, move_down_int : std_logic := '1';   --INICIJALNA VREDNOST JE DA JE NEAKTIVAN
    --signal temp : std_logic;
begin
    --ovo bi trebalo da oboji reket                     NEPOTREBNO JER GA PRAVIM KAO BITMAPU
--	r_out <= RACKET_COLOR(23 downto 16);
--	g_out <= RACKET_COLOR(15 downto 8);
--	b_out <= RACKET_COLOR(7 downto 0);
    
	--OVO BI TREBALO DA ISCRTAVA REKET
	racket_valid <= '1' when ((hpos > racket_xpos and hpos <= racket_xpos + RACKET_DIM) and 
                            (vpos > racket_ypos and vpos <= racket_ypos + 8*RACKET_DIM)) 
                else'0';
                
   racket_xpos <= RACKET_H_START;  --X POZICIJA REKETA SE NE MENJA NIKAD
   
   
--Logika za pomeranje reketa jer move_down ne bude aktivan u istom trenutku kao i ref_tick i onda se nista ne desi
    STATE_TRAN: process (clk, reset) is
    begin
        if reset = '1' then
            state_reg <= init;
        else
            if rising_edge(clk) then
                state_reg <= next_state;
            end if;
        end if;
    end process STATE_TRAN;
   

    NEXT_STATE_LOGIC: process (next_state, state_reg, move_up, move_down, ref_tick) is
	begin
		case state_reg is           
			when init =>
				if (move_up = '0') or (move_down = '0') then
                    next_state <= push;
                else
                    next_state <= state_reg; --AKO JE NEAKTIVAN BUTTON ONDA SE VRTIS U INIT
                end if;
			when push =>    --ovo bi trebalo da obezbedi da se signal dovoljno dugo drzi da ga ref_tick registruje
				if ref_tick = '1' then
                    next_state <= init;
                else
                    next_state <= state_reg; --DOK NE DODJE REF_TICK ON SE VRTI U PUSH, PO DOLASKU REF_TICK IDE U INIT
                end if;
		end case;
	end process NEXT_STATE_LOGIC;
	
    OUTPUT_LOGIC: process (state_reg, move_up, move_down, move_down_int, move_up_int) is
	begin
		case state_reg is
			when init =>    --KADA U INIT OBA SU OFF
                move_up_int     <= '1';     --NEAKTIVAN ZA '1'
                move_down_int   <= '1';     --NEAKTIVAN ZA '1'
--PUSH STANJE BI TREBALO DA PRVI PRITISNUTI TASTER DRZI NA AKTIVNOM NIVOU DOK NE DODJE REF_TICK
			when push =>
				if move_up = '0' then   --OVAJ IF THEN ELSE GOVORI: DUGME KOJE JE PRVO PRITISNUTO CE BITI IZVRSENO NA REF_TICK
                    move_up_int     <= '0';
                    move_down_int   <= '1';
                elsif move_down = '0' then
                    move_up_int     <= '1';
                    move_down_int   <= '0';
                else
                    move_down_int   <= '1';
                    move_up_int     <= '1';
                end if;
		end case;
	end process OUTPUT_LOGIC;
    
   -- Azuriranje pozicije na osnovu pomeranja
process(clk, reset, racket_ypos)    --NIJE MI JASNO ZASTO SE GENERISE LEC OVDE???
begin                               --OVAJ LEC SE PRAVI KAKO BI SACUVAO TU VREDNOST PRILIKOM RESETA
	if (reset = '1') then
		racket_ypos <= RACKET_V_START;  
	elsif (rising_edge(clk)) then
        if (ref_tick = '1') then
            if (move_up_int = '0') then   --BUTTON JE VALJDA AKTIVAN U LOG 0 znc ako je button aktivan onda idi gore
                if (racket_ypos > 0) then
                    if racket_ypos < 10 then    --ovo sprecava da reket izadje sa ekrana
                        racket_ypos <= 0;
                    else
                        racket_ypos <= racket_ypos - 10; --ako je pritisnut taster za gore, onda se pozicija po y smanjuje za 10
                    end if;
                end if;
            elsif (move_down_int = '0') then    --KRECE SE REKET NA DOLE
                if (racket_ypos < 767) then  --ZNACI UKOLIKO SE NALAZI IZNAD 703 PX
                    if racket_ypos >629  then    --UKOLIKO SE NALAZI ISPOD 693 PX, 767-8*RACKET_DIM-10
                        racket_ypos <= 639;      --SLEDECA POZICIJA MU JE 639px ODNOSNO NA KRAJU EKRANA
                    else
                        racket_ypos <= racket_ypos + 10; --AKO SE NE NALAZI ISPOD 693 ONDA SAMO POVECAVAJ ZA 10 PO Y  
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

--out signali potrebni za game logiku posle 
racket_hpos <= racket_xpos;
racket_vpos <= racket_ypos;
end Behavioral;