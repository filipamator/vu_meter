library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

ENTITY ili9341 IS
PORT (
	clk         : IN STD_LOGIC;
	tft_sdo     : IN STD_LOGIC;
    tft_sck     : OUT STD_LOGIC;
    tft_sdi     : OUT STD_LOGIC;
	tft_dc      : OUT STD_LOGIC;
    tft_reset   : OUT STD_LOGIC;
    tft_cs      : OUT STD_LOGIC;

    fb_data     : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
    fb_wraddress: IN STD_LOGIC_VECTOR (16 DOWNTO 0);
    fb_wrclock  : IN STD_LOGIC;
    fb_wren     : IN STD_LOGIC

);
END ENTITY ili9341;


ARCHITECTURE rtl OF ili9341 IS

COMPONENT tft_ram IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (16 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (16 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END COMPONENT tft_ram;

COMPONENT tft_ili9341 IS
GENERIC (
	INPUT_CLK_MHZ	: natural
	);
PORT (
    clk                 : IN STD_LOGIC;
    tft_sdo             : IN STD_LOGIC;
    tft_sck             : OUT STD_LOGIC;
    tft_sdi             : OUT STD_LOGIC;
    tft_dc              : OUT STD_LOGIC;
    tft_reset           : OUT STD_LOGIC;
    tft_cs              : OUT STD_LOGIC;
    framebufferData     : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    framebufferClk      : OUT STD_LOGIC;
    fb_start            : OUT STD_LOGIC
);

END COMPONENT tft_ili9341;

SIGNAL framebufferClk,prev_framebufferClk : STD_LOGIC;
SIGNAL framebufferData : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL framebufferData_r : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL framebufferData_g : STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL framebufferData_b : STD_LOGIC_VECTOR(4 DOWNTO 0);


SIGNAL q : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL counter : INTEGER;
SIGNAL color_counter : INTEGER;
SIGNAL fb_start,prev_fb_start : STD_LOGIC;


BEGIN


-- RRRRRR
-- framebufferData <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,framebufferData'length));
-- framebufferData <= STD_LOGIC_VECTOR(TO_UNSIGNED(color_counter,7)) & "000000000";

-- color order:
-- G3 G2 G1 R5 R4 R3 R2 R1  B5 B4 B3 B2 B1 G6 G5 G4
-- color order in memory:
-- R5 R4 R3 R2 R1 G6 G5 G4 G3 G2 G1 B5 B4 B3 B2 B1

framebufferData <= framebufferData_g(2 DOWNTO 0) & framebufferData_r & framebufferData_b & framebufferData_g(5 DOWNTO 3);


framebufferData_r <= q(15 DOWNTO 11);
framebufferData_g <= q(10 DOWNTO 5);
framebufferData_b <= q(4 DOWNTO 0);


PROCESS (clk)
BEGIN

    IF clk='1' and clk'event THEN

        prev_framebufferClk <= framebufferClk;
        prev_fb_start <= fb_start;

        IF fb_start='1' and prev_fb_start='0' THEN
            counter <= 0;
        END IF;

        IF framebufferClk='1' and prev_framebufferClk='0' THEN

            IF counter=76799 THEN -- 76799
                counter <= 0;
            ELSE
                counter <= counter + 1;
            END IF;

        END IF;

    END IF;

END PROCESS;

inst1 : tft_ili9341
generic map (
	INPUT_CLK_MHZ => 50
	)
port map(
	clk => clk,
	tft_sdo => '0',
    tft_sck => tft_sck,
    tft_sdi => tft_sdi,
    tft_dc => tft_dc,
    tft_reset => tft_reset,
    tft_cs => tft_cs,
    framebufferData => framebufferData,
    framebufferClk => framebufferClk,
    fb_start => fb_start
);

tft_ram_inst : tft_ram 
PORT MAP (
		data		=> fb_data,
		rdaddress 	=> STD_LOGIC_VECTOR(TO_UNSIGNED(counter-1,17)),
		rdclock	 	=> framebufferClk,
		wraddress	=> fb_wraddress,
		wrclock	 	=> fb_wrclock,
		wren	 	=> fb_wren,
		q	 		=> q
	);

	
	
-- R5 R4 R3 R2 R1 G6 G5 G4 G3 G2 G1 B5 B4 B3 B2 B1
	
-- G3 G2 G1 R5 R4 R3 R2 R1 B5 B4 B3 B2 B1 G6 G5 G4	
	

END rtl;
