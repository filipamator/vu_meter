library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity vu_meter is
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
end entity vu_meter;




architecture rtl of vu_meter is


------------------------
-- Components ----------
------------------------


component dac_i2s is
port (

	CLOCK_50		: in std_logic;
	reset			: in std_logic;
	AUD_ADCDAT	    : inout std_logic;
	AUD_BCLK		: inout std_logic;
	AUD_ADCLRCK	    : inout std_logic;
	AUD_DACLRCK	    : inout std_logic;
	I2C_SDAT		: inout std_logic;
	AUD_XCK		    : out std_logic;
	AUD_DACDAT	    : out std_logic;
	I2C_SCLK		: out std_logic;
    audio_left          : out std_logic_vector(15 downto 0);
    audio_left_en       : out std_logic;
    audio_right         : out std_logic_vector(15 downto 0);
    audio_right_en      : out std_logic
);
end component dac_i2s;


component ili9341 IS
PORT (
	CLK         : IN STD_LOGIC;
	TFT_SDO   	: IN STD_LOGIC;
    TFT_SCK     : OUT STD_LOGIC;
    TFT_SDI     : OUT STD_LOGIC;
	TFT_DC      : OUT STD_LOGIC;
    TFT_RESET   : OUT STD_LOGIC;
    TFT_CS    	: OUT STD_LOGIC;
	fb_data     : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
    fb_wraddress: IN STD_LOGIC_VECTOR (16 DOWNTO 0);
    fb_wrclock  : IN STD_LOGIC;
    fb_wren     : IN STD_LOGIC
);
END component ili9341;


component plotspec is
port (
            clock           : in std_logic;
            reset           : in std_logic;

            data_in        : in std_logic_vector(7 downto 0);
            data_in_en     : in std_logic;
            data_in_start  : in std_logic;

            fb_data         : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            fb_wraddress    : OUT STD_LOGIC_VECTOR (16 DOWNTO 0);
            fb_wren         : OUT STD_LOGIC
);
end component plotspec;



component fake_plotspec is
port (
            clock           : in std_logic;
            reset           : in std_logic;

            fb_data         : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            fb_wraddress    : OUT STD_LOGIC_VECTOR (16 DOWNTO 0);
            fb_wren         : OUT STD_LOGIC
);
end component fake_plotspec;


component fake_dac is
port (
        clock       : in STD_LOGIC;
        reset       : in STD_LOGIC;
        data_out    : out STD_LOGIC_VECTOR(15 downto 0);
        data_out_en : out STD_LOGIC
);
end component fake_dac;


component fft is
generic (
            SIZE    : natural := 1024
);
port (
            clock    : in std_logic;
            reset    : in std_logic;
            data_en  : in std_logic;
            data_in  : in std_logic_vector(15 downto 0);
			data_start : in std_logic;
            data_fft_out : out std_logic_vector(31 downto 0);
            data_fft_out_en : out std_logic;
            data_fft_out_start : out std_logic
);
end component fft;

component uart_dump is
  generic (
    SIZE         : natural := 1024
  );
  port (
    i_clock       : in  std_logic;
    i_reset       : in std_logic;
	i_start		  : in std_logic;
    i_data        : in std_logic_vector(15 downto 0);
    i_enable      : in std_logic;
    o_tx_byte     : out std_logic_vector(7 downto 0);
    o_tx_dv       : out  std_logic;
    i_tx_done     : in std_logic;
    i_tx_active   : in std_logic
  );
end component uart_dump;


component UART_TX is
  generic (
    g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_TX_DV     : in  std_logic;
    i_TX_Byte   : in  std_logic_vector(7 downto 0);
    o_TX_Active : out std_logic;
    o_TX_Serial : out std_logic;
    o_TX_Done   : out std_logic
    );
end component UART_TX;


component debounce IS
  GENERIC(
    counter_size  :  INTEGER := 10); --counter size (19 bits gives 10.5ms with 50MHz clock)
  PORT(
    clk     : IN  STD_LOGIC;  --input clock
	reset 	: IN STD_LOGIC;
    button  : IN  STD_LOGIC;  --input signal to be debounced
    result  : OUT STD_LOGIC); --debounced signal
END component debounce;

component int2fp IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component int2fp;

component powerlog is
port (
        i_clock     : in std_logic;
        i_reset     : in std_logic;
        i_data      : in std_logic_vector(31 downto 0);
		i_data_start: in std_logic;
        i_data_en   : in std_logic;
		o_data		: out std_logic_vector(31 downto 0);
		o_data_en	: out std_logic;
		o_data_start: out std_logic
	
);
end component powerlog;

