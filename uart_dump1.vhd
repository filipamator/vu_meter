library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity uart_dump is
  generic (
    SIZE         : natural := 1024
  );
  port (
    i_clock       : in  std_logic;
    i_reset       : in std_logic;
    i_start		  : in std_logic;
    i_data        : in std_logic_vector(15 downto 0);
    i_enable      : in std_logic;
    o_tx_byte     : out std_logic_vector(7 downto 0);
    o_tx_dv       : out  std_logic;
    i_tx_done     : in std_logic;
    i_tx_active   : in std_logic
  );
end uart_dump;
 
 
architecture RTL of uart_dump is
 
-----------------------------------------------
-- COMPONENTS --------------------------------- 
-----------------------------------------------



COMPONENT fifo_1024x16bit IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrfull		: OUT STD_LOGIC 
	);
END COMPONENT fifo_1024x16bit;


-----------------------------------------------
-- SIGNALS ------------------------------------
-----------------------------------------------

  type t_SM_Main is (ST_IDLE, ST_TXWAIT, ST_WAIT, ST_TXMSB, ST_TXLSB);
  type t_SM_Wr is (ST_IDLE, ST_WRITE);


  signal r_State      : t_SM_Main := ST_IDLE;
  signal r_WrState    : t_SM_Wr := ST_IDLE;

  signal r_NextState  : t_SM_Main;
  signal r_rdreq      : std_logic; 
  signal r_rdempty    : std_logic;
  signal r_data       : std_logic_vector(15 downto 0);
  signal r_waitcounter : integer := 0;
  signal r_wrreq      : std_logic;
  signal r_wrdata     : std_logic_vector(15 downto 0);
  signal r_start_prev : std_logic;
  signal r_wrcounter  : integer := 0;

begin


  process (i_clock, i_reset)
  begin
  
    if (i_reset='1') then                         -- reset
      r_rdreq <= '0';
      o_tx_dv <= '0';
      r_waitcounter <= 0;
      r_State <= ST_IDLE;
    elsif (i_clock='1' and i_clock'event) then
    
      case r_State is
        when ST_IDLE =>  
          if (r_rdempty='0') then                 -- get a 16b byte whenever FIFO is not empty  
            r_rdreq <= '1';                       -- and send over uart MSB and later LSB part of sample
            r_waitcounter <= 1;
            r_NextState <= ST_TXMSB;
            r_State <= ST_WAIT;
          end if;
        when ST_TXMSB =>
        
          r_rdreq <= '0';                    
          if i_tx_active='1' then                 -- wait until uart core is not busy
            r_State <= ST_TXMSB;
          else
            o_tx_byte <= r_data(15 downto 8);     -- send MSB and wait for three cycles of the clock in ST_WAIT state
            o_tx_dv <= '1';
            r_waitcounter <= 50;
            r_NextState <= ST_TXLSB;
            r_State <= ST_WAIT;
          end if;

        when ST_TXLSB =>
          o_tx_dv <= '0';
          if i_tx_active='1' then
            r_State <= ST_TXLSB;
          else
            o_tx_byte <= r_data(7 downto 0);
            o_tx_dv <= '1';
            r_waitcounter <= 50;
            r_State <= ST_WAIT;
            r_NextState <= ST_TXWAIT;
          end if;
          
        when ST_TXWAIT =>
          o_tx_dv <= '0';
          if i_tx_active='1' then
            r_State <= ST_TXWAIT;
          else
            r_State <= ST_IDLE;
          end if;
        
        when ST_WAIT =>
          r_rdreq <= '0';
          o_tx_dv <= '0';
          if (r_waitcounter=0) then
            r_State <= r_NextState;
          else 
            r_waitcounter <= r_waitcounter - 1;
          end if;
      end case;

    
    end if;
  end process;

  process (i_clock, i_reset)
  begin
    if (i_reset='1') then
      r_wrreq <= '0';
      r_wrcounter <= 0;
      r_WrState <= ST_IDLE;
    elsif (i_clock='1' and i_clock'event) then
      r_start_prev <= i_start;
      case r_WrState is
        
        when ST_IDLE =>
          if (r_start_prev='0' and i_start='1') then    -- rising edge of i_start
            r_wrcounter <= 0;
            r_WrState <= ST_WRITE;                      -- start writing samples into fifo
          end if;
        
        
        when ST_WRITE =>
          if r_wrcounter=SIZE then
            r_wrreq <= '0';
            r_WrState <= ST_IDLE;
          else 
            if (i_enable='1') then
              r_wrdata <= i_data;
              r_wrreq <= '1';
              r_wrcounter <= r_wrcounter + 1;
            else
              r_wrreq <= '0';
            end if;
            r_WrState <= ST_WRITE;
          end if;
      
      
      end case;
    end if;
  end process;


  fifo_i1 : fifo_1024x16bit
    PORT MAP
    (
      data    => r_wrdata, -- i_data,    --
      rdclk	  => i_clock,
      rdreq	  => r_rdreq,
      wrclk	  => i_clock,
      wrreq		=> r_wrreq, -- i_enable,  --
      q	      => r_data,
      rdempty => r_rdempty,
      wrfull  => open
    );
   
end RTL;
