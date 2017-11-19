library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;


entity fft_tb is
end fft_tb;


architecture Behavioral of fft_tb is

-----------------------------
-- Components ---------------
-----------------------------


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



------------------------------
-- Signals --------------------
------------------------------

signal clock,reset : std_logic := '0';
signal data_en      : std_logic := '0';  
signal data_in      : std_logic_vector(15 downto 0);
signal data_fft_out : std_logic_vector(31 downto 0);
signal data_fft_out_en : std_logic;
signal data_fft_out_start : std_logic;

begin

    clock <= not (clock) after 10 ns;    --clock with time period 20 ns


    main : process is
    begin
        reset <= '1';
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        reset <= '0';
        wait;
    end process main;


-------------------------------------------

    --read process
    reading : process (clock)
        file        infile      : text is in  "audiotest.txt";   --declare input file
        variable    inline      : line; --line number declaration
        variable    dataread1   : integer;
    begin
        if reset='1' then
             data_en <= '0';
        elsif (clock='1' and clock'event) then
            data_en <= '0';

                if (not endfile(infile)) then  
                    readline(infile, inline);      
                    read(inline, dataread1);
                    data_in <= std_logic_vector(to_signed(dataread1, data_in'length));
                    data_en <= '1';

                else 
                    data_in <= (others => '0');   
                end if;

            
        end if;

    end process reading;


-------------------------------------------

    --write process
    writing : process
        file      outfile  : text is out "audiotest_fft.txt";  --declare output file
        variable  outline  : line;   --line number declaration  
        variable datatosave : integer;
    begin
        wait until clock = '1' and clock'event;
        if(data_fft_out_en='1') then
            datatosave := to_integer(unsigned(data_fft_out));
            write(outline, datatosave);
            writeline(outfile, outline);
        else
            null;
        end if;
    end process writing;

--------------------------------------------


 fft_i1 : fft
port map (
            clock       => clock,  
            reset       => reset,
            data_en     => data_en,
            data_in     => data_in,
            data_fft_out    => data_fft_out,
            data_fft_out_en => data_fft_out_en,
            data_fft_out_start  => data_fft_out_start
);


end Behavioral;