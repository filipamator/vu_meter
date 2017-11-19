
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

--entity declaration
entity calcfft_tb is
end calcfft_tb;

--architecture definition
architecture Behavioral of calcfft_tb is

--period of clock,bit for indicating end of file.
signal clock,endoffile : std_logic := '0';
signal dataread : integer;
-- signal datatosave : integer;
signal linenumber : integer:=1; 
signal read_en  : std_logic := '0';


signal data_in: std_logic_vector(15 downto 0) := (others => '0');
signal reset : std_logic := '0';
signal reset_n : std_logic := '1';



component dft_top is
port (
    clk             : in std_logic;
    reset           : in std_logic;
    nexx            : in std_logic;
    nexx_out        : out std_logic;
    X0, X1, X2, X3  : in std_logic_vector(15 downto 0);
    Y0, Y1, Y2, Y3  : out std_logic_vector(15 downto 0)
);
end component dft_top;


component calcfft is
port (
    clock       : in std_logic;
    enable      : in std_logic;
    reset_n     : in std_logic;
    data_in     : in std_logic_vector(15 downto 0)
);
end component calcfft;



begin

    reset_n <= not reset;
    clock <= not (clock) after 10 ns;    --clock with time period 1 ns
--    datatosave <= dataread;



    main : process is
    begin

        
        wait until rising_edge(clock);
        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        read_en <= '1';
        wait until rising_edge(clock);
        wait until rising_edge(endoffile);
        read_en <= '0';
        wait for 10000 us;

    end process main;

    --read process
    reading : process
        file        infile      : text is in  "1.txt";   --declare input file
        variable    inline      : line; --line number declaration
        variable    dataread1   : integer;
    begin
        wait until clock = '1' and clock'event;

        if (read_en='1') then 
            if (not endfile(infile)) then  
                readline(infile, inline);      
                read(inline, dataread1);
               data_in <= std_logic_vector(to_signed(dataread1, data_in'length));
                linenumber <= linenumber + 1;
            else
                endoffile <='1';         
            end if;

        end if;

    end process reading;

calcfft_i1 : calcfft
port map (
    clock       => clock,
    enable      => read_en,
    reset_n     => reset_n,
    data_in     => data_in
);


end Behavioral;