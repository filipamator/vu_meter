library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity powerlog is
port (
        i_clock     : in std_logic;
        i_reset     : in std_logic;
        i_data      : in std_logic_vector(31 downto 0);
		i_data_start: in std_logic;
        i_data_en   : in std_logic;

		o_data		: out std_logic_vector(31 downto 0);
		o_data_en	: out std_logic;
		o_data_start: out std_logic
	
);
end entity powerlog;


architecture rtl of powerlog is


------------------------
-- Components ----------
------------------------

component int2fp IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component int2fp;

component fplog IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component fplog;

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



component fptoi32
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clk_en		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;


component i32tofp
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clk_en		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;


------------------------
-- Signals -------------
------------------------

SIGNAL r_data_fp           : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
SIGNAL r_logdata_fp        : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
SIGNAL r_logdata			: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
SIGNAL r_logdata_amp_fp		: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
signal r_counter			: integer := 0;
signal r_temp				: integer := 0;

TYPE STATE_TYPE IS (ST_IDLE, ST_WRITE);
SIGNAL state   : STATE_TYPE := ST_IDLE;

begin


	process (i_clock, i_reset)
	begin
		if i_reset='1' then
			r_counter <= 0;
			o_data_en <= '0';
			o_data_start <= '0';
			state <= ST_IDLE;
		elsif (i_clock='1' and i_clock'event) then
			case state is

				when ST_IDLE =>
					o_data_en <= '0';
					if (i_data_start='1') then
						state <= ST_WRITE;
					end if;
				when ST_WRITE =>
					if (r_counter < 37) then								-- From 0 to 35
						r_counter <= r_counter + 1;
					elsif (r_counter = 37 ) then
						r_counter <= r_counter + 1;
						o_data_start <= '1';
					elsif (r_counter > 37 and r_counter < 1062) then		-- From 37 to 1060
						o_data_start <= '0';
						o_data_en <= '1';
						o_data <= r_logdata;
						r_temp <= r_temp + 1;
						r_counter <= r_counter + 1;
					else 
						o_data_en <= '0';
						r_counter <= 0;
						state <= ST_IDLE;
					end if;

			end case;
		end if;
	end process;



 int2fp_i1  : i32tofp
	PORT MAP
	(
		aclr		=> i_reset,
		clk_en		=> '1',
		clock		=> i_clock,
		dataa		=> i_data,
		result		=> r_data_fp
	);


fplog_i1 : fplog
PORT MAP
	(
		clock       => i_clock,	
		data		=> r_data_fp,
		result		=> r_logdata_fp
	);

fp2int_i1 : fptoi32
	PORT MAP
	(
		aclr		=> i_reset,
		clk_en		=> '1',
		clock		=> i_clock,	
		dataa		=> r_logdata_amp_fp,
		result		=> r_logdata
	);


fp_mult_i1 : fp_mult
	PORT MAP
	(
		clock		=> i_clock,
		dataa		=> r_logdata_fp,
		datab		=>  "01000001110000101001000001011110",	-- 2*12.1602454933
		result		=> r_logdata_amp_fp
	);

end rtl;