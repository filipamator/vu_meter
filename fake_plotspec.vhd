library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;


--entity declaration
entity fake_plotspec is
port (
            clock           : in std_logic;
            reset           : in std_logic;

            fb_data         : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            fb_wraddress    : OUT STD_LOGIC_VECTOR (16 DOWNTO 0);
            fb_wren         : OUT STD_LOGIC
);
end fake_plotspec;

--architecture definition
architecture Behavioral of fake_plotspec is


TYPE STATE_TYPE IS (ST_IDLE, ST_STORE, ST_FB);
SIGNAL state   : STATE_TYPE;

signal position_x   : integer range 0 to 319 := 0;
signal position_y   : integer range 0 to 239 := 0;
signal fb_address   : integer;
signal counter      : integer := 0;

--type mem512  is array (0 to 511) of std_logic_vector(7 downto 0);
--signal buff : mem512;

begin


    --fb_wraddress <= std_logic_vector(to_unsigned(fb_address, fb_wraddress'length));

    --read process
    fillfb : process (clock,reset)
    
    type mem512  is array (0 to 511) of std_logic_vector(7 downto 0);
    variable buff         : mem512 := ( x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",                                        
                                        x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80",x"80");     
                                        

    
    begin
        if (reset='1') then
            position_x <= 0;
            position_y <= 0;
            counter <= 0;
            fb_wren <= '0';
            state <= ST_IDLE;
        elsif (clock='1' and clock'event) then
            case state is
                when ST_IDLE => 
                    if (counter=1_000_000) then
                        counter <= 0;
                        state <= ST_FB;
                    else
                        counter <= counter + 1;
                    end if;
                when ST_STORE =>
                    state <= ST_IDLE;
                when ST_FB =>

                    if (position_x = 256) then
                        fb_wren <= '0';
                        state <= ST_IDLE;
                    else
                        
                        if (position_y = 239) then
                            position_y <= 0;
                            position_x <= position_x + 1;
                        else
                            position_y <= position_y + 1;
                        end if;
                        
                        if position_y < to_integer(unsigned(buff(position_x))) then
                            fb_data <= (others => '1');
                        else
                            fb_data <= (others => '0');
                        end if;
                        
                        -- position_y := position_y + 1;
                        fb_wraddress <= std_logic_vector(to_unsigned(position_x * 240 + position_y, fb_wraddress'length));
                        fb_wren <= '1';
                     

                    end if;


 
 
            end case;
        end if;
    end process fillfb;



end Behavioral;