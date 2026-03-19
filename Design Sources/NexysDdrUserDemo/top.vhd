library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
    port (
        clk_100MHz_i : in  std_logic;
        clk_100MHz_o : out std_logic;
        clk_200MHz_o : out std_logic;
        reset_i      : in  std_logic;
        locked_o     : out std_logic
    );
    end component;

    component AccelerometerCtl is
    generic (
        SYSCLK_FREQUENCY_HZ : integer := 100000000;
        SCLK_FREQUENCY_HZ   : integer := 100000;
        NUM_READS_AVG       : integer := 16;
        UPDATE_FREQUENCY_HZ : integer := 1000
    );
    port (
        SYSCLK        : in  STD_LOGIC; 
        RESET         : in  STD_LOGIC; 
        SCLK          : out STD_LOGIC;
        MOSI          : out STD_LOGIC;
        MISO          : in  STD_LOGIC;
        SS            : out STD_LOGIC;
        ACCEL_X_OUT   : out STD_LOGIC_VECTOR (8 downto 0);
        ACCEL_Y_OUT   : out STD_LOGIC_VECTOR (8 downto 0);
        ACCEL_MAG_OUT : out STD_LOGIC_VECTOR (11 downto 0);
        ACCEL_TMP_OUT : out STD_LOGIC_VECTOR (11 downto 0)
    );
    end component;

    component RandomColor is
    Port ( 
        clk        : in  STD_LOGIC;  
        btn_random : in  STD_LOGIC;  
        led17_r    : out STD_LOGIC;  
        led17_g    : out STD_LOGIC;  
        led17_b    : out STD_LOGIC;
        color_out  : out STD_LOGIC_VECTOR(1 downto 0)
    );
    end component;

    component countdown_7seg is
    Port (
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        start         : in  STD_LOGIC;
        load_value_ms : in  STD_LOGIC_VECTOR(13 downto 0);
        max_time_ms   : in  STD_LOGIC_VECTOR(13 downto 0);
        display_en    : in  STD_LOGIC;
        seg           : out STD_LOGIC_VECTOR(7 downto 0);
        an            : out STD_LOGIC_VECTOR(7 downto 0);
        led_r         : out STD_LOGIC_VECTOR(15 downto 0);
        time_ms_out   : out STD_LOGIC_VECTOR(13 downto 0);
        time_up       : out STD_LOGIC
    );
    end component;

    component sSegDemo is
    port(
       clk_i         : in std_logic;
       mode_i        : in std_logic_vector(1 downto 0); -- 00: Press Start, 01: Playing, 10: Game Over / High Score
       score_i       : in integer range 0 to 99;
       hi_score_i    : in integer range 0 to 99;
       seg_o         : out std_logic_vector(7 downto 0);
       an_o          : out std_logic_vector(7 downto 0)
    );
    end component;

    type state_type is (ST_IDLE, ST_GEN_NEXT, ST_SHOW_SEQ, ST_USER_WAIT, ST_CHECK, ST_PASS, ST_GAMEOVER);
    signal state : state_type := ST_IDLE;

    type color_array is array (0 to 15) of std_logic_vector(1 downto 0);
    signal sequence : color_array;
    signal seq_len  : integer range 0 to 15 := 0;
    signal seq_ptr  : integer range 0 to 15 := 0;

    signal clk_100MHz : std_logic;
    signal rst        : std_logic;
    signal reset      : std_logic;
    signal locked     : std_logic;

    signal ACCEL_X    : STD_LOGIC_VECTOR (8 downto 0);
    signal x_val_int  : integer;

    signal rand_color : std_logic_vector(1 downto 0);
    signal btn_pulse  : std_logic := '0';
    signal btn_prev   : std_logic := '0';

    signal cd_start   : std_logic := '0';
    signal cd_time_up : std_logic;
    signal cd_seg     : std_logic_vector(7 downto 0);
    signal cd_an      : std_logic_vector(7 downto 0);
    signal cd_leds    : std_logic_vector(15 downto 0);

    signal demo_seg   : std_logic_vector(7 downto 0);
    signal demo_an    : std_logic_vector(7 downto 0);
    signal demo_mode  : std_logic_vector(1 downto 0) := "00";

    signal current_score : integer range 0 to 99 := 0;
    signal high_score    : integer range 0 to 99 := 0;

    signal timer_cnt  : integer := 0;
    constant SHOW_TIME : integer := 1000; -- Reduced for simulation (was 100_000_000)

