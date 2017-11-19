library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity windowfunction is
generic (
		SIZE		: natural := 1024
);
port (
        i_clock     : in std_logic;
        i_reset     : in std_logic;
        i_data      : in std_logic_vector(15 downto 0);
		i_data_start: in std_logic;
        i_data_en   : in std_logic;

		o_data		: out std_logic_vector(15 downto 0);
		o_data_en	: out std_logic;
		o_data_start: out std_logic
	
);
end entity windowfunction;


architecture rtl of windowfunction is


------------------------
-- Components ----------
------------------------

component hannwindow is
port (
        i_sample    : in STD_LOGIC_VECTOR(9 downto 0);
        o_value     : out STD_LOGIC_VECTOR(31 downto 0)
);
end component hannwindow;

component fp_mult IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component fp_mult;



component int2fp
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;



component fp2int
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
end component;



------------------------
-- Signals -------------
------------------------

SIGNAL r_data_fp            : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
SIGNAL r_wdata_fp           : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
SIGNAL r_window_fp          : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
SIGNAL r_wdata			    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
SIGNAL r_data				: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
SIGNAL r_coefaddr			: STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
SIGNAL r_coef				: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal r_counter			: integer;
signal r_temp				: integer := 0;

TYPE STATE_TYPE IS (ST_IDLE, ST_WRITE);
SIGNAL state   : STATE_TYPE := ST_IDLE;

begin





	process (i_clock, i_reset)
	begin
		if i_reset='1' then
			r_counter <= 0;
			state <= ST_IDLE;
		elsif (i_clock='1' and i_clock'event) then
			case state is
				when ST_IDLE =>
					if (i_data_start='1') then
						r_counter <= 0;
						state <= ST_WRITE;
					end if;
				when ST_WRITE =>
					

					if (r_counter < 1024) then
						r_data <= i_data;
						r_counter <= r_counter + 1;
					elsif r_counter = SIZE-1+18 then
						r_counter <= 0;
						state <= ST_IDLE;
					else 
						r_counter <= r_counter + 1;
					end if;

					-- if (r_counter < 37) then								-- From 0 to 35
					-- 	r_counter <= r_counter + 1;
					-- elsif (r_counter = 37 ) then
					-- 	r_counter <= r_counter + 1;
					-- 	o_data_start <= '1';
					-- elsif (r_counter > 37 and r_counter < 1062) then		-- From 37 to 1060
					-- 	o_data_start <= '0';
					-- 	o_data_en <= '1';
					-- 	o_data <= r_wdata;
					-- 	r_temp <= r_temp + 1;
					-- 	r_counter <= r_counter + 1;
					-- else 
					-- 	o_data_en <= '0';
					-- 	r_counter <= 0;
					-- 	state <= ST_IDLE;
					-- end if;

			end case;
		end if;
	end process;



	process (i_clock, i_reset)
	begin
		if i_reset='1' then
		elsif (i_clock='1' and i_clock'event) then
			if (r_counter > 6 and r_counter < 1031) then
				r_coefaddr <=  std_logic_vector(to_unsigned(r_counter-6, r_coefaddr'length));
			end if;
		end if;
	end process;


	process (i_clock, i_reset)
	begin
		if i_reset='1' then
			o_data_en <= '0';
			o_data_start <= '0';
			r_temp <= 0;
		elsif (i_clock='1' and i_clock'event) then
			o_data_en <= '0';
			if r_counter = 17 then
				o_data_start <= '1';
			elsif (r_counter > 17 and r_counter < 1042) then
				--r_temp <= r_temp + 1;
				o_data_en <= '1';
				o_data_start <= '0';
				o_data <= r_wdata;
			end if;
		end if;
	end process;


hannwindow_i1 : hannwindow
	port map (
			i_sample	=> r_coefaddr,
			o_value     => r_coef
	);

int2fp_i1  : int2fp
	PORT MAP
	(
		clock		=> i_clock,
		dataa		=> r_data,
		result		=> r_data_fp
	);

fp2int_i1 : fp2int
	PORT MAP
	(
		clock		=> i_clock,	
		dataa		=> r_wdata_fp,
		result		=> r_wdata
	);

fp_mult_i1 : fp_mult
	PORT MAP
	(
		clock		=> i_clock,
		dataa		=> r_data_fp,
		datab		=> r_coef,	-- 12.1602454933
		result		=> r_wdata_fp
	);

end rtl;