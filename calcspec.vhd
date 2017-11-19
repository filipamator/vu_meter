library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;


--entity declaration
entity calcspec is
port (
            clock    : in std_logic;
            reset    : in std_logic;
            data_en  : in std_logic;
            data_in  : in std_logic_vector(15 downto 0);
            data_out : out std_logic_vector(15 downto 0);
            data_out_en : out std_logic;
            data_out_start : out std_logic
);
end calcspec;

--architecture definition
architecture Behavioral of calcspec is


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
		remainder		: OUT STD_LOGIC_VECTOR (16 DOWNTO 0)
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

component sample_avg is
	GENERIC (
				d_width		: natural := 16;
                stage       : natural := 4
	);
	PORT (
				clk			: IN STD_LOGIC;
				data_in_en	: IN STD_LOGIC;
				reset_n		: IN STD_LOGIC;
				data_in		: IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
				data_out	: OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
				ce			: OUT STD_LOGIC
	);	
end component sample_avg;



signal X0, X1, X2, X3 : std_logic_vector(15 downto 0) := (others => '0');
signal Y0, Y1, Y2, Y3 : std_logic_vector(15 downto 0) := (others => '0');

signal nexx, nexx_out : std_logic := '0';

TYPE STATE_TYPE IS (ST_IDLE, ST_STORE, ST_SQRT, ST_TOFP);
SIGNAL state   : STATE_TYPE;

type state_type2 is (ST_IDLE,ST_STORE,ST_FFT);
signal state_store : state_type2;

signal writecounter : integer := 0;
signal storecounter : integer := 0;
signal tempcounter : integer := 0;

signal store_msb    : std_logic := '0';
signal busy         : std_logic := '0';
signal data_en_avg  : std_logic := '0';
signal data_in_avg  : std_logic_vector(15 downto 0);

SIGNAL sqrt_in : std_logic_vector(31 downto 0);
SIGNAL sqrt_out : std_logic_vector(15 downto 0);
SIGNAL to_int2fp : std_logic_vector(15 downto 0) := (others => '0');
SIGNAL from_int2fp  : std_logic_vector(15 downto 0) := (others => '0');
SIGNAL from_log     : std_logic_vector(31 downto 0) := (others => '0');
SIGNAL to_log       : std_logic_vector(31 downto 0) := (others => '0');
SIGNAL log_amp      : std_logic_vector(31 downto 0) := (others => '0');

type Memory_1k is array (0 to 1023) of std_logic_vector(31 downto 0);
signal fft : Memory_1k := (others => (others => '0'));
signal samples : Memory_1k := (others => (others => '0'));

signal reset_n : std_logic;



begin

    reset_n <= not reset;

    --read process
    reading : process (clock,reset)
    begin
        if (reset='1') then
            storecounter <= 0;
            store_msb <= '0';
            nexx <= '0';
            state_store <= ST_IDLE;
        elsif (clock='1' and clock'event) then

            case state_store is
                when ST_IDLE =>
                    if (data_en_avg='1' and busy='0') then
                        samples(0)(31 downto 16) <= data_in_avg;
                        store_msb <= '0';
                        storecounter <= 0;
                        state_store <= ST_STORE;
                    end if;
                when ST_STORE =>        
                    if data_en_avg='1' then
                        if store_msb='0' then
                            samples(storecounter)(15 downto 0) <= data_in_avg;
                            storecounter <= storecounter + 1;
                        else 
                            samples(storecounter)(31 downto 16) <= data_in_avg;
                        end if;
                        store_msb <= not store_msb;
                        if storecounter=511 then
                            storecounter <= 0;
                            nexx <= '1';
                            state_store <= ST_FFT;
                        end if;
                    end if;
                when ST_FFT =>
                    nexx <= '0';
                    X0 <= samples(storecounter)(31 downto 16);
                    X1 <= (others => '0');
                    X2 <= samples(storecounter)(15 downto 0);
                    X3 <= (others => '0');
                    if storecounter=511 then
                        storecounter <= 0;
                        state_store <= ST_IDLE;
                    else
                        storecounter <= storecounter + 1;
                    end if;
            end case;
        end if;
    end process reading;




    --write process
    writing : process(clock,reset)

    begin
        if reset='1' then
            tempcounter <= 0;
            state <= ST_IDLE;
            busy <= '0';
            data_out_en <= '0';
            data_out_start <= '0';
        elsif (clock='1' and clock'event) then
        
            case (state) is

                when ST_IDLE =>
                    data_out_en <= '0';
                    if nexx_out ='1' then
                        writecounter <= 0;
                        busy <= '1';
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
                        busy <= '0';
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
                        data_out <= from_int2fp;
                        data_out_en <= '1';
                        tempcounter <= tempcounter + 1;

                        if writecounter=39 then
                            data_out_start <= '1';
                        else
                            data_out_start <= '0';
                        end if;

                        --datatosave := to_integer(signed(from_int2fp));
                        --write(outline, datatosave);
                        --writeline(outfile, outline);
                    end if;
                    writecounter <= writecounter + 1;
            end case;
        
        
        
        end if;
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
		q	 => sqrt_out,
		remainder	 => open
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


-- calc_inst1 : calcfft PORT MAP (
--         clock   => clock,
--         enable  => nexx,
--         reset_n => '1',
--         data_in =>
-- );



sample_avg_i1 : sample_avg
	GENERIC MAP (
				d_width => 16,
                stage   => 0
	)
	PORT MAP (
				clk         => clock,
				data_in_en  => data_en,
				reset_n	    => reset_n,
				data_in     => data_in,
				data_out    => data_in_avg,
				ce		    => data_en_avg
	);


end Behavioral;