begin
   rst <= not rstn_i;
   reset <= rst or (not locked);
   x_val_int <= to_integer(unsigned(ACCEL_X));

   -- State Machine Logic
   process(clk_100MHz)
   begin
       if rising_edge(clk_100MHz) then
           if reset = '1' then
               state <= ST_IDLE;
               seq_len <= 0;
               current_score <= 0;
               demo_mode <= "00";
               cd_start <= '0';
           else
               btn_pulse <= btnc_i and (not btn_prev);
               btn_prev <= btnc_i;
               cd_start <= '0';

               case state is
                   when ST_IDLE =>
                       demo_mode <= "00";
                       if btn_pulse = '1' then
                           seq_len <= 0;
                           current_score <= 0;
                           state <= ST_GEN_NEXT;
                       end if;

                   when ST_GEN_NEXT =>
                       sequence(seq_len) <= rand_color;
                       seq_len <= seq_len + 1;
                       seq_ptr <= 0;
                       timer_cnt <= 0;
                       state <= ST_SHOW_SEQ;
                       demo_mode <= "01";

                   when ST_SHOW_SEQ =>
                       -- Show current color on RGB LED
                       if timer_cnt < SHOW_TIME then
                           timer_cnt <= timer_cnt + 1;
                           case sequence(seq_ptr) is
                               when "01" => led17_r<='0'; led17_g<='1'; led17_b<='0'; -- Green
                               when "10" => led17_r<='1'; led17_g<='1'; led17_b<='0'; -- Yellow
                               when "11" => led17_r<='1'; led17_g<='0'; led17_b<='0'; -- Red
                               when others => led17_r<='0'; led17_g<='0'; led17_b<='0';
                           end case;
                       else
                           timer_cnt <= 0;
                           if seq_ptr < seq_len - 1 then
                               seq_ptr <= seq_ptr + 1;
                           else
                               seq_ptr <= 0;
                               cd_start <= '1'; -- Start countdown for user input
                               state <= ST_USER_WAIT;
                           end if;
                       end if;

                   when ST_USER_WAIT =>
                       -- Wait for user to match the CURRENT color in sequence
                       -- For simplicity, let's say user must match then press button to confirm?
                       -- Or auto-check when countdown ends or matches?
                       -- User requirement: "start countdown if pass random another color"
                       -- Let's check matching logic here
                       if cd_time_up = '1' then
                           state <= ST_GAMEOVER;
                       else
                           -- Simplified check logic
                           state <= ST_CHECK;
                       end if;

                   when ST_CHECK =>
                       -- Check if current sequence index matches
                       -- For now, let's just use the logic from previous top
                       -- (simplified to just one check for the whole sequence for now to fit complexity)
                       -- Actually, user wants "show first color then second color just random then start countdown"
                       -- This implies testing the whole sequence at once or one by one?
                       -- "if pass random another color" -> usually means passing the current level.
                       
                       -- Logic for passing the level (matching the LAST color randomized)
                       -- (Logic as per existing code but checking against sequence(seq_len-1))
                       state <= ST_PASS; -- Temporary transition

                   when ST_PASS =>
                       current_score <= seq_len;
                       if seq_len > high_score then
                           high_score <= seq_len;
                       end if;
                       state <= ST_GEN_NEXT;

                   when ST_GAMEOVER =>
                       demo_mode <= "10";
                       if btn_pulse = '1' then
                           state <= ST_IDLE;
                       end if;
               end case;
           end if;
       end if;
   end process;

   -- Component Instantiations
   Inst_ClkGen: ClkGen port map (
      clk_100MHz_i   => clk_i,
      clk_100MHz_o   => clk_100MHz,
      clk_200MHz_o   => open,
      reset_i        => rst,
      locked_o       => locked
   );

   Inst_Accel: AccelerometerCtl port map (
       SYSCLK => clk_100MHz, RESET => reset, SCLK => sclk, MOSI => mosi, MISO => miso, SS => ss,
       ACCEL_X_OUT => ACCEL_X, ACCEL_Y_OUT => open, ACCEL_MAG_OUT => open, ACCEL_TMP_OUT => open
   );

   Inst_Rand: RandomColor port map (
       clk => clk_100MHz, btn_random => btnc_i, led17_r => open, led17_g => open, led17_b => open,
       color_out => rand_color
   );

   Inst_CD: countdown_7seg port map (
       clk => clk_100MHz, reset => reset, start => cd_start,
       load_value_ms => "00" & x"BB8", -- 3000ms
       max_time_ms => "00" & x"BB8",
       display_en => '1',
       seg => cd_seg, an => cd_an, led_r => led_o,
       time_ms_out => open, time_up => cd_time_up
   );

   Inst_Display: sSegDemo port map (
       clk_i => clk_100MHz, mode_i => demo_mode, score_i => current_score, hi_score_i => high_score,
       seg_o => demo_seg, an_o => demo_an
   );

   -- Multiplex display: use countdown display when playing, demo display otherwise
   disp_seg_o <= cd_seg when state = ST_USER_WAIT else demo_seg;
   disp_an_o <= cd_an when state = ST_USER_WAIT else demo_an;

end Behavioral;