library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;


entity windowfunction_tb is
end windowfunction_tb;


architecture Behavioral of windowfunction_tb is

-----------------------------
-- Components ---------------
-----------------------------

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

component fake_dac is
port (
        clock       : in STD_LOGIC;
        reset       : in STD_LOGIC;
        data_out    : out STD_LOGIC_VECTOR(15 downto 0);
        data_out_en : out STD_LOGIC
);
end component fake_dac;

------------------------------
-- Signals --------------------
------------------------------

signal clock,reset,trigger : std_logic := '0';

signal data_out : std_logic_vector(15 downto 0);
signal data_out_en : std_logic;


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


    trig : process is 
    begin
        trigger <= '0';
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        wait until rising_edge(clock);        
        trigger <= '1';
        wait until rising_edge(clock);
        trigger <= '0';
        wait;
    end process trig;

    --read process
    reading : process (clock)
        file        infile      : text is in  "list.txt";   --declare input file
        variable    inline      : line; --line number declaration
        variable    dataread1   : integer;
    begin

        if (reset='1') then
            data_out_en <= '0';
            data_out <= (others => '0');
        elsif (clock='1' and clock'event) then
                data_out_en <= '1';
                if (not endfile(infile)) then  
                    readline(infile, inline);      
                    read(inline, dataread1);
                    data_out <= std_logic_vector(to_signed(dataread1, data_out'length));
                else
                    data_out_en <='0';
                end if;
        end if;

    end process reading;


-------------------------------------------

    -- --write process
    -- writing : process
    --     file      outfile  : text is out "2.txt";  --declare output file
    --     variable  outline  : line;   --line number declaration  
    --     variable datatosave : integer;
    -- begin
    --     wait until clock = '1' and clock'event;
    --     if(DEBUG_DATA_EN='1') then
    --         datatosave := to_integer(unsigned(DEBUG_DATA));
    --         write(outline, datatosave);
    --         writeline(outfile, outline);
    --     else
    --         null;
    --     end if;
    -- end process writing;

--------------------------------------------


 fake_dac_i1 : fake_dac
port map (
        clock       => clock,
        reset       => reset,
        data_out    => open,
        data_out_en => open
);




windowfunction_i1 : windowfunction
generic map (
		SIZE => 1024
)
port map (
        i_clock         => clock,
        i_reset         => reset,
        i_data          => data_out,
		i_data_start    => trigger,
        i_data_en       => data_out_en,
		o_data		    => open,
		o_data_en	    => open,
		o_data_start    => open
	
);


end Behavioral;