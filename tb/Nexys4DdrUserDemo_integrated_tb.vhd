library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Nexys4DdrUserDemo_integrated_tb is
end Nexys4DdrUserDemo_integrated_tb;

architecture behavioral of Nexys4DdrUserDemo_integrated_tb is

    component Nexys4DdrUserDemo
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
    end component;

    signal clk_tb          : std_logic := '0';
    signal rstn_tb         : std_logic := '0';
    signal sw_tb           : std_logic_vector(15 downto 0) := (others => '0');
    signal btnc_tb         : std_logic := '0';
    signal led_o_tb        : std_logic_vector(15 downto 0);
    signal led17_r_tb      : std_logic;
    signal led17_g_tb      : std_logic;
    signal led17_b_tb      : std_logic;
    signal disp_seg_o_tb   : std_logic_vector(7 downto 0);
    signal disp_an_o_tb    : std_logic_vector(7 downto 0);
    
    constant clk_period : time := 10 ns;

begin

    UUT: Nexys4DdrUserDemo
    port map (
        clk_i => clk_tb, rstn_i => rstn_tb, sw_i => sw_tb, btnc_i => btnc_tb,
        led_o => led_o_tb, led17_r => led17_r_tb, led17_g => led17_g_tb, led17_b => led17_b_tb,
        disp_seg_o => disp_seg_o_tb, disp_an_o => disp_an_o_tb,
        sclk => open, mosi => open, miso => '0', ss => open
    );

    clk_process : process
    begin
        clk_tb <= '0'; wait for clk_period/2;
        clk_tb <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
    begin		
        -- Initial Reset
        rstn_tb <= '0';
        wait for 100 ns;
        rstn_tb <= '1';
        wait for 1 us;

        -- 1. Start Game
        btnc_tb <= '1'; wait for 100 ns; btnc_tb <= '0';
        
        -- 2. Wait for Sequence to be shown (ST_SHOW_SEQ)
        -- In simulation, we reduced SHOW_TIME to 1000 cycles (10us)
        wait for 50 us; 
        
        -- 3. Now in ST_USER_WAIT, the countdown should be visible
        wait for 100 us;
        
        -- The logic currently auto-passes for testing
        -- Wait for the next level (2 colors)
        wait for 100 us; 
        
        -- 4. Let's wait until it should be in ST_GAMEOVER (if countdown ends)
        -- Note: The current simplified top auto-transitions from USER_WAIT to CHECK to PASS.
        -- To test High Score, we can trigger a manual reset or similar if logic allowed.
        
        wait for 1 ms;

        report "Integrated Simulation Completed";
        wait;
    end process;

end behavioral;