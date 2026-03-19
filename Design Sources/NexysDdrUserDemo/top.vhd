library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Nexys4DdrUserDemo is
   port(
      clk_i          : in  std_logic;
      rstn_i         : in  std_logic;
      sw_i           : in  std_logic_vector(15 downto 0);
      btnc_i         : in  std_logic;
      led_o          : out std_logic_vector(15 downto 0); 
      led17_r        : out std_logic; 
      led17_g        : out std_logic; 
      led17_b        : out std_logic;
      disp_seg_o     : out std_logic_vector(7 downto 0);
      disp_an_o      : out std_logic_vector(7 downto 0);
      sclk           : out STD_LOGIC;
      mosi           : out STD_LOGIC;
      miso           : in  STD_LOGIC;
      ss             : out STD_LOGIC
   );
end Nexys4DdrUserDemo;

architecture Behavioral of Nexys4DdrUserDemo is

component ClkGen
port
 (clk_100MHz_i       : in    std_logic;
  clk_100MHz_o       : out   std_logic;
  clk_200MHz_o       : out   std_logic;
  reset_i            : in    std_logic;
  locked_o           : out   std_logic
 );
end component;

component sSegDemo is
port(
   clk_i         : in std_logic;
   rstn_i        : in std_logic;
   accel_x_i     : in std_logic_vector(8 downto 0);
   accel_y_i     : in std_logic_vector(8 downto 0);
   game_status_i : in std_logic_vector(1 downto 0); 
   seg_o         : out std_logic_vector(7 downto 0);
   an_o          : out std_logic_vector(7 downto 0));
end component;

component AccelerometerCtl is
generic 
(
   SYSCLK_FREQUENCY_HZ : integer := 100000000;
   SCLK_FREQUENCY_HZ   : integer := 100000;
   NUM_READS_AVG       : integer := 16;
   UPDATE_FREQUENCY_HZ : integer := 1000
);
port
(
 SYSCLK     : in STD_LOGIC; 
 RESET      : in STD_LOGIC; 
 SCLK       : out STD_LOGIC;
 MOSI       : out STD_LOGIC;
 MISO       : in STD_LOGIC;
 SS         : out STD_LOGIC;
 ACCEL_X_OUT    : out STD_LOGIC_VECTOR (8 downto 0);
 ACCEL_Y_OUT    : out STD_LOGIC_VECTOR (8 downto 0);
 ACCEL_MAG_OUT  : out STD_LOGIC_VECTOR (11 downto 0);
 ACCEL_TMP_OUT  : out STD_LOGIC_VECTOR (11 downto 0)
);
end component;

component RandomColor is
    Port ( clk        : in  STD_LOGIC;  
           btn_random : in  STD_LOGIC;  
           led17_r    : out STD_LOGIC;  
           led17_g    : out STD_LOGIC;  
           led17_b    : out STD_LOGIC;
           color_out  : out STD_LOGIC_VECTOR(1 downto 0));
end component;

signal rst        : std_logic;
signal reset      : std_logic;
signal resetn     : std_logic;
signal locked     : std_logic;
signal clk_100MHz_buf : std_logic;

signal ACCEL_X    : STD_LOGIC_VECTOR (8 downto 0);
signal ACCEL_Y    : STD_LOGIC_VECTOR (8 downto 0);
signal ACCEL_MAG  : STD_LOGIC_VECTOR (11 downto 0);
signal ACCEL_TMP  : STD_LOGIC_VECTOR (11 downto 0);

signal tf_color   : std_logic_vector(1 downto 0); 
signal x_val_int  : integer; 
signal game_status: std_logic_vector(1 downto 0) := "00"; 

begin
   led_o <= sw_i;
   rst <= not rstn_i;
   reset <= rst or (not locked);
   resetn <= not reset;
   
   x_val_int <= conv_integer(ACCEL_X);

   process(clk_100MHz_buf)
   begin
       if rising_edge(clk_100MHz_buf) then
           if tf_color = "01" then -- Green
               if (x_val_int >= 370 and x_val_int <= 398) and (sw_i(15) = '1') and (sw_i(0) = '0') then
                   game_status <= "01"; 
               else
                   game_status <= "10"; 
               end if;
               
           elsif tf_color = "10" then -- Yellow
               if (x_val_int >= 370 and x_val_int <= 398) and (sw_i(0) = '1') and (sw_i(15) = '0') then
                   game_status <= "01"; 
               else
                   game_status <= "10"; 
               end if;
               
           elsif tf_color = "11" then -- Red
               if (x_val_int >= 240 and x_val_int <= 270) and (sw_i(15) = '1')and (sw_i(0) = '1') then
                   game_status <= "01"; 
               else
                   game_status <= "10"; 
               end if;
              
           end if;
       end if;
   end process;

   Inst_ClkGen: ClkGen
   port map (
      clk_100MHz_i   => clk_i,
      clk_100MHz_o   => clk_100MHz_buf,
      clk_200MHz_o   => open,
      reset_i        => rst,
      locked_o       => locked
      );
      
   Inst_SevenSeg: sSegDemo
   port map(
      clk_i          => clk_100MHz_buf,
      rstn_i         => resetn,
      accel_x_i      => ACCEL_X,  
      accel_y_i      => ACCEL_Y,  
      game_status_i  => game_status,
      seg_o          => disp_seg_o,
      an_o           => disp_an_o);

   Inst_AccelerometerCtl: AccelerometerCtl
   generic map
   (
        SYSCLK_FREQUENCY_HZ   => 100000000,
        SCLK_FREQUENCY_HZ     => 100000,
        NUM_READS_AVG         => 16,
        UPDATE_FREQUENCY_HZ   => 1000
   )
   port map
   (
       SYSCLK     => clk_100MHz_buf,
       RESET      => reset, 
       SCLK       => sclk,
       MOSI       => mosi,
       MISO       => miso,
       SS         => ss,
       ACCEL_X_OUT   => ACCEL_X,
       ACCEL_Y_OUT   => ACCEL_Y,
       ACCEL_MAG_OUT => ACCEL_MAG,
       ACCEL_TMP_OUT => ACCEL_TMP
   );
   Inst_RandomColor: RandomColor
   port map(
       clk        => clk_100MHz_buf,
       btn_random => btnc_i,   
       led17_r    => led17_r,  
       led17_g    => led17_g,
       led17_b    => led17_b,
       color_out  => tf_color  
   );

end Behavioral;