library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;


--entity declaration
entity plotspec is
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
end plotspec;

--architecture definition
architecture Behavioral of plotspec is


TYPE STATE_TYPE IS (ST_IDLE, ST_STORE, ST_FB);
SIGNAL state   : STATE_TYPE := ST_IDLE;

--signal position_x   : integer range 0 to 319 := 0;
--signal position_y   : integer range 0 to 239 := 0;
--signal fb_address   : integer;
signal counter      : integer;

--type mem512  is array (0 to 511) of std_logic_vector(7 downto 0);
--signal buff : mem512;

begin


    --fb_wraddress <= std_logic_vector(to_unsigned(fb_address, fb_wraddress'length));

    --read process
    fillfb : process (clock,reset)
    
    type mem512  is array (0 to 511) of std_logic_vector(7 downto 0);
    variable buff         : mem512;
    variable position_x   : integer range 0 to 319 := 0;
    variable position_y   : integer range 0 to 239 := 0;
    variable address      : integer;
    
    begin
        if (reset='1') then
            position_x := 0;
            position_y := 0;
            counter <= 0;
            fb_wren <= '0';
            state <= ST_IDLE;
        elsif (clock='1' and clock'event) then
            case state is
                when ST_IDLE => 
							position_y := 0;
							position_x := 0;
							fb_wren <= '0';
                    if data_in_start='1' then      
                        --buff(0) :=  std_logic_vector(to_unsigned( to_integer(signed(data_in))/2,8));
                        counter <= 0;
                        state <= ST_STORE;
                    end if;
                when ST_STORE =>
                    if (data_in_en='1') then
                        
                        if (data_in = "00000000") then
                            buff(counter) := "00000001";
                        else
                            buff(counter) := data_in;
                        end if;
                        
                        counter <= counter + 1;
                        if (counter=511) then
                            state <= ST_FB;
                        end if;
                    end if;
                when ST_FB =>


                    if (position_x = 320) then
                        fb_wren <= '0';
                        state <= ST_IDLE;
                    else
                        
                        if (position_y = 239) then
                            position_y := 0;
                            position_x := position_x + 1;
                        else
                            position_y := position_y + 1;
                        end if;
                        
                        if position_y < to_integer(unsigned(buff(position_x))) then
                            fb_data <= (others => '1');
                        else
                            fb_data <= (others => '0');
                        end if;
                        
                        address :=  (319 - position_x) * 240 + position_y;
                        -- position_y := position_y + 1;
                        fb_wraddress <= std_logic_vector(to_unsigned(address, fb_wraddress'length));
                        fb_wren <= '1';
                     

                    end if;


 
 
            end case;
        end if;
    end process fillfb;



end Behavioral;