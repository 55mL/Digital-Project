library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity countdown_7seg is
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
end countdown_7seg;

architecture Behavioral of countdown_7seg is

    component clock_divider is
        Port (
            clk           : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            tick_out_1hz  : out STD_LOGIC;
            tick_out_1khz : out STD_LOGIC
        );
    end component;

    component bin_to_7seg is
        Port (
            bin : in  STD_LOGIC_VECTOR(3 downto 0);
            seg : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    constant MAX_MS_LIMIT : integer := 9999;

    signal tick_1hz   : STD_LOGIC;
    signal tick_1khz  : STD_LOGIC;

    signal time_ms    : integer range 0 to MAX_MS_LIMIT := 0;
    signal seconds    : integer range 0 to 9 := 0;

    signal tens_digit : integer range 0 to 9;
    signal ones_digit : integer range 0 to 9;

    signal tens_bin   : STD_LOGIC_VECTOR(3 downto 0);
    signal ones_bin   : STD_LOGIC_VECTOR(3 downto 0);

    signal bin        : STD_LOGIC_VECTOR(3 downto 0);
    signal digit_idx  : integer range 0 to 7 := 0;

    signal led_count  : integer range 0 to 16 := 16;
    signal max_time_i : integer range 1 to MAX_MS_LIMIT := 1;

    signal pwm_cnt    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal led_r_int  : STD_LOGIC_VECTOR(15 downto 0);

    signal seg7       : STD_LOGIC_VECTOR(6 downto 0);
    signal dp_bit     : STD_LOGIC := '0';

    signal ms_two     : integer range 0 to 99 := 0;
    signal ms_tens    : integer range 0 to 9 := 0;
    signal ms_ones    : integer range 0 to 9 := 0;

begin

    U_CLK_DIV : clock_divider
        port map (
            clk           => clk,
            reset         => reset,
            tick_out_1hz  => tick_1hz,
            tick_out_1khz => tick_1khz
        );

    process(max_time_ms)
        variable tmp : integer;
    begin
        tmp := to_integer(unsigned(max_time_ms));

        if tmp < 1 then
            max_time_i <= 1;
        elsif tmp > MAX_MS_LIMIT then
            max_time_i <= MAX_MS_LIMIT;
        else
            max_time_i <= tmp;
        end if;
    end process;

    process(clk)
        variable load_int : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                time_ms <= 0;
            elsif start = '1' then
                load_int := to_integer(unsigned(load_value_ms));
                if load_int > MAX_MS_LIMIT then
                    time_ms <= MAX_MS_LIMIT;
                else
                    time_ms <= load_int;
                end if;
            elsif tick_1khz = '1' then
                if time_ms > 0 then
                    time_ms <= time_ms - 1;
                else
                    time_ms <= 0;
                end if;
            end if;
        end if;
    end process;

    process(time_ms)
    begin
        if time_ms = 0 then
            seconds <= 0;
        else
            seconds <= (time_ms - 1) / 1000 + 1;
        end if;
    end process;

    tens_digit <= seconds / 10;
    ones_digit <= seconds mod 10;

    tens_bin <= std_logic_vector(to_unsigned(tens_digit, 4));
    ones_bin <= std_logic_vector(to_unsigned(ones_digit, 4));

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                digit_idx <= 0;
            elsif tick_1khz = '1' then
                if digit_idx = 7 then
                    digit_idx <= 0;
                else
                    digit_idx <= digit_idx + 1;
                end if;
            end if;
        end if;
    end process;

    process(time_ms)
    begin
        ms_two  <= (time_ms mod 1000) / 10;
        ms_tens <= ms_two / 10;
        ms_ones <= ms_two mod 10;
    end process;

    process(digit_idx, tens_bin, ones_bin, ms_tens, ms_ones, display_en)
    variable an_vec : STD_LOGIC_VECTOR(7 downto 0);
begin
    bin <= (others => '0');
    an_vec := (others => '1');
    dp_bit <= '0';

    if display_en = '0' then
        an <= (others => '1');
    else
        case digit_idx is
            when 7 | 6 | 5 | 4 =>
                bin <= (others => '1');
                dp_bit <= '1';
            when 3 =>
                bin <= tens_bin;
                dp_bit <= '1';
            when 2 =>
                bin <= ones_bin;
                dp_bit <= '0';
            when 1 =>
                bin <= std_logic_vector(to_unsigned(ms_tens, 4));
                dp_bit <= '1';
            when 0 =>
                bin <= std_logic_vector(to_unsigned(ms_ones, 4));
                dp_bit <= '1';
            when others =>
                bin <= (others => '0');
                dp_bit <= '1';
        end case;

        an_vec(digit_idx) := '0';
        an <= an_vec;
    end if;
end process;

    Bin2Seven : bin_to_7seg
        port map (
            bin => bin,
            seg => seg7
        );

    seg <= (others => '1') when display_en = '0' else (dp_bit & seg7);

    process(time_ms, max_time_i)
    begin
        if time_ms >= max_time_i then
            led_count <= 16;
        else
            led_count <= (time_ms * 16) / max_time_i;
        end if;
    end process;

    process(clk)
        variable r_temp : STD_LOGIC_VECTOR(15 downto 0);
        variable i_var  : integer;
        variable duty_r : unsigned(7 downto 0);
    begin
        if rising_edge(clk) then
            pwm_cnt <= std_logic_vector(unsigned(pwm_cnt) + 1);
            r_temp := (others => '0');

            for i_var in 0 to 15 loop
                if i_var >= (16 - led_count) then
                    if time_ms > (max_time_i * 2) / 3 then
                        duty_r := to_unsigned(255, 8);
                    elsif time_ms > max_time_i / 3 then
                        duty_r := to_unsigned(128, 8);
                    else
                        duty_r := to_unsigned(64, 8);
                    end if;

                    if unsigned(pwm_cnt) < duty_r then
                        r_temp(i_var) := '1';
                    else
                        r_temp(i_var) := '0';
                    end if;
                else
                    r_temp(i_var) := '0';
                end if;
            end loop;

            led_r_int <= r_temp;
        end if;
    end process;

    led_r       <= led_r_int;
    time_ms_out <= std_logic_vector(to_unsigned(time_ms, 14));
    time_up     <= '1' when time_ms = 0 else '0';

end Behavioral;