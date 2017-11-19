library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;


entity calcspec_tb is
end calcspec_tb;


architecture Behavioral of calcspec_tb is

component fft is
port (
            clock    : in std_logic;
            reset    : in std_logic;
            data_en  : in std_logic;
            data_in  : in std_logic_vector(15 downto 0);
            data_fft_out : out std_logic_vector(31 downto 0);
            data_fft_out_en : out std_logic;
            data_fft_out_start : out std_logic
);
end component fft;

component fake_dac is
port (
        clock       : in STD_LOGIC;
        reset       : in STD_LOGIC;
        data_out    : out STD_LOGIC_VECTOR(15 downto 0);
        data_out_en : out STD_LOGIC
);
end component fake_dac;

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


signal clock,endoffile : std_logic := '0';

signal tick_48khz : std_logic := '0';
signal reset : std_logic := '0';
signal counter_48khz : integer;

signal audio_left			: std_logic_vector(15 downto 0);
signal audio_left_en		: std_logic;

signal fft_data_out_en : std_logic;
signal fft_data_out : std_logic_vector(31 downto 0);
signal fft_data_out_sh : std_logic_vector(7 downto 0);
signal fft_data_out_start : std_logic;



begin

    fft_data_out_sh <= fft_data_out(31 downto 24);
    clock <= not (clock) after 10 ns;    --clock with time period 20 ns

    main : process is
    begin
        reset <= '1';
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        reset <= '0';
        wait;
    end process main;


    clock48khz: process(clock) is
    begin
        if reset='1' then
            counter_48khz <= 0;
            tick_48khz <= '0';
        elsif clock='1' and clock'event then
            if counter_48khz=99 then
                tick_48khz <= '1';
                counter_48khz <= 0;
            else 
                counter_48khz <= counter_48khz + 1;
                tick_48khz <= '0';
            end if;
        end if;
    end process clock48khz;


    --read process
    reading : process (clock)
        file        infile      : text is in  "1.txt";   --declare input file
        variable    inline      : line; --line number declaration
        variable    dataread1   : integer;
    begin

        if (clock='1' and clock'event) then
            -- read_en <= '0';
            if (tick_48khz='1') then 
                if (not endfile(infile)) then  
                    readline(infile, inline);      
                    read(inline, dataread1);
                    --read_data <= std_logic_vector(to_signed(dataread1, read_data'length));
                    --read_en <= '1';
                else
                    endoffile <='1';         
                end if;

            end if;
        end if;

    end process reading;

--------------
    --write process
    writing : process
        file      outfile  : text is out "2.txt";  --declare output file
        variable  outline  : line;   --line number declaration  
        variable datatosave : integer;
    begin
        wait until clock = '1' and clock'event;
        if(fft_data_out_en='1') then
            datatosave := to_integer(signed(fft_data_out_sh));
            write(outline, datatosave);
            writeline(outfile, outline);
        else
            null;
        end if;
    end process writing;

-----------------

fake_dac_i1 : fake_dac
port map (
        clock           => clock,
        reset           => reset,
        data_out        => audio_left,
        data_out_en     => audio_left_en
);


fft_i1 : fft
port map (
            clock       => clock,
            reset       => reset,
            data_en     => audio_left_en,
            data_in     => audio_left,
            data_fft_out_en => fft_data_out_en,
            data_fft_out    => fft_data_out,
            data_fft_out_start => fft_data_out_start
);

	plotspec_i1 : plotspec
	port map (
    	clock   		=> clock,
        reset         	=> reset,
        data_in    	    => fft_data_out(25 downto 18),
        data_in_en  	=> fft_data_out_en,
        data_in_start   => fft_data_out_start,
        fb_data   	    => open,
        fb_wraddress    => open,
        fb_wren		    => open
	);


end Behavioral;