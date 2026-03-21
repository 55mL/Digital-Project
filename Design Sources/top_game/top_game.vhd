library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_game is
    Port (
        clk_i   : in  STD_LOGIC;
        rstn_i  : in  STD_LOGIC;
        btnc_i  : in  STD_LOGIC;
        sw_i    : in  STD_LOGIC_VECTOR(15 downto 0);
        seg_o   : out STD_LOGIC_VECTOR(7 downto 0);
        an_o    : out STD_LOGIC_VECTOR(7 downto 0);
        led_o   : out STD_LOGIC_VECTOR(15 downto 0);
        led17_r : out STD_LOGIC;
        led17_g : out STD_LOGIC;
        led17_b : out STD_LOGIC;
        sclk    : out STD_LOGIC;
        mosi    : out STD_LOGIC;
        miso    : in  STD_LOGIC;
        ss      : out STD_LOGIC
    );
end top_game;

architecture Behavioral of top_game is

    component ClkGen
        port (
            clk_100MHz_i : in  std_logic;
            clk_100MHz_o : out std_logic;
            clk_200MHz_o : out std_logic;
            reset_i      : in  std_logic;
            locked_o     : out std_logic
        );
    end component;

    component AccelerometerCtl
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
            ACCEL_X_OUT   : out STD_LOGIC_VECTOR(8 downto 0);
            ACCEL_Y_OUT   : out STD_LOGIC_VECTOR(8 downto 0);
            ACCEL_MAG_OUT : out STD_LOGIC_VECTOR(11 downto 0);
            ACCEL_TMP_OUT : out STD_LOGIC_VECTOR(11 downto 0)
        );
    end component;

    component RandomColor
        port (
            clk        : in  STD_LOGIC;
            btn_random : in  STD_LOGIC;
            led17_r    : out STD_LOGIC;
            led17_g    : out STD_LOGIC;
            led17_b    : out STD_LOGIC;
            color_out  : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    component countdown_7seg
        port (
            clk           : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            start         : in  STD_LOGIC;
            load_value_ms : in  STD_LOGIC_VECTOR(13 downto 0);
            max_time_ms   : in  STD_LOGIC_VECTOR(13 downto 0);
            display_en    : in  STD_LOGIC;
            x_val_in      : in  integer range 0 to 511;
            cond_ok_in    : in  STD_LOGIC;
            seg           : out STD_LOGIC_VECTOR(7 downto 0);
            an            : out STD_LOGIC_VECTOR(7 downto 0);
            led_r         : out STD_LOGIC_VECTOR(15 downto 0);
            time_ms_out   : out STD_LOGIC_VECTOR(13 downto 0);
            time_up       : out STD_LOGIC
        );
    end component;

    component btn_edge_detect
        port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            btn_in    : in  STD_LOGIC;
            btn_pulse : out STD_LOGIC
        );
    end component;

    component cond_checker
        port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            active      : in  STD_LOGIC;
            color_latch : in  STD_LOGIC_VECTOR(1 downto 0);
            x_val       : in  integer range 0 to 511;
            sw_in       : in  STD_LOGIC_VECTOR(15 downto 0);
            cond_ok     : out STD_LOGIC;
            hold_pass   : out STD_LOGIC
        );
    end component;

    component text_display
        port (
            clk        : in  STD_LOGIC;
            game_state : in  STD_LOGIC_VECTOR(3 downto 0);
            high_score : in  integer range 0 to 9999;
            score      : in  integer range 0 to 9999;
            seg_o      : out STD_LOGIC_VECTOR(7 downto 0);
            an_o       : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component seg_mux
        port (
            sel     : in  STD_LOGIC;
            cd_seg  : in  STD_LOGIC_VECTOR(7 downto 0);
            cd_an   : in  STD_LOGIC_VECTOR(7 downto 0);
            txt_seg : in  STD_LOGIC_VECTOR(7 downto 0);
            txt_an  : in  STD_LOGIC_VECTOR(7 downto 0);
            seg_o   : out STD_LOGIC_VECTOR(7 downto 0);
            an_o    : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component score_manager
        port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            inc_score   : in  STD_LOGIC;
            reset_score : in  STD_LOGIC;
            update_hs   : in  STD_LOGIC;
            score       : out integer range 0 to 9999;
            high_score  : out integer range 0 to 9999
        );
    end component;

    component difficulty_ctrl
        port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            decrease    : in  STD_LOGIC;
            reset_diff  : in  STD_LOGIC;
            time_val_ms : out integer range 1000 to 5000
        );
    end component;

    component game_fsm
        port (
            clk           : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            btn_pulse     : in  STD_LOGIC;
            hold_pass     : in  STD_LOGIC;
            cd_time_up    : in  STD_LOGIC;
            color_out     : in  STD_LOGIC_VECTOR(1 downto 0);
            x_val         : in  integer range 0 to 511;
            sw_i          : in  STD_LOGIC_VECTOR(15 downto 0);
            seg_sel       : out STD_LOGIC;
            cd_display    : out STD_LOGIC;
            cd_start      : out STD_LOGIC;
            ld17_en       : out STD_LOGIC;
            do_random     : out STD_LOGIC;
            color_latch   : out STD_LOGIC_VECTOR(1 downto 0);
            load_wait_cnt : out integer range 0 to 3;
            inc_score     : out STD_LOGIC;
            reset_score   : out STD_LOGIC;
            update_hs     : out STD_LOGIC;
            diff_dec      : out STD_LOGIC;
            diff_reset    : out STD_LOGIC;
            state_slv     : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal reset_sys    : std_logic;
    signal locked       : std_logic;

    signal accel_x      : STD_LOGIC_VECTOR(8 downto 0);
    signal accel_y      : STD_LOGIC_VECTOR(8 downto 0);
    signal accel_mag    : STD_LOGIC_VECTOR(11 downto 0);
    signal accel_tmp    : STD_LOGIC_VECTOR(11 downto 0);
    signal x_val        : integer range 0 to 511;

    signal color_out    : STD_LOGIC_VECTOR(1 downto 0);
    signal color_latch  : STD_LOGIC_VECTOR(1 downto 0);
    signal rc_r, rc_g, rc_b : STD_LOGIC;

    signal cd_start     : STD_LOGIC;
    signal cd_load_ms   : STD_LOGIC_VECTOR(13 downto 0);
    signal cd_max_ms    : STD_LOGIC_VECTOR(13 downto 0);
    signal cd_display   : STD_LOGIC;
    signal cd_seg       : STD_LOGIC_VECTOR(7 downto 0);
    signal cd_an        : STD_LOGIC_VECTOR(7 downto 0);
    signal cd_led       : STD_LOGIC_VECTOR(15 downto 0);
    signal cd_time_ms   : STD_LOGIC_VECTOR(13 downto 0);
    signal cd_time_up   : STD_LOGIC;

    signal cd_time_val  : integer range 1000 to 5000;
    signal diff_dec     : STD_LOGIC;
    signal diff_reset   : STD_LOGIC;

    signal score        : integer range 0 to 9999;
    signal high_score   : integer range 0 to 9999;
    signal inc_score    : STD_LOGIC;
    signal reset_score  : STD_LOGIC;
    signal update_hs    : STD_LOGIC;

    signal btn_pulse    : STD_LOGIC;
    signal cond_ok      : STD_LOGIC;
    signal hold_pass    : STD_LOGIC;
    signal cc_active    : STD_LOGIC;

    signal txt_seg      : STD_LOGIC_VECTOR(7 downto 0);
    signal txt_an       : STD_LOGIC_VECTOR(7 downto 0);
    signal seg_sel      : STD_LOGIC;

    signal ld17_en      : STD_LOGIC;
    signal do_random    : STD_LOGIC;
    signal state_slv    : STD_LOGIC_VECTOR(3 downto 0);
    signal load_wait_cnt : integer range 0 to 3;

begin

    rst       <= not rstn_i;
    reset_sys <= rst or (not locked);

    Inst_ClkGen : ClkGen
        port map (
            clk_100MHz_i => clk_i,
            clk_100MHz_o => clk,
            clk_200MHz_o => open,
            reset_i      => rst,
            locked_o     => locked
        );

    
    Inst_Accel : AccelerometerCtl
        generic map (
            SYSCLK_FREQUENCY_HZ => 100_000_000,
            SCLK_FREQUENCY_HZ   => 100_000,
            NUM_READS_AVG       => 16,
            UPDATE_FREQUENCY_HZ => 1000
        )
        port map (
            SYSCLK        => clk,
            RESET         => reset_sys,
            SCLK          => sclk,
            MOSI          => mosi,
            MISO          => miso,
            SS            => ss,
            ACCEL_X_OUT   => accel_x,
            ACCEL_Y_OUT   => accel_y,
            ACCEL_MAG_OUT => accel_mag,
            ACCEL_TMP_OUT => accel_tmp
        );

    x_val <= to_integer(unsigned(accel_x));

  
    Inst_RC : RandomColor
        port map (
            clk        => clk,
            btn_random => do_random,
            led17_r    => rc_r,
            led17_g    => rc_g,
            led17_b    => rc_b,
            color_out  => color_out
        );

    led17_r <= rc_r when ld17_en = '1' else '0';
    led17_g <= rc_g when ld17_en = '1' else '0';
    led17_b <= rc_b when ld17_en = '1' else '0';

    cd_load_ms <= std_logic_vector(to_unsigned(cd_time_val, 14));
    cd_max_ms  <= std_logic_vector(to_unsigned(cd_time_val, 14));

    Inst_CD : countdown_7seg
        port map (
            clk           => clk,
            reset         => reset_sys,
            start         => cd_start,
            load_value_ms => cd_load_ms,
            max_time_ms   => cd_max_ms,
            display_en    => cd_display,
            x_val_in      => x_val,
            cond_ok_in    => cond_ok,
            seg           => cd_seg,
            an            => cd_an,
            led_r         => cd_led,
            time_ms_out   => cd_time_ms,
            time_up       => cd_time_up
        );

    led_o <= cd_led;

    Inst_BTN : btn_edge_detect
        port map (
            clk       => clk,
            reset     => reset_sys,
            btn_in    => btnc_i,
            btn_pulse => btn_pulse
        );

    cc_active <= '1' when state_slv = "0100" else '0';

    Inst_CC : cond_checker
        port map (
            clk         => clk,
            reset       => reset_sys,
            active      => cc_active,
            color_latch => color_latch,
            x_val       => x_val,
            sw_in       => sw_i,
            cond_ok     => cond_ok,
            hold_pass   => hold_pass
        );

    Inst_DIFF : difficulty_ctrl
        port map (
            clk         => clk,
            reset       => reset_sys,
            decrease    => diff_dec,
            reset_diff  => diff_reset,
            time_val_ms => cd_time_val
        );

    Inst_SCORE : score_manager
        port map (
            clk         => clk,
            reset       => reset_sys,
            inc_score   => inc_score,
            reset_score => reset_score,
            update_hs   => update_hs,
            score       => score,
            high_score  => high_score
        );

    Inst_TXT : text_display
        port map (
            clk        => clk,
            game_state => state_slv,
            high_score => high_score,
            score      => score,
            seg_o      => txt_seg,
            an_o       => txt_an
        );

    Inst_MUX : seg_mux
        port map (
            sel     => seg_sel,
            cd_seg  => cd_seg,
            cd_an   => cd_an,
            txt_seg => txt_seg,
            txt_an  => txt_an,
            seg_o   => seg_o,
            an_o    => an_o
        );

    Inst_FSM : game_fsm
        port map (
            clk           => clk,
            reset         => reset_sys,
            btn_pulse     => btn_pulse,
            hold_pass     => hold_pass,
            cd_time_up    => cd_time_up,
            color_out     => color_out,
            x_val         => x_val,
            sw_i          => sw_i,
            seg_sel       => seg_sel,
            cd_display    => cd_display,
            cd_start      => cd_start,
            ld17_en       => ld17_en,
            do_random     => do_random,
            color_latch   => color_latch,
            load_wait_cnt => load_wait_cnt,
            inc_score     => inc_score,
            reset_score   => reset_score,
            update_hs     => update_hs,
            diff_dec      => diff_dec,
            diff_reset    => diff_reset,
            state_slv     => state_slv
        );

end Behavioral;