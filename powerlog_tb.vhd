library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;


entity powerlog_tb is
end powerlog_tb;


architecture Behavioral of powerlog_tb is

component powerlog is
port (
        i_clock     : std_logic;
        i_data_start: in std_logic;
        i_reset     : std_logic;
        i_data      : std_logic_vector(15 downto 0);
        i_data_en   : std_logic;

        o_data		: out std_logic_vector(15 downto 0);
		o_data_en	: out std_logic;
		o_data_start: out std_logic
);
end component powerlog;


signal clock,endoffile : std_logic := '0';
signal reset : std_logic := '0';

signal read_data		: std_logic_vector(15 downto 0);
signal read_data_en		: std_logic := '0';

signal counter          : integer := 0;
signal start            : std_logic := '0';
signal trig             : std_logic;

signal out_data         : std_logic_vector(15 downto 0);
signal out_data_en      : std_logic;
signal out_data_start   : std_logic;


begin


    clock <= not (clock) after 10 ns;    --clock with time period 20 ns

    main : process is
    begin
        reset <= '1';
        trig <= '0';
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        reset <= '0';
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        trig <= '1';
        wait;
    end process main;


    --read process
    reading : process (clock)
        file        infile      : text is in  "1.txt";   --declare input file
        variable    inline      : line; --line number declaration
        variable    dataread1   : integer;
    begin
        
        if (clock='1' and clock'event) then
            read_data_en <= '0';
            if trig='1' then
                if (not endfile(infile)) then  
                    readline(infile, inline);      
                    read(inline, dataread1);
                    read_data <= std_logic_vector(to_signed(dataread1, read_data'length));
                    read_data_en <= '1';
                    counter <= counter + 1;
                    start <= '1';
                else
                    endoffile <='1';      
                    read_data <= (others => '0');   
                end if;
            end if;

            
        end if;

    end process reading;

----------
--    write process
    writing : process
        file      outfile  : text is out "2.txt";  --declare output file
        variable  outline  : line;   --line number declaration  
        variable datatosave : integer;
    begin
        wait until clock = '1' and clock'event;
        if(out_data_en='1') then
            datatosave := to_integer(signed(out_data));
            write(outline, datatosave);
            writeline(outfile, outline);
        else
            null;
        end if;
    end process writing;

-------------


powerlog_i1 : powerlog
port map (
        i_clock         => clock,
        i_data_start    => start,
        i_reset         => reset,
        i_data          => read_data,
        i_data_en       => read_data_en,
        o_data	        => out_data,
		o_data_en	    => out_data_en,
		o_data_start    => out_data_start
);


end Behavioral;