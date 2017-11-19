
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

--entity declaration
entity filehandle is
end filehandle;

--architecture definition
architecture Behavioral of filehandle is

--period of clock,bit for indicating end of file.
signal clock,endoffile : std_logic := '0';
signal dataread : integer;
-- signal datatosave : integer;
signal linenumber : integer:=1; 
signal read_en  : std_logic := '0';


signal X0, X1, X2, X3 : std_logic_vector(15 downto 0) := (others => '0');
signal Y0, Y1, Y2, Y3 : std_logic_vector(15 downto 0) := (others => '0');
signal reset : std_logic := '0';
signal nexx, nexx_out : std_logic := '0';
TYPE STATE_TYPE IS (ST_IDLE, ST_STORE, ST_SQRT, ST_TOFP);
SIGNAL state   : STATE_TYPE;
signal writecounter : integer := 0;

SIGNAL temp : std_logic_vector(31 downto 0);
SIGNAL sqrt_in : std_logic_vector(31 downto 0);
SIGNAL sqrt_out : std_logic_vector(15 downto 0);
SIGNAL to_int2fp : std_logic_vector(15 downto 0) := (others => '0');
SIGNAL from_int2fp  : std_logic_vector(15 downto 0) := (others => '0');
SIGNAL from_log     : std_logic_vector(31 downto 0) := (others => '0');
SIGNAL to_log       : std_logic_vector(31 downto 0) := (others => '0');
SIGNAL log_amp      : std_logic_vector(31 downto 0) := (others => '0');

type Memory_1k is array (0 to 1023) of std_logic_vector(31 downto 0);
signal fft : Memory_1k;


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


component sqrt IS
	PORT
	(
		radical		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		remainder		: OUT STD_LOGIC_VECTOR (17 DOWNTO 0)
	);
END component sqrt;

component int2fp IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component int2fp;


component fp2int IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component fp2int;


component fp_mult IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component fp_mult;


component fplog IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component fplog;

component calcfft is
port (
    clock       : in std_logic;
    enable      : in std_logic;
    reset_n     : in std_logic;
    data_in     : in std_logic_vector(15 downto 0)
);
end component calcfft;



begin

    clock <= not (clock) after 1 ns;    --clock with time period 1 ns
--    datatosave <= dataread;



    main : process is
    begin

        
        wait until rising_edge(clock);
        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';
        wait until rising_edge(clock);
        nexx <= '1';
        read_en <= '1';
        wait until rising_edge(clock);
        nexx <= '0';

        wait for 100 us;

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
                --dataread <= dataread1;
                X0 <= std_logic_vector(to_signed(dataread1, X0'length));
                X1 <= (others => '0');


                readline(infile, inline);      
                read(inline, dataread1);

                X2 <= std_logic_vector(to_signed(dataread1, X2'length));
                X3 <= (others => '0');

                linenumber <= linenumber + 1;

            else
                endoffile <='1';         
            end if;

        end if;

    end process reading;




    --write process
    writing : process(clock)
        file      outfile  : text is out "2.txt";  --declare output file
        variable  outline  : line;   --line number declaration  
        variable datatosave : integer;

    begin

        if (clock='1' and clock'event) then
        
            case (state) is

                when ST_IDLE =>
                    if nexx_out ='1' then
                        writecounter <= 0;
                        state <= ST_STORE;
                    else
                        state <= ST_IDLE;
                    end if;

                when ST_STORE =>

                    if (writecounter = 512) then
                        
                        writecounter <= 1;
                        sqrt_in <= fft(0);
                        
                        state <= ST_SQRT;
                    else
                        fft(2*writecounter) <= std_logic_vector(signed(Y0)*signed(Y0) + signed(Y1)*signed(Y1));
                        fft(2*writecounter+1) <= std_logic_vector(signed(Y2)*signed(Y2) + signed(Y3)*signed(Y3));
                        writecounter <= writecounter + 1;
                    end if;


                when ST_SQRT =>


                    if (writecounter=1024) then
                        fft(1023) <=  x"0000" & sqrt_out;
                        writecounter <= 0;
                        state <= ST_TOFP;
                    else
                        for i in 0 to 1 loop
                            case i is
                                when 0 =>
                                    sqrt_in <= fft(writecounter);
                                when 1 =>
                                    fft(writecounter-1) <= x"0000" & sqrt_out;
                            end case;
                        end loop;

                        writecounter <= writecounter + 1;
                    end if;


                when ST_TOFP =>

                    if (writecounter=1062) then     -- 1023 + 33 cycles 
                        state <= ST_IDLE;
                    elsif (writecounter < 1024) then
                        if (fft(writecounter)(15 downto 0) = x"0000") then
                            to_int2fp <= "0000000000000001";
                        else
                            to_int2fp <= fft(writecounter)(15 downto 0);
                        end if;

                        
                        writecounter <= writecounter + 1;
                    end if;

                    if ((writecounter > 38) and (writecounter < 1063)) then
                        fft(writecounter - 39) <= x"0000" & from_int2fp;
                        datatosave := to_integer(signed(from_int2fp));
                        write(outline, datatosave);
                        writeline(outfile, outline);
                    end if;
                    
                    writecounter <= writecounter + 1;



                        -- datatosave :=  to_integer(signed(proc_spectrum1));
                        -- write(outline, datatosave);
                        -- writeline(outfile, outline);

                        -- datatosave :=  to_integer(signed(proc_spectrum2));
                        -- write(outline, datatosave);
                        -- writeline(outfile, outline);






            end case;
        
        
        end if;



--        wait until clock = '0' and clock'event;
--        if(endoffile='0') then   --if the file end is not reached.
--           write(outline, datatosave);
--            writeline(outfile, outline);
--           -- linenumber <= linenumber + 1;
--        else
--            null;
--        end if;
    end process writing;




inst1 : dft_top 
port map (
    clk => clock,
    reset => reset,
    nexx => nexx,
    nexx_out    => nexx_out,
    X0 => X0,
    X1 => X1, 
    X2 => X2, 
    X3 => X3,

    Y0 => Y0, 
    Y1 => Y1, 
    Y2 => Y2, 
    Y3 => Y3 
);


sqrt_inst1 : sqrt 
PORT MAP (
		radical	 => sqrt_in,
		q	 => sqrt_out
		-- remainder	 => remainder_sig
	);



int2fp_inst : int2fp 
        PORT MAP (
		clock	 => clock,
		dataa	 => to_int2fp,
		result	 => to_log
	);

fplog_inst1 :  fplog PORT MAP (
		clock	 => clock,
		data	 => to_log,
		result	 => from_log
	);

fp_mult_inst : fp_mult PORT MAP (
		clock	 => clock,
		dataa	 => from_log,
		datab	 => "01000010110010000000000000000000",
		result	 => log_amp
	);


fp2int_inst : fp2int PORT MAP (
		clock	 => clock,
		dataa	 => log_amp,
		result	 => from_int2fp
	);


calc_inst1 : calcfft PORT MAP (
        clock   => clock,
        enable  => nexx,
        reset_n => '1',
        data_in =>
);



end Behavioral;