component dataacq is
generic (
            SIZE        : natural := 1024
);
port (
            i_clock    : in std_logic;
            i_reset    : in std_logic;
            i_data_en  : in std_logic;
            i_data     : in std_logic_vector(15 downto 0);
            i_start    : in std_logic;

            o_data       : out std_logic_vector(15 downto 0);
            o_data_en    : out std_logic;
            o_data_start : out std_logic
);
end component dataacq;

component triggen is
generic (
		CLKCOUNTER	: natural := 5000000
);
port (
		clock 	: in std_logic;
		reset_n	: in std_logic;
		enable	: out std_logic
);
end component triggen;

component windowfunction is
generic (
		SIZE		: natural := 1024
);
port (
        i_clock     : in std_logic;
        i_reset     : in std_logic;
        i_data      : in std_logic_vector(15 downto 0);
		i_data_start: in std_logic;
        i_data_en   : in std_logic;

		o_data		: out std_logic_vector(15 downto 0);
		o_data_en	: out std_logic;
		o_data_start: out std_logic
	
);
end component windowfunction;
------------------------
-- Signals -------------
------------------------

signal fb_data     			: STD_LOGIC_VECTOR (15 DOWNTO 0);
signal fb_wraddress			: STD_LOGIC_VECTOR (16 DOWNTO 0);

signal fb_wren     			: STD_LOGIC;
signal audio_left			: std_logic_vector(15 downto 0);
signal audio_right			: std_logic_vector(15 downto 0);
signal audio_left_en		: std_logic;
signal audio_right_en		: std_logic;
signal reset 				: std_logic;

signal i2s_left			: std_logic_vector(15 downto 0);
signal i2s_left_en		: std_logic;
signal fake_left		: std_logic_vector(15 downto 0);
signal fake_left_en		: std_logic;



signal fft_data_out_en 		: std_logic;
signal fft_data_out 		: std_logic_vector(31 downto 0) := (others => '0');
signal fft_data_out_start 	: std_logic;


signal r_tx_byte		: std_logic_vector(7 downto 0);
signal r_tx_dv			: std_logic;
signal r_tx_done		: std_logic;
signal r_tx_active		: std_logic;


signal select_dac		: std_logic;
signal button_raw,trigger : std_logic;


signal logfft_data_out : std_logic_vector(31 downto 0);
signal logfft_data_out_en : std_logic;
signal logfft_data_out_start : std_logic;

signal buff_data	: std_logic_vector(15 downto 0);
signal buff_data_en,buff_data_start : std_logic;


signal wbuff_data	: std_logic_vector(15 downto 0);
signal wbuff_data_en,wbuff_data_start : std_logic;
signal r_start_fft		: std_logic;
signal reset_n 			: std_logic;
signal fft_data_out_sh 	: std_logic_vector(7 downto 0);

signal plot_data 		: std_logic_vector(7 downto 0);
signal plot_data_en		: std_logic;
signal plot_data_start	: std_logic;


begin

	reset_n <= not reset;

	fft_data_out_sh <= fft_data_out(13 downto 6);


with SW(1) select  plot_data <= logfft_data_out(7 downto 0) when '0', 
								fft_data_out(13 downto 6) when others;

with SW(1) select plot_data_en <= 	logfft_data_out_en when '0', 
									fft_data_out_en when others;

with SW(1) select plot_data_start <= logfft_data_out_start when '0',
									 fft_data_out_start when others;


--				data_in    		=> logfft_data_out(7 downto 0),
--				data_in_en  	=> logfft_data_out_en,
--				data_in_start 	=> logfft_data_out_start

--				data_fft_out		=> fft_data_out,
--				data_fft_out_en 	=> fft_data_out_en,
--				data_fft_out_start 	=> fft_data_out_start


	button_raw <= not KEY(1);
	select_dac <= SW(0);


	with  select_dac select audio_left <= 
									i2s_left when '0',
									fake_left when others;

	with select_dac select audio_left_en <= 
									i2s_left_en when '0',
									fake_left_en when others;
	reset <= not KEY(0);
	

	dac_i2s_i1 : dac_i2s 
	port map (
		CLOCK_50 		=> CLOCK_50,	
		reset			=> reset,
		AUD_ADCDAT	   	=> AUD_ADCDAT,
		AUD_BCLK		=> AUD_BCLK,
		AUD_ADCLRCK	 	=> AUD_ADCLRCK,
		AUD_DACLRCK	  	=> AUD_DACLRCK,
		I2C_SDAT		=> I2C_SDAT,
		AUD_XCK		  	=> AUD_XCK,
		AUD_DACDAT	   	=> AUD_DACDAT,
		I2C_SCLK		=> I2C_SCLK,
		audio_left     	=> i2s_left,
		audio_left_en  	=> i2s_left_en,
		audio_right   	=> open,
		audio_right_en 	=> open
	);
	
	fake_dac_i1 : fake_dac
	port map (
        clock			=> CLOCK_50,
        reset 			=> reset,
        data_out  		=> fake_left,
        data_out_en 	=> fake_left_en
	);
	
	triggen_i1 : triggen
	generic map(
		CLKCOUNTER	=> 3_000_000
	)
	port map (
		clock => CLOCK_50,
		reset_n	=> reset_n,
		enable	=> r_start_fft
	);

	dataacq_i1 : dataacq
	generic map(
				SIZE		=> 1024
	)
	port map(
				i_clock 		=> CLOCK_50,
				i_reset    		=> reset,
				i_data_en 		=> audio_left_en,
				i_data     		=> audio_left,
				i_start  		=> r_start_fft,
				o_data    		=> buff_data,
				o_data_en    	=> buff_data_en,
				o_data_start 	=> buff_data_start
	);


	windowfunction_i1 : windowfunction
	generic map (
			SIZE		=> 1024
	)
	port map (
			i_clock   		=> CLOCK_50,
			i_reset    		=> reset,
			i_data     		=> buff_data,
			i_data_start	=> buff_data_start,
			i_data_en  		=> buff_data_en,
			o_data			=> wbuff_data,
			o_data_en		=> wbuff_data_en,
			o_data_start	=> wbuff_data_start
	);


	fft_i1 : fft
	generic map (
				SIZE => 1024
	)
	port map (
				clock				=> CLOCK_50,
				reset 				=> reset,
				data_start 			=> wbuff_data_start,
				data_en 			=> wbuff_data_en, 
				data_in  			=> wbuff_data,
				data_fft_out		=> fft_data_out,
				data_fft_out_en 	=> fft_data_out_en,
				data_fft_out_start 	=> fft_data_out_start
	);



	powerlog_i1 : powerlog
	port map (
			i_clock   => CLOCK_50,
			i_reset   => reset,
			i_data    => fft_data_out,
			i_data_en => fft_data_out_en,
			i_data_start => fft_data_out_start,

			o_data	=> logfft_data_out,
			o_data_en => logfft_data_out_en,
			o_data_start => logfft_data_out_start
		
	);



DEBUG_DATA <= logfft_data_out;
DEBUG_DATA_EN <= logfft_data_out_en;

	 ili9341_i1 : ili9341
	 PORT MAP (
	 	CLK    		=> CLOCK_50,  
	 	TFT_SDO   	=> TFT_SDO,
	 	TFT_SCK   	=> TFT_SCK,
	 	TFT_SDI  	=> TFT_SDI,
	 	TFT_DC      => TFT_DC,
	 	TFT_RESET  	=> TFT_RESET,
	 	TFT_CS    	=> TFT_CS,
	 	fb_data    	=> fb_data,
     	fb_wraddress=> fb_wraddress,
     	fb_wrclock  => CLOCK_50,
    	fb_wren    	=> fb_wren
	 );
	
	

	plotspec_i1 : plotspec
	port map (
				clock   		=> CLOCK_50,
				reset         	=> reset,

				data_in    		=> plot_data,
				data_in_en  	=> plot_data_en,
				data_in_start 	=> plot_data_start,
				
				-- data_in    		=> logfft_data_out(7 downto 0),
				-- data_in_en  	=> logfft_data_out_en,
				-- data_in_start 	=> logfft_data_out_start,
				
				fb_data   		=> fb_data,
				fb_wraddress	=> fb_wraddress,
				fb_wren			=> fb_wren
	);


	uart_dump_i1 : uart_dump
	generic map (
			SIZE			=> 1024
	)
	port map (
			i_clock			=> CLOCK_50,
			i_reset  		=> reset,
			i_start 		=> trigger,
			i_data   		=> fft_data_out(31 downto 16),
			i_enable 		=> fft_data_out_en,
			o_tx_byte 		=> r_tx_byte,
			o_tx_dv     	=> r_tx_dv,
			i_tx_done   	=> r_tx_done,
			i_tx_active 	=> r_tx_active
	);

UART_TX_i1 : UART_TX
	generic map (
		g_CLKS_PER_BIT => 108
	)
	port map (
			i_Clk 			=> CLOCK_50,
			i_TX_DV    		=> r_tx_dv,
			i_TX_Byte 		=> r_tx_byte,
			o_TX_Active 	=> r_tx_active,
			o_TX_Serial 	=> UART_TXD,
			o_TX_Done 		=> r_tx_done

		);

debounce_i1 : debounce
	GENERIC MAP (
		counter_size	=> 5_000_000
  	)
	PORT MAP (
		clk		=> CLOCK_50,
		reset	=> reset,
		button  => button_raw,
		result  => trigger
  	);

end rtl;