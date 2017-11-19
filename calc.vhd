
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
    data_in     : in std_logic_vector(15 downto 0)
);
end calcfft;


architecture Behavioral of calcfft is
end Behavioral;