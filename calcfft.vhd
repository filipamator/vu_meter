library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity calcfft is
port (
    clock       : in std_logic;
    enable      : in std_logic;
    reset_n     : in std_logic;
    data_in     : in std_logic_vector(15 downto 0)
);
end calcfft;





architecture Behavioral of calcfft is

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

type Memory_1k is array (0 to 511) of std_logic_vector(31 downto 0);
signal buff : Memory_1k;

TYPE STATE_TYPE IS (ST_IDLE, ST_STORE, ST_DFT, ST_DFTWAIT, ST_DFTREAD);
SIGNAL state   : STATE_TYPE;
signal msb : std_logic;
signal counter : integer := 0;

signal nexx : std_logic := '0';
signal nexx_out : std_logic := '0';
signal data0_im,data1_im,data0_re,data1_re : std_logic_vector(15 downto 0);
signal fft0_re,fft0_im,fft1_re,fft1_im : std_logic_vector(15 downto 0);


signal reset : std_logic := '0';

begin

    reset <= not reset_n;

    process (clock, reset_n)
    begin
        if (reset_n='0') then
            counter <= 0;
            msb <= '1';
            state <= ST_IDLE;
        elsif (clock='1' and clock'event) then
            case state is

                when ST_IDLE =>
                    if enable='1' then
                        --buff(0)(15 downto 0) <= data_in;
                        counter <= 0;
                        msb <= '0';
                        state <= ST_STORE;
                    else
                        state <= ST_IDLE;
                    end if;

                when ST_STORE =>
                    if (counter=512) then
                        counter <= 0;
                        nexx <= '1';
                        state <= ST_DFT;
                    else   
                        if msb='1' then
                            buff(counter)(31 downto 16) <= data_in;
                            msb <= not msb;
                            counter <= counter + 1;
                        else
                            buff(counter)(15 downto 0) <= data_in;
                            msb <= not msb;
                        end if;
                    end if;

                when ST_DFT =>
                    nexx <= '0';
                    if (counter=512) then
                        state <= ST_DFTWAIT;
                    else
                        data0_im <= (others => '0');
                        data0_re <= buff(counter)(15 downto 0);
                        data1_im <= (others => '0');
                        data1_re <= buff(counter)(31 downto 16);
                        counter <= counter + 1;
                    end if;

                when ST_DFTWAIT =>
                    
                    if nexx_out ='1' then
                        counter <= 0;
                        state <= ST_DFTREAD;
                    else
                        state <= ST_DFTWAIT;
                    end if;

                when ST_DFTREAD =>

                    if (counter = 512) then
                        -- counter <= 1;
                        -- sqrt_in <= fft(0);
                        state <= ST_IDLE;
                    else
                        buff(counter) <= std_logic_vector(signed(fft0_re)*signed(fft0_re) + signed(fft0_im)*signed(fft0_im));
                        buff(counter+1) <= std_logic_vector(signed(fft1_re)*signed(fft1_re) + signed(fft1_im)*signed(fft1_im));
                        counter <= counter + 2;
                    end if;





            end case;

        end if;
    end process;


inst1 : dft_top 
port map (
    clk => clock,
    reset => reset,
    nexx => nexx,
    nexx_out => nexx_out,
    X0 => data0_re,
    X1 => data0_im, 
    X2 => data1_re, 
    X3 => data1_im,
    Y0 => fft0_re, 
    Y1 => fft0_im, 
    Y2 => fft1_re, 
    Y3 => fft1_im
);


end Behavioral;