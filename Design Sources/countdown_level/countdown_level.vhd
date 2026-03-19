library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity countdown_level is
    Port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        start : in  STD_LOGIC;

        seg   : out STD_LOGIC_VECTOR(7 downto 0);
        an    : out STD_LOGIC_VECTOR(7 downto 0);
        led_r : out STD_LOGIC_VECTOR(15 downto 0)
    );
end countdown_level;

architecture Behavioral of countdown_level is

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

    constant START_MS : integer := 3000;
    constant BONUS_MS : integer := 500;
    constant MAX_MS   : integer := 9990;

    -- ชั่วคราว: ใช้กำหนดผลตัดสินจำลอง
    constant DEBUG_JUDGE_PASS : STD_LOGIC := '1';
    constant DEBUG_JUDGE_FAIL : STD_LOGIC := '0';

    signal start_prev     : STD_LOGIC := '0';
    signal start_pulse    : STD_LOGIC := '0';

    signal cd_start       : STD_LOGIC := '0';
    signal cd_load_value  : STD_LOGIC_VECTOR(13 downto 0) := std_logic_vector(to_unsigned(START_MS, 14));
    signal cd_max_time    : STD_LOGIC_VECTOR(13 downto 0) := std_logic_vector(to_unsigned(START_MS, 14));

    signal cd_time_ms_out : STD_LOGIC_VECTOR(13 downto 0);
    signal cd_time_up     : STD_LOGIC;

    signal game_started   : STD_LOGIC := '0';
    signal level_base_ms  : integer range 0 to MAX_MS := START_MS;

    -- signal กลางสำหรับรับผลจาก component อื่นในอนาคต
    signal judge_valid    : STD_LOGIC := '0';
    signal judge_pass     : STD_LOGIC := '0';
    signal judge_fail     : STD_LOGIC := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                start_prev  <= '0';
                start_pulse <= '0';
            else
                start_pulse <= start and (not start_prev);
                start_prev  <= start;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- ชั่วคราว: จำลองผลจาก component อื่น
    -- ใช้ปุ่ม start หลังเริ่มเกมแล้ว เป็นตัว trigger ผลตัดสิน 1 clock
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                judge_valid <= '0';
                judge_pass  <= '0';
                judge_fail  <= '0';
            else
                judge_valid <= '0';
                judge_pass  <= '0';
                judge_fail  <= '0';

                if start_pulse = '1' and game_started = '1' and cd_time_up = '0' then
                    judge_valid <= '1';
                    judge_pass  <= DEBUG_JUDGE_PASS;
                    judge_fail  <= DEBUG_JUDGE_FAIL;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- main level logic
    ----------------------------------------------------------------
    process(clk)
        variable next_base : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cd_start      <= '0';
                game_started  <= '0';
                level_base_ms <= START_MS;
                cd_load_value <= std_logic_vector(to_unsigned(START_MS, 14));
                cd_max_time   <= std_logic_vector(to_unsigned(START_MS, 14));
            else
                cd_start <= '0';

                -- start game ครั้งแรก / เริ่มใหม่หลัง time up
                if start_pulse = '1' and ((game_started = '0') or (cd_time_up = '1')) then
                    level_base_ms <= START_MS;
                    cd_load_value <= std_logic_vector(to_unsigned(START_MS, 14));
                    cd_max_time   <= std_logic_vector(to_unsigned(START_MS, 14));
                    cd_start      <= '1';
                    game_started  <= '1';

                -- get pass or fail from other component
                elsif judge_valid = '1' then
                    if judge_pass = '1' and judge_fail = '0' then
                        next_base := level_base_ms + BONUS_MS;

                        if next_base > MAX_MS then
                            next_base := MAX_MS;
                        end if;

                        level_base_ms <= next_base;
                        cd_load_value <= std_logic_vector(to_unsigned(next_base, 14));
                        cd_max_time   <= std_logic_vector(to_unsigned(next_base, 14));
                        cd_start      <= '1';

                    elsif judge_fail = '1' and judge_pass = '0' then
                        game_started  <= '0';
                        level_base_ms <= START_MS;
                        cd_load_value <= std_logic_vector(to_unsigned(START_MS, 14));
                        cd_max_time   <= std_logic_vector(to_unsigned(START_MS, 14));
                    end if;
                end if;
            end if;
        end if;
    end process;

    U_COUNTDOWN : countdown_7seg
        port map (
            clk           => clk,
            reset         => reset,
            start         => cd_start,
            load_value_ms => cd_load_value,
            max_time_ms   => cd_max_time,
            display_en    => game_started,

            seg           => seg,
            an            => an,
            led_r         => led_r,

            time_ms_out   => cd_time_ms_out,
            time_up       => cd_time_up
        );

end Behavioral;