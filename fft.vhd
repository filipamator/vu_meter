library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use ieee.numeric_std.all;


--entity declaration
entity fft is
generic (
            SIZE    : natural := 1024
);
port (
            clock    : in std_logic;
            reset    : in std_logic;
            data_start : in std_logic;
            data_en  : in std_logic;
            data_in  : in std_logic_vector(15 downto 0);
            data_fft_out : out std_logic_vector(31 downto 0);
            data_fft_out_en : out std_logic;
            data_fft_out_start : out std_logic
);
end fft;

--architecture definition
architecture Behavioral of fft is


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

TYPE STATE_TYPE IS (ST_IDLE, ST_STORE,ST_WRITE);
SIGNAL state   : STATE_TYPE;

type state_type2 is (ST_IDLE,ST_STORE,ST_FFT);
signal state_store : state_type2;

signal writecounter : integer := 0;
signal storecounter : integer := 0;

signal store_msb    : std_logic := '0';
signal data_en_avg  : std_logic := '0';
signal data_in_avg  : std_logic_vector(15 downto 0);


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

                    if data_start='1' then
                        state_store <= ST_STORE;
                        storecounter <= 0;
                        store_msb <= '1';
                    end if;

                    -- if (data_en_avg='1') then
                    --     samples(0)(31 downto 16) <= data_in_avg;
                    --     store_msb <= '0';
                    --     storecounter <= 0;
                    --     state_store <= ST_STORE;
                    -- end if;
                when ST_STORE =>        
                    if data_en_avg='1' then
                        if store_msb='0' then
                            samples(storecounter)(15 downto 0) <= data_in_avg;
                            storecounter <= storecounter + 1;
                        else 
                            samples(storecounter)(31 downto 16) <= data_in_avg;
                        end if;
                        store_msb <= not store_msb;
                        if storecounter=SIZE/2 - 1 then
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
                    if storecounter=SIZE/2-1 then
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
            state <= ST_IDLE;
            data_fft_out_en <= '0';
            data_fft_out_start <= '0';
            data_fft_out <= (others => '0');
        elsif (clock='1' and clock'event) then
        
            case (state) is

                when ST_IDLE =>
                    data_fft_out <= (others => '0');
                    data_fft_out_en <= '0';
                    if nexx_out ='1' then
                        -- data_fft_out_start <= '1';
                        writecounter <= 0;
                        state <= ST_STORE;
                    else
                        state <= ST_IDLE;
                    end if;

                when ST_STORE =>
                    -- data_fft_out_start <= '0';
                    if (writecounter = SIZE/2) then
                        writecounter <= 0;
                        data_fft_out_start <= '1';
                        state <= ST_WRITE;
                    else
                        fft(2*writecounter) <= std_logic_vector(signed(Y0)*signed(Y0) + signed(Y1)*signed(Y1));
                        fft(2*writecounter+1) <= std_logic_vector(signed(Y2)*signed(Y2) + signed(Y3)*signed(Y3));
                        writecounter <= writecounter + 1;
                    end if;


                when ST_WRITE =>
                    data_fft_out_start <= '0';
                    if (writecounter=SIZE) then
                        data_fft_out_en <= '0';
                        data_fft_out <= (others => '0');
                        state <= ST_IDLE;                        
                    else
                        data_fft_out_en <= '1';
                        if fft(writecounter)="00000000000000000000000000000000" then
                            data_fft_out <= "00000000000000000000000000000001";
                        else
                            data_fft_out <= fft(writecounter);
                        end if;
                        writecounter <= writecounter + 1;
                    end if;

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