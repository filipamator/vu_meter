library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;


--entity declaration
entity dataacq is
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
end dataacq;

--architecture definition
architecture Behavioral of dataacq is



TYPE STATE_TYPE IS (ST_IDLE, ST_STORE,ST_WRITE);
SIGNAL state   : STATE_TYPE;


signal writecounter : integer := 0;
signal storecounter : integer := 0;


type Memory is array (0 to SIZE-1) of std_logic_vector(15 downto 0);
signal samples : Memory := (others => (others => '0'));

signal reset_n : std_logic;


begin

    reset_n <= not i_reset;

    reading : process (i_clock,i_reset)
    begin
        if (i_reset='1') then
            o_data <= (others => '0');
            o_data_en <= '0';
            o_data_start <= '0';
            storecounter <= 0;
            state <= ST_IDLE;
        elsif (i_clock='1' and i_clock'event) then

            case state is
                when ST_IDLE =>
                    o_data_en <= '0';
                    if (i_start='1') then
                        storecounter <= 0;
                        state <= ST_STORE;
                    end if;
                when ST_STORE =>        
                    if i_data_en='1' then
                        samples(storecounter) <= i_data;
                        storecounter <= storecounter + 1;
                    end if;
                        
                    if storecounter=SIZE-1 then
                        storecounter <= 0;
                        state <= ST_WRITE;
                        o_data_start <= '1';
                    end if;

                when ST_WRITE =>
                    o_data_start <= '0';
                    o_data <= samples(storecounter);
                    o_data_en <= '1';
                    if storecounter=SIZE-1 then
                        storecounter <= 0;
                        state <= ST_IDLE;
                    else
                        storecounter <= storecounter + 1;
                    end if;
            end case;
        end if;
    end process reading;




end Behavioral;