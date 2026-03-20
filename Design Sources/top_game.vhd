library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =============================================================================
-- top_game.vhd
-- Top-level entity สำหรับเกมเหยียบเบรคตามสัญญาณไฟจราจร
--
-- Flow:
--  1. 7-seg แสดง "PRESS"  → รอกด BTNC (N17)
--  2. 7-seg แสดง "START"
--  3. สุ่มไฟ (RandomColor) → แสดงบน LD17
--  4. 7-seg นับถอยหลัง + LED[0-15] ถอยหลังตาม
--  5. ตรวจเงื่อนไข (accelerometer + switch) ค้าง 1 วินาที
--       เขียว  : accel_x 370-398, sw[15]='1'
--       เหลือง : accel_x 370-398, sw[0]='1'
--       แดง    : accel_x 241-270, sw[15]='1' AND sw[0]='1'
--  6. ถูก → PASS → +score → เพิ่มความยาก → loop กลับข้อ 3
--     ผิด / หมดเวลา → FAIL → แสดง HIGH SCORE → กลับข้อ 1 (PRESS)
-- =============================================================================

entity top_game is
    Port (
        -- Board clock & reset
        clk_i       : in  STD_LOGIC;                       -- E3  100 MHz
        rstn_i      : in  STD_LOGIC;                       -- C12 CPU_RESETN (active-low)

        -- Buttons
        btnc_i      : in  STD_LOGIC;                       -- N17 BTNC (start / random)

        -- Switches
        sw_i        : in  STD_LOGIC_VECTOR(15 downto 0);  -- J15..V10

        -- 7-segment display
        seg_o       : out STD_LOGIC_VECTOR(7 downto 0);   -- cathodes + DP
        an_o        : out STD_LOGIC_VECTOR(7 downto 0);   -- anodes (active-low)

        -- User LEDs (countdown bar)
        led_o       : out STD_LOGIC_VECTOR(15 downto 0);

        -- RGB LED LD17 (traffic light)
        led17_r     : out STD_LOGIC;
        led17_g     : out STD_LOGIC;
        led17_b     : out STD_LOGIC;

        -- SPI Accelerometer
        sclk        : out STD_LOGIC;
        mosi        : out STD_LOGIC;
        miso        : in  STD_LOGIC;
        ss          : out STD_LOGIC
    );
end top_game;

architecture Behavioral of top_game is

    -- =========================================================================
    -- Component Declarations
    -- =========================================================================

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

    -- =========================================================================
    -- Game FSM States
    -- =========================================================================
    type game_state_t is (
        ST_PRESS,       -- แสดง PRESS รอกดปุ่ม
        ST_START,       -- แสดง START (1 วินาที)
        ST_RANDOM,      -- สุ่มสีและแสดง LD17 (brief pulse เพื่อ latch สี)
        ST_LOAD_CD,     -- โหลด countdown แล้วรอ time_up='0' ก่อนเริ่มนับ
        ST_COUNTDOWN,   -- นับถอยหลัง + ตรวจเงื่อนไข
        ST_PASS,        -- แสดง PASS (1 วินาที)
        ST_WAIT_VERT,   -- รอตั้งบอร์ดแนวตั้งก่อนเริ่มด่านใหม่
        ST_FAIL,        -- แสดง FAIL (1 วินาที)
        ST_HIGHSCORE    -- แสดง High Score แล้วกลับ PRESS
    );

    -- =========================================================================
    -- Internal Signals
    -- =========================================================================

    -- Clock / Reset
    signal clk          : std_logic;
    signal rst          : std_logic;   -- active-high internal reset
    signal reset_sys    : std_logic;
    signal locked       : std_logic;

    -- Accelerometer
    signal accel_x      : STD_LOGIC_VECTOR(8 downto 0);
    signal accel_y      : STD_LOGIC_VECTOR(8 downto 0);
    signal accel_mag    : STD_LOGIC_VECTOR(11 downto 0);
    signal accel_tmp    : STD_LOGIC_VECTOR(11 downto 0);
    signal x_val        : integer range 0 to 511;

    -- Random Color
    signal color_out    : STD_LOGIC_VECTOR(1 downto 0);
    signal color_latch  : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal rc_r, rc_g, rc_b : STD_LOGIC;

    -- Countdown
    signal cd_start     : STD_LOGIC := '0';
    signal cd_load_ms   : STD_LOGIC_VECTOR(13 downto 0);
    signal cd_max_ms    : STD_LOGIC_VECTOR(13 downto 0);
    signal cd_display   : STD_LOGIC := '0';
    signal cd_seg       : STD_LOGIC_VECTOR(7 downto 0);
    signal cd_an        : STD_LOGIC_VECTOR(7 downto 0);
    signal cd_led       : STD_LOGIC_VECTOR(15 downto 0);
    signal cd_time_ms   : STD_LOGIC_VECTOR(13 downto 0);
    signal cd_time_up   : STD_LOGIC;

    -- Countdown timing parameters
    constant CD_START_MS  : integer := 3000;   -- เวลาเริ่มต้น 3 วินาที
    constant CD_MIN_MS    : integer := 1000;   -- เวลาขั้นต่ำ 1 วินาที
    constant CD_DEC_MS    : integer := 200;    -- ลดทีละ 200 ms ต่อรอบ
    signal   cd_time_val  : integer range CD_MIN_MS to CD_START_MS := CD_START_MS;

    -- Score
    signal score        : integer range 0 to 9999 := 0;
    signal high_score   : integer range 0 to 9999 := 0;

    -- FSM
    signal game_state   : game_state_t := ST_PRESS;

    -- Button debounce / edge detect for BTNC
    signal btn_prev     : STD_LOGIC := '0';
    signal btn_pulse    : STD_LOGIC := '0';

    -- General-purpose 1-second delay counter (100 MHz → 100_000_000 ticks)
    constant ONE_SEC    : integer := 100_000_000;
    signal delay_cnt    : integer range 0 to ONE_SEC := 0;
    signal delay_done   : STD_LOGIC := '0';

    -- Hold counter สำหรับตรวจเงื่อนไขค้าง 1 วินาที
    signal hold_cnt     : integer range 0 to ONE_SEC := 0;
    signal cond_ok      : STD_LOGIC := '0';   -- เงื่อนไขถูกต้องในขณะนั้น
    signal hold_pass    : STD_LOGIC := '0';   -- ค้างครบ 1 วินาที → pass

    -- 7-seg mux output selector
    -- "00" = countdown module, "01" = text (PRESS/START/PASS/FAIL/HIGHSCORE)
    signal seg_sel      : STD_LOGIC := '0';

    -- Text 7-seg (multiplexed internally)
    signal txt_seg      : STD_LOGIC_VECTOR(7 downto 0);
    signal txt_an       : STD_LOGIC_VECTOR(7 downto 0);

    -- Refresh counter for text display multiplexing
    signal refresh_cnt  : unsigned(19 downto 0) := (others => '0');
    signal digit_sel    : unsigned(2 downto 0);

    -- High score display digits
    signal hs_d0, hs_d1, hs_d2, hs_d3 : integer range 0 to 9;

    -- LD17 output (gated by FSM)
    signal ld17_en      : STD_LOGIC := '0';  -- เปิด LD17 เฉพาะตอน countdown

    -- RandomColor latch pulse
    signal do_random    : STD_LOGIC := '0';

    -- Load countdown step counter (รอ 2 รอบหลัง cd_start เพื่อให้ time_ms โหลดจริง)
    signal load_wait_cnt : integer range 0 to 3 := 0;

    -- =========================================================================
    -- Helper: encode digit to 7-seg cathode (active-low, no DP)
    -- =========================================================================
    function digit_to_seg(d : integer range 0 to 9) return std_logic_vector is
    begin
        case d is
            when 0 => return "11000000"; -- 0  (bit7=DP off)
            when 1 => return "11111001"; -- 1
            when 2 => return "10100100"; -- 2
            when 3 => return "10110000"; -- 3
            when 4 => return "10011001"; -- 4
            when 5 => return "10010010"; -- 5
            when 6 => return "10000010"; -- 6
            when 7 => return "11111000"; -- 7
            when 8 => return "10000000"; -- 8
            when 9 => return "10010000"; -- 9
            when others => return "11111111";
        end case;
    end function;

begin

    -- =========================================================================
    -- Clock & Reset
    -- =========================================================================
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

    -- =========================================================================
    -- Accelerometer
    -- =========================================================================
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

    -- =========================================================================
    -- Random Color (ใช้ btn_random = do_random pulse เพื่อ latch ตอนเข้า ST_RANDOM)
    -- =========================================================================
    Inst_RC : RandomColor
        port map (
            clk        => clk,
            btn_random => do_random,
            led17_r    => rc_r,
            led17_g    => rc_g,
            led17_b    => rc_b,
            color_out  => color_out
        );

    -- Gate LD17 output: แสดงเฉพาะตอนนับถอยหลัง
    led17_r <= rc_r when ld17_en = '1' else '0';
    led17_g <= rc_g when ld17_en = '1' else '0';
    led17_b <= rc_b when ld17_en = '1' else '0';

    -- =========================================================================
    -- Countdown 7-seg + LED bar
    -- =========================================================================
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

    cd_load_ms <= std_logic_vector(to_unsigned(cd_time_val, 14));
    cd_max_ms  <= std_logic_vector(to_unsigned(cd_time_val, 14));

    -- LED bar output
    led_o <= cd_led;

    -- =========================================================================
    -- 7-seg Output MUX
    -- =========================================================================
    seg_o <= cd_seg  when seg_sel = '0' else txt_seg;
    an_o  <= cd_an   when seg_sel = '0' else txt_an;

    -- =========================================================================
    -- Refresh counter for text multiplexing
    -- =========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;
    digit_sel <= refresh_cnt(19 downto 17);

    -- =========================================================================
    -- High score digits
    -- =========================================================================
    hs_d0 <= high_score mod 10;
    hs_d1 <= (high_score / 10) mod 10;
    hs_d2 <= (high_score / 100) mod 10;
    hs_d3 <= (high_score / 1000) mod 10;

    -- =========================================================================
    -- Text 7-seg process  (PRESS / START / PASS / FAIL / HIGH SCORE)
    -- seg bit7 = DP (active-low), seg[6:0] = a..g
    -- patterns ตรงกับ Press.vhd เดิม (7 บิต active-low, DP=1 ปิด)
    -- =========================================================================
    process(digit_sel, game_state, hs_d0, hs_d1, hs_d2, hs_d3)
    begin
        txt_seg <= "11111111";
        txt_an  <= "11111111";

        case game_state is

            -- ------------------------------------------------------------------
            -- PRESS  ตรงกับ Press.vhd เดิมทุกบิต
            -- digits: 4=P, 3=r, 2=E, 1=S, 0=S
            -- ------------------------------------------------------------------
            when ST_PRESS =>
                case digit_sel is
                    when "100" =>           -- P  an=11101111
                        txt_an  <= "11101111";
                        txt_seg <= "1" & "0001100";  -- DP off + P
                    when "011" =>           -- r  an=11110111
                        txt_an  <= "11110111";
                        txt_seg <= "1" & "0101111";  -- DP off + r (ตรง Press.vhd)
                    when "010" =>           -- E  an=11111011
                        txt_an  <= "11111011";
                        txt_seg <= "1" & "0000110";  -- DP off + E
                    when "001" =>           -- S  an=11111101
                        txt_an  <= "11111101";
                        txt_seg <= "1" & "0010010";  -- DP off + S
                    when "000" =>           -- S  an=11111110
                        txt_an  <= "11111110";
                        txt_seg <= "1" & "0010010";  -- DP off + S
                    when others =>
                        txt_an  <= "11111111";
                        txt_seg <= "11111111";
                end case;

            -- ------------------------------------------------------------------
            -- START  ตรงกับ Press.vhd เดิม (show_start = '1')
            -- digits: 4=S, 3=T, 2=A, 1=r, 0=T
            -- ------------------------------------------------------------------
            when ST_START =>
                case digit_sel is
                    when "100" =>           -- S  an=11101111
                        txt_an  <= "11101111";
                        txt_seg <= "1" & "0010010";  -- DP off + S
                    when "011" =>           -- T  an=11110111
                        txt_an  <= "11110111";
                        txt_seg <= "1" & "0000111";  -- DP off + T
                    when "010" =>           -- A  an=11111011
                        txt_an  <= "11111011";
                        txt_seg <= "1" & "0001000";  -- DP off + A
                    when "001" =>           -- r  an=11111101 (ตรง Press.vhd seg="0101111")
                        txt_an  <= "11111101";
                        txt_seg <= "1" & "0101111";  -- DP off + r
                    when "000" =>           -- T  an=11111110
                        txt_an  <= "11111110";
                        txt_seg <= "1" & "0000111";  -- DP off + T
                    when others =>
                        txt_an  <= "11111111";
                        txt_seg <= "11111111";
                end case;

            -- ------------------------------------------------------------------
            -- PASS  (4 chars: P-A-S-S on digits 3-0)
            -- ------------------------------------------------------------------
            when ST_PASS =>
                case digit_sel is
                    when "011" =>           -- P
                        txt_an  <= "11110111";
                        txt_seg <= "10001100";
                    when "010" =>           -- A
                        txt_an  <= "11111011";
                        txt_seg <= "10001000";
                    when "001" =>           -- S
                        txt_an  <= "11111101";
                        txt_seg <= "10010010";
                    when "000" =>           -- S
                        txt_an  <= "11111110";
                        txt_seg <= "10010010";
                    when others =>
                        txt_an  <= "11111111";
                        txt_seg <= "11111111";
                end case;

            -- ------------------------------------------------------------------
            -- WAIT VERTICAL (UP)
            -- digits 3=U, 2=P
            -- ------------------------------------------------------------------
            when ST_WAIT_VERT =>
                case digit_sel is
                    when "011" =>           -- U
                        txt_an  <= "11110111";
                        txt_seg <= "11000001";
                    when "010" =>           -- P
                        txt_an  <= "11111011";
                        txt_seg <= "10001100";
                    when others =>
                        txt_an  <= "11111111";
                        txt_seg <= "11111111";
                end case;

            -- ------------------------------------------------------------------
            -- FAIL  (4 chars: F-A-I-L on digits 3-0)
            -- ------------------------------------------------------------------
            when ST_FAIL =>
                case digit_sel is
                    when "011" =>           -- F
                        txt_an  <= "11110111";
                        txt_seg <= "10001110";
                    when "010" =>           -- A
                        txt_an  <= "11111011";
                        txt_seg <= "10001000";
                    when "001" =>           -- I
                        txt_an  <= "11111101";
                        txt_seg <= "11111001";
                    when "000" =>           -- L
                        txt_an  <= "11111110";
                        txt_seg <= "11000111";
                    when others =>
                        txt_an  <= "11111111";
                        txt_seg <= "11111111";
                end case;

            -- ------------------------------------------------------------------
            -- HIGH SCORE  (H-I + 4-digit score)
            -- digits 7=H, 6=I, 5=blank, 4=blank, 3=d3, 2=d2, 1=d1, 0=d0
            -- ------------------------------------------------------------------
            when ST_HIGHSCORE =>
                case digit_sel is
                    when "111" =>           -- H
                        txt_an  <= "01111111";
                        txt_seg <= "10001001";
                    when "110" =>           -- I
                        txt_an  <= "10111111";
                        txt_seg <= "11111001";
                    when "101" | "100" =>   -- blank
                        txt_an  <= "11111111";
                        txt_seg <= "11111111";
                    when "011" =>           -- thousands
                        txt_an  <= "11110111";
                        txt_seg <= digit_to_seg(hs_d3);
                    when "010" =>           -- hundreds
                        txt_an  <= "11111011";
                        txt_seg <= digit_to_seg(hs_d2);
                    when "001" =>           -- tens
                        txt_an  <= "11111101";
                        txt_seg <= digit_to_seg(hs_d1);
                    when "000" =>           -- ones
                        txt_an  <= "11111110";
                        txt_seg <= digit_to_seg(hs_d0);
                    when others =>
                        txt_an  <= "11111111";
                        txt_seg <= "11111111";
                end case;

            when others =>
                txt_seg <= "11111111";
                txt_an  <= "11111111";
        end case;
    end process;

    -- =========================================================================
    -- Button edge detector (BTNC)
    -- =========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_sys = '1' then
                btn_prev  <= '0';
                btn_pulse <= '0';
            else
                btn_pulse <= btnc_i and (not btn_prev);
                btn_prev  <= btnc_i;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Condition checker: เงื่อนไขถูกต้อง ณ ขณะนั้น
    -- =========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            cond_ok <= '0';
            if game_state = ST_COUNTDOWN then
                case color_latch is
                    when "01" =>   -- เขียว: x 370-398, sw[15]='1'
                        if (x_val >= 370 and x_val <= 398) and sw_i(15) = '1' then
                            cond_ok <= '1';
                        end if;
                    when "10" =>   -- เหลือง: x 370-398, sw[0]='1'
                        if (x_val >= 370 and x_val <= 398) and sw_i(0) = '1' then
                            cond_ok <= '1';
                        end if;
                    when "11" =>   -- แดง: x 241-270, sw[15]='1' AND sw[0]='1'
                        if (x_val >= 241 and x_val <= 270) and sw_i(15) = '1' and sw_i(0) = '1' then
                            cond_ok <= '1';
                        end if;
                    when others =>
                        cond_ok <= '0';
                end case;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Hold counter: ค้างเงื่อนไขถูกต้องครบ 1 วินาที
    -- =========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            hold_pass <= '0';
            if game_state = ST_COUNTDOWN then
                if cond_ok = '1' then
                    if hold_cnt >= (ONE_SEC / 2) - 1 then
                        hold_cnt  <= 0;
                        hold_pass <= '1';
                    else
                        hold_cnt <= hold_cnt + 1;
                    end if;
                else
                    hold_cnt <= 0;   -- reset ถ้าเงื่อนไขหลุด
                end if;
            else
                hold_cnt  <= 0;
                hold_pass <= '0';
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Main Game FSM
    -- =========================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_sys = '1' then
                game_state  <= ST_PRESS;
                score       <= 0;
                high_score  <= 0;
                cd_time_val <= CD_START_MS;
                seg_sel     <= '1';
                cd_display  <= '0';
                cd_start    <= '0';
                ld17_en     <= '0';
                do_random   <= '0';
                delay_cnt   <= 0;
                delay_done  <= '0';
                color_latch <= "00";
                load_wait_cnt <= 0;
            else
                -- default pulses
                cd_start  <= '0';
                do_random <= '0';
                delay_done <= '0';

                case game_state is

                    -- ----------------------------------------------------------
                    -- ST_PRESS : แสดง PRESS รอกด BTNC
                    -- ----------------------------------------------------------
                    when ST_PRESS =>
                        seg_sel    <= '1';   -- text
                        cd_display <= '0';
                        ld17_en    <= '0';
                        score      <= 0;
                        cd_time_val <= CD_START_MS;

                        if btn_pulse = '1' then
                            game_state <= ST_START;
                            delay_cnt  <= 0;
                        end if;

                    -- ----------------------------------------------------------
                    -- ST_START : แสดง START 1 วินาที
                    -- ----------------------------------------------------------
                    when ST_START =>
                        seg_sel <= '1';   -- text

                        if delay_cnt >= ONE_SEC - 1 then
                            delay_cnt  <= 0;
                            game_state <= ST_RANDOM;
                            do_random  <= '1';   -- latch สีใหม่
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    -- ----------------------------------------------------------
                    -- ST_RANDOM : pulse do_random แล้วรอ 1 วินาทีให้เห็น LD17
                    -- ----------------------------------------------------------
                    when ST_RANDOM =>
                        seg_sel <= '1';   -- text (แสดง blank หรือ ready)
                        ld17_en <= '1';   -- เปิด LD17 แสดงสี

                        -- latch color จาก RandomColor
                        if color_out /= "00" then
                            color_latch <= color_out;
                        end if;

                        if delay_cnt >= ONE_SEC - 1 then
                            delay_cnt  <= 0;
                            -- ส่ง cd_start pulse แล้วไป ST_LOAD_CD รอ countdown โหลด
                            cd_start      <= '1';
                            cd_display    <= '1';
                            seg_sel       <= '0';   -- countdown display
                            load_wait_cnt <= 0;
                            game_state    <= ST_LOAD_CD;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    -- ----------------------------------------------------------
                    -- ST_LOAD_CD : โหลด countdown แล้วรอให้ time_up='0'
                    --   cd_start ถูก pulse ใน ST_RANDOM → countdown โหลด time_ms
                    --   รอ 3 รอบเพื่อให้ time_ms propagate แน่นอน
                    -- ----------------------------------------------------------
                    when ST_LOAD_CD =>
                        seg_sel    <= '0';   -- countdown display
                        ld17_en    <= '1';   -- ยังแสดงสีอยู่
                        cd_display <= '1';

                        if load_wait_cnt < 3 then
                            load_wait_cnt <= load_wait_cnt + 1;
                        else
                            -- time_ms ต้องโหลดเรียบร้อยแล้ว ที่นี้ time_up='0'
                            game_state <= ST_COUNTDOWN;
                        end if;

                    -- ----------------------------------------------------------
                    -- ST_COUNTDOWN : นับถอยหลัง ตรวจเงื่อนไข
                    -- ----------------------------------------------------------
                    when ST_COUNTDOWN =>
                        seg_sel <= '0';   -- countdown
                        ld17_en <= '1';   -- ยังแสดงสีอยู่

                        if hold_pass = '1' then
                            -- ทำถูกและค้างครบ 1 วินาที
                            cd_display <= '0';
                            ld17_en    <= '0';
                            game_state <= ST_PASS;
                            delay_cnt  <= 0;

                        elsif cd_time_up = '1' then
                            -- หมดเวลา
                            cd_display <= '0';
                            ld17_en    <= '0';
                            if score > high_score then
                                high_score <= score;
                            end if;
                            game_state <= ST_FAIL;
                            delay_cnt  <= 0;
                        end if;

                    -- ----------------------------------------------------------
                    -- ST_PASS : แสดง PASS 1 วินาที → เพิ่ม score และความยาก
                    -- ----------------------------------------------------------
                    when ST_PASS =>
                        seg_sel <= '1';   -- text

                        if delay_cnt >= ONE_SEC - 1 then
                            delay_cnt <= 0;
                            -- เพิ่ม score
                            score <= score + 1;
                            -- เพิ่มความยาก: ลด countdown
                            if cd_time_val - CD_DEC_MS >= CD_MIN_MS then
                                cd_time_val <= cd_time_val - CD_DEC_MS;
                            else
                                cd_time_val <= CD_MIN_MS;
                            end if;
                            game_state <= ST_WAIT_VERT;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    -- ----------------------------------------------------------
                    -- ST_WAIT_VERT : บังคับตั้งบอร์ดแนวตั้งก่อนเริ่มด่านใหม่
                    -- ----------------------------------------------------------
                    when ST_WAIT_VERT =>
                        seg_sel <= '1';   -- text (แสดง UP)

                        -- แนวตั้ง: x_val ปลายขึ้น (+1g, ~384) หรือปลายลง (-1g, ~128)
                        if (x_val >= 350 and x_val <= 420) or (x_val >= 90 and x_val <= 160) then
                            do_random  <= '1';
                            game_state <= ST_RANDOM;
                        end if;

                    -- ----------------------------------------------------------
                    -- ST_FAIL : แสดง FAIL 1 วินาที
                    -- ----------------------------------------------------------
                    when ST_FAIL =>
                        seg_sel <= '1';   -- text

                        if delay_cnt >= ONE_SEC - 1 then
                            delay_cnt  <= 0;
                            game_state <= ST_HIGHSCORE;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    -- ----------------------------------------------------------
                    -- ST_HIGHSCORE : แสดง High Score รอกด BTNC → กลับ PRESS
                    -- ----------------------------------------------------------
                    when ST_HIGHSCORE =>
                        seg_sel <= '1';   -- text (high score)
                        ld17_en <= '0';

                        if btn_pulse = '1' then
                            game_state <= ST_PRESS;
                        end if;

                    when others =>
                        game_state <= ST_PRESS;

                end case;
            end if;
        end if;
    end process;

end Behavioral;