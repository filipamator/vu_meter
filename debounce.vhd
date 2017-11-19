LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY debounce IS
  GENERIC(
    counter_size  :  INTEGER := 5_000_000);
  PORT(
    clk     : IN  STD_LOGIC;  --input clock
    reset   : IN STD_LOGIC;   --reset
    button  : IN  STD_LOGIC;  --input signal to be debounced
    result  : OUT STD_LOGIC); --debounced signal
END debounce;

ARCHITECTURE logic OF debounce IS


    type t_SM_Main is (ST_IDLE, ST_WAIT);
    signal r_State      : t_SM_Main := ST_IDLE;

    signal r_button_prev : STD_LOGIC := '0';
    signal counter : INTEGER := 0;

BEGIN


    PROCESS(clk)
        BEGIN
            IF (reset='1') THEN
                result <= '0';
                r_State <= ST_IDLE;
            ELSIF(clk'EVENT and clk = '1') THEN    
                r_button_prev <= button;
                case r_State is
                    when ST_IDLE =>
                        IF (r_button_prev='0' and button='1') THEN
                            counter <= counter_size;
                            result <= '1';
                            r_State <= ST_WAIT;
                        END IF;
                    when ST_WAIT =>
                        result <= '0';
                        IF counter = 0 THEN
                            r_State <= ST_IDLE;
                        ELSE
                            counter <= counter - 1;
                        END IF;

                end case;
            END IF;

    END PROCESS;


END logic;
