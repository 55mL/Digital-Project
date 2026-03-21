library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_fsm is
    Port (
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
end game_fsm;

architecture Behavioral of game_fsm is

    attribute keep_hierarchy : string;
    attribute keep_hierarchy of Behavioral : architecture is "yes";

    type game_state_t is (
        ST_PRESS,
        ST_START,
        ST_RANDOM,
        ST_LOAD_CD,
        ST_COUNTDOWN,
        ST_PASS,
        ST_WAIT_VERT,
        ST_FAIL,
        ST_SCORE,
        ST_HIGHSCORE
    );

    function state_to_slv(s : game_state_t) return std_logic_vector is
    begin
        case s is
            when ST_PRESS     => return "0000";
            when ST_START     => return "0001";
            when ST_RANDOM    => return "0010";
            when ST_LOAD_CD   => return "0011";
            when ST_COUNTDOWN => return "0100";
            when ST_PASS      => return "0101";
            when ST_WAIT_VERT => return "0110";
            when ST_FAIL      => return "0111";
            when ST_SCORE     => return "1000";
            when ST_HIGHSCORE => return "1001";
            when others       => return "0000";
        end case;
    end function;

    constant ONE_SEC : integer := 100_000_000;

    signal game_state     : game_state_t := ST_PRESS;
    signal delay_cnt      : integer range 0 to ONE_SEC := 0;
    signal color_latch_i  : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal load_wait_i    : integer range 0 to 3 := 0;

begin

    color_latch   <= color_latch_i;
    load_wait_cnt <= load_wait_i;
    state_slv     <= state_to_slv(game_state);

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                game_state    <= ST_PRESS;
                seg_sel       <= '1';
                cd_display    <= '0';
                cd_start      <= '0';
                ld17_en       <= '0';
                do_random     <= '0';
                delay_cnt     <= 0;
                color_latch_i <= "00";
                load_wait_i   <= 0;
                reset_score   <= '0';
                diff_reset    <= '0';
                inc_score     <= '0';
                diff_dec      <= '0';
                update_hs     <= '0';
            else
                cd_start    <= '0';
                do_random   <= '0';
                inc_score   <= '0';
                reset_score <= '0';
                update_hs   <= '0';
                diff_dec    <= '0';
                diff_reset  <= '0';

                case game_state is

                    when ST_PRESS =>
                        seg_sel     <= '1';
                        cd_display  <= '0';
                        ld17_en     <= '0';
                        reset_score <= '1';
                        diff_reset  <= '1';

                        if btn_pulse = '1' then
                            game_state <= ST_START;
                            delay_cnt  <= 0;
                        end if;

                    when ST_START =>
                        seg_sel <= '1';

                        if delay_cnt >= ONE_SEC - 1 then
                            delay_cnt  <= 0;
                            game_state <= ST_RANDOM;
                            do_random  <= '1';
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    when ST_RANDOM =>
                        seg_sel <= '1';
                        ld17_en <= '1';

                        if color_out /= "00" then
                            color_latch_i <= color_out;
                        end if;

                        if delay_cnt >= ONE_SEC - 1 then
                            delay_cnt   <= 0;
                            cd_start    <= '1';
                            cd_display  <= '1';
                            seg_sel     <= '0';
                            load_wait_i <= 0;
                            game_state  <= ST_LOAD_CD;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    when ST_LOAD_CD =>
                        seg_sel    <= '0';
                        ld17_en    <= '1';
                        cd_display <= '1';

                        if load_wait_i < 3 then
                            load_wait_i <= load_wait_i + 1;
                        else
                            game_state <= ST_COUNTDOWN;
                        end if;

                    when ST_COUNTDOWN =>
                        seg_sel <= '0';
                        ld17_en <= '1';

                        if hold_pass = '1' then
                            cd_display <= '0';
                            ld17_en    <= '0';
                            game_state <= ST_PASS;
                            delay_cnt  <= 0;

                        elsif cd_time_up = '1' then
                            cd_display <= '0';
                            ld17_en    <= '0';
                            update_hs  <= '1';
                            game_state <= ST_FAIL;
                            delay_cnt  <= 0;
                        end if;

                    when ST_PASS =>
                        seg_sel <= '1';

                        if delay_cnt >= ONE_SEC - 1 then
                            delay_cnt  <= 0;
                            inc_score  <= '1';
                            diff_dec   <= '1';
                            game_state <= ST_WAIT_VERT;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    when ST_WAIT_VERT =>
                        seg_sel <= '1';

                        if (x_val >= 420 and x_val <= 500 and
                            sw_i(15) = '0' and sw_i(0) = '0') or
                           (x_val >= 10  and x_val <= 90  and
                            sw_i(15) = '0' and sw_i(0) = '0') then
                            do_random  <= '1';
                            game_state <= ST_RANDOM;
                        end if;

                    when ST_FAIL =>
                        seg_sel <= '1';

                        if delay_cnt >= ONE_SEC - 1 then
                            delay_cnt  <= 0;
                            game_state <= ST_SCORE;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    when ST_SCORE =>
                        seg_sel <= '1';

                        if delay_cnt >= ONE_SEC * 2 - 1 then
                            delay_cnt  <= 0;
                            game_state <= ST_HIGHSCORE;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;

                    when ST_HIGHSCORE =>
                        seg_sel <= '1';
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