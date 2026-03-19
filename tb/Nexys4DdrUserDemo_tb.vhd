library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Nexys4DdrUserDemo_tb is
end Nexys4DdrUserDemo_tb;

architecture behavioral of Nexys4DdrUserDemo_tb is

    -- Component Declaration
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

    -- Signals
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
    signal sclk_tb         : std_logic;
    signal mosi_tb         : std_logic;
    signal miso_tb         : std_logic := '0';
    signal ss_tb           : std_logic;

    -- Clock period
    constant clk_period : time := 10 ns; -- 100MHz

begin

    -- Instantiate Device Under Test (DUT)
    UUT: Nexys4DdrUserDemo
    port map (
        clk_i      => clk_tb,
        rstn_i     => rstn_tb,
        sw_i       => sw_tb,
        btnc_i     => btnc_tb,
        led_o      => led_o_tb,
        led17_r    => led17_r_tb,
        led17_g    => led17_g_tb,
        led17_b    => led17_b_tb,
        disp_seg_o => disp_seg_o_tb,
        disp_an_o  => disp_an_o_tb,
        sclk       => sclk_tb,
        mosi       => mosi_tb,
        miso       => miso_tb,
        ss         => ss_tb
    );

    -- Clock process
    clk_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for clk_period/2;
            clk_tb <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        -- Initial Reset
        rstn_tb <= '0';
        wait for 100 ns;
        rstn_tb <= '1';
        wait for 100 ns;

        -- Test Case 1: Trigger a Random Color
        -- Wait some time to let fast_counter in RandomColor advance
        wait for 500 ns;
        btnc_tb <= '1';
        wait for 100 ns;
        btnc_tb <= '0';
        wait for 100 ns;
        
        -- After pressing btnc, a color is picked. 
        -- Based on RandomColor logic, since we haven't waited long, 
        -- it's likely Green or Yellow/Red depending on counter.
        
        -- Test Case 2: Apply Switch Settings
        -- Let's try to pass for Green (SW15=1, SW0=0)
        sw_tb(15) <= '1';
        sw_tb(0)  <= '0';
        wait for 1 us;
        
        -- Test Case 3: Apply Switch Settings for Red (SW15=1, SW0=1)
        sw_tb(15) <= '1';
        sw_tb(0)  <= '1';
        wait for 1 us;

        -- Wait for more time to observe 7-segment display multiplexing
        wait for 10 ms;

        -- End of Simulation
        report "Simulation Completed";
        wait;
    end process;

end behavioral;