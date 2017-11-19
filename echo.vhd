library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE IEEE.STD_LOGIC_SIGNED.all;

entity echo is
	generic (
		DELAY		: natural := 4800
	);
	port (
	
		clk 		: in std_logic;
		ce			: in std_logic;
		data_in	: in std_logic_vector(31 downto 0);
		data_out : out std_logic_vector(31 downto 0)
	);
end entity echo;


architecture Behavioral of echo is

	component D_FF_VHDL is
		port
		(
			clk : in std_logic;

			rst : in std_logic;
			pre : in std_logic;
			ce  : in std_logic;
			
			d : in std_logic_vector(31 downto 0);
			q : out std_logic_vector(31 downto 0)
		);
	end component D_FF_VHDL;

    type vector32 is array (natural range <>) of std_logic_vector(31 downto 0);
    signal s_signal : vector32(DELAY downto 0);


begin

	s_signal(0) <= data_in;
	data_out  <= s_signal(DELAY);

	GEN_REG:
   for I in 0 to DELAY-1 generate
            REG: D_FF_VHDL 
                port map (
                    clk => clk,
                    rst => '0',
                    pre => '0',
						  ce => ce,
                    d => s_signal(I),
                    q => s_signal(I+1)
                );
	end generate;



end Behavioral;


----------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity D_FF_VHDL is
   port
   (
      clk : in std_logic;

      rst : in std_logic;
      pre : in std_logic;
      ce  : in std_logic;
      
      d : in std_logic_vector(31 downto 0);
      q : out std_logic_vector(31 downto 0)
   );
end entity D_FF_VHDL;
 
architecture Behavioral of D_FF_VHDL is
begin
   process (clk) is
   begin
      if rising_edge(clk) then  
         if (rst='1') then   
            q <= (others => '0');
         elsif (pre='1') then
            q <= (others => '1');
         elsif (ce='1') then
            q <= d;
         end if;
      end if;
   end process;
end architecture Behavioral;