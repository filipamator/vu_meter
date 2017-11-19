library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;


entity vu_meter_tb is
end vu_meter_tb;


architecture Behavioral of vu_meter_tb is

-----------------------------
-- Components ---------------
-----------------------------


component vu_meter is
port (
	CLOCK_50		: in std_logic;
	KEY 			: in std_logic_vector(3 downto 0);
	AUD_ADCDAT		: inout std_logic;
	AUD_BCLK		: inout std_logic;
	AUD_ADCLRCK		: inout std_logic;
	AUD_DACLRCK		: inout std_logic;
	I2C_SDAT		: inout std_logic;
	AUD_XCK			: out std_logic;
	AUD_DACDAT		: out std_logic;
	I2C_SCLK		: out std_logic;
	SW				: in std_logic_vector(17 downto 0);
	TFT_SDO   		: IN STD_LOGIC;
    TFT_SCK     	: OUT STD_LOGIC;
    TFT_SDI     	: OUT STD_LOGIC;
	TFT_DC      	: OUT STD_LOGIC;
    TFT_RESET   	: OUT STD_LOGIC;
    TFT_CS    		: OUT STD_LOGIC;
    UART_TXD   		: OUT STD_LOGIC;
    UART_RXD   		: IN STD_LOGIC;
    UART_CTS   		: OUT STD_LOGIC;
    UART_RTS   		: IN STD_LOGIC;
    
	DEBUG_DATA		: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	DEBUG_DATA_EN	: OUT STD_LOGIC
);
end component vu_meter;

component UART_RX is
  generic (
    g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end component UART_RX;
 

------------------------------
-- Signals --------------------
------------------------------

signal clock,reset : std_logic := '0';
signal AUD_ADCDAT   : std_logic;
signal AUD_BCLK	    : std_logic;
signal AUD_ADCLRCK  : std_logic;
signal AUD_DACLRCK	: std_logic;
signal I2C_SDAT	    : std_logic;
signal AUD_XCK	    : std_logic;
signal AUD_DACDAT   : std_logic;
signal I2C_SCLK     : std_logic;
signal trigger      : std_logic;
SIGNAL KEY          : std_logic_vector(3 downto 0);
signal uart_tx      : std_logic;

signal DEBUG_DATA   : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal DEBUG_DATA_EN: std_logic;

begin

    KEY <= "00" & trigger & reset;

    clock <= not (clock) after 10 ns;    --clock with time period 20 ns


    main : process is
    begin
        reset <= '0';
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        reset <= '1';
        wait;
    end process main;


    trig : process is 
    begin
        trigger <= '1';
        wait for 1 us;
        trigger <= '0';
        wait for 1 us;
        trigger <= '1';
        wait;
    end process trig;

-------------------------------------------

    --write process
    writing : process
        file      outfile  : text is out "2.txt";  --declare output file
        variable  outline  : line;   --line number declaration  
        variable datatosave : integer;
    begin
        wait until clock = '1' and clock'event;
        if(DEBUG_DATA_EN='1') then
            datatosave := to_integer(unsigned(DEBUG_DATA));
            write(outline, datatosave);
            writeline(outfile, outline);
        else
            null;
        end if;
    end process writing;

--------------------------------------------

vu_meter_i1 : vu_meter 
port map (
	CLOCK_50    => clock,
	KEY 		=>  KEY,
	AUD_ADCDAT	=> open,
	AUD_BCLK	=> AUD_BCLK,
	AUD_ADCLRCK	=> AUD_ADCLRCK,
	AUD_DACLRCK	=> AUD_DACLRCK,
	I2C_SDAT	=> I2C_SDAT,
	AUD_XCK		=> AUD_XCK,
	AUD_DACDAT	=> AUD_DACDAT,
	I2C_SCLK	=> I2C_SCLK,
	SW			=> "000000000000000001",
	TFT_SDO     => '0',
    TFT_SCK     => open,
    TFT_SDI     => open,
	TFT_DC      => open,
    TFT_RESET   => open,
    TFT_CS    	=> open,
    UART_TXD   	=> uart_tx,
    UART_RXD    => '0',
    UART_CTS   	=> open,
    UART_RTS   	=> '0',
    DEBUG_DATA => DEBUG_DATA,
    DEBUG_DATA_EN => DEBUG_DATA_EN
);

UART_RX_i1 : UART_RX
  generic map (
    g_CLKS_PER_BIT => 108
    )
  port map (
    i_Clk           => clock,
    i_RX_Serial     => uart_tx,
    o_RX_DV         => open,
    o_RX_Byte       => open
    );

end Behavioral;