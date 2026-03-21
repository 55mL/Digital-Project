library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity text_display is
    Port (
        clk        : in  STD_LOGIC;
        game_state : in  STD_LOGIC_VECTOR(3 downto 0); 
        high_score : in  integer range 0 to 9999;
        score      : in  integer range 0 to 9999;
        seg_o      : out STD_LOGIC_VECTOR(7 downto 0);
        an_o       : out STD_LOGIC_VECTOR(7 downto 0)
    );
end text_display;

-- State encoding constants (must match top_game):
-- ST_PRESS      = 0000
-- ST_START      = 0001
-- ST_RANDOM     = 0010
-- ST_LOAD_CD    = 0011
-- ST_COUNTDOWN  = 0100
-- ST_PASS       = 0101
-- ST_WAIT_VERT  = 0110
-- ST_FAIL       = 0111
-- ST_SCORE      = 1000
-- ST_HIGHSCORE  = 1001

architecture Behavioral of text_display is
    signal refresh_cnt : unsigned(19 downto 0) := (others => '0');
    signal digit_sel   : unsigned(2 downto 0);

    signal hs_d0, hs_d1, hs_d2, hs_d3       : integer range 0 to 9;
    signal score_d0, score_d1, score_d2, score_d3 : integer range 0 to 9;

    function digit_to_seg(d : integer range 0 to 9) return std_logic_vector is
    begin
        case d is
            when 0 => return "11000000";
            when 1 => return "11111001";
            when 2 => return "10100100";
            when 3 => return "10110000";
            when 4 => return "10011001";
            when 5 => return "10010010";
            when 6 => return "10000010";
            when 7 => return "11111000";
            when 8 => return "10000000";
            when 9 => return "10010000";
            when others => return "11111111";
        end case;
    end function;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;
    digit_sel <= refresh_cnt(19 downto 17);

    hs_d0 <= high_score mod 10;
    hs_d1 <= (high_score / 10) mod 10;
    hs_d2 <= (high_score / 100) mod 10;
    hs_d3 <= (high_score / 1000) mod 10;

    score_d0 <= score mod 10;
    score_d1 <= (score / 10) mod 10;
    score_d2 <= (score / 100) mod 10;
    score_d3 <= (score / 1000) mod 10;

    process(digit_sel, game_state, hs_d0, hs_d1, hs_d2, hs_d3,
            score_d0, score_d1, score_d2, score_d3)
    begin
        seg_o <= "11111111";
        an_o  <= "11111111";

        case game_state is

            when "0000" =>  -- ST_PRESS
                case digit_sel is
                    when "100" => an_o <= "11101111"; seg_o <= "10001100";
                    when "011" => an_o <= "11110111"; seg_o <= "10101111";
                    when "010" => an_o <= "11111011"; seg_o <= "10000110";
                    when "001" => an_o <= "11111101"; seg_o <= "10010010";
                    when "000" => an_o <= "11111110"; seg_o <= "10010010";
                    when others => an_o <= "11111111"; seg_o <= "11111111";
                end case;

            when "0001" =>  -- ST_START
                case digit_sel is
                    when "100" => an_o <= "11101111"; seg_o <= "10010010";
                    when "011" => an_o <= "11110111"; seg_o <= "10000111";
                    when "010" => an_o <= "11111011"; seg_o <= "10001000";
                    when "001" => an_o <= "11111101"; seg_o <= "10101111";
                    when "000" => an_o <= "11111110"; seg_o <= "10000111";
                    when others => an_o <= "11111111"; seg_o <= "11111111";
                end case;

            when "0101" =>  -- ST_PASS
                case digit_sel is
                    when "011" => an_o <= "11110111"; seg_o <= "10001100";
                    when "010" => an_o <= "11111011"; seg_o <= "10001000";
                    when "001" => an_o <= "11111101"; seg_o <= "10010010";
                    when "000" => an_o <= "11111110"; seg_o <= "10010010";
                    when others => an_o <= "11111111"; seg_o <= "11111111";
                end case;

            when "0110" =>  -- ST_WAIT_VERT
                case digit_sel is
                    when "011" => an_o <= "11110111"; seg_o <= "11000001";
                    when "010" => an_o <= "11111011"; seg_o <= "10001100";
                    when others => an_o <= "11111111"; seg_o <= "11111111";
                end case;

            when "0111" =>  -- ST_FAIL
                case digit_sel is
                    when "011" => an_o <= "11110111"; seg_o <= "10001110";
                    when "010" => an_o <= "11111011"; seg_o <= "10001000";
                    when "001" => an_o <= "11111101"; seg_o <= "11111001";
                    when "000" => an_o <= "11111110"; seg_o <= "11000111";
                    when others => an_o <= "11111111"; seg_o <= "11111111";
                end case;

            when "1000" =>  -- ST_SCORE
                case digit_sel is
                    when "011" => an_o <= "11110111"; seg_o <= digit_to_seg(score_d3);
                    when "010" => an_o <= "11111011"; seg_o <= digit_to_seg(score_d2);
                    when "001" => an_o <= "11111101"; seg_o <= digit_to_seg(score_d1);
                    when "000" => an_o <= "11111110"; seg_o <= digit_to_seg(score_d0);
                    when others => an_o <= "11111111"; seg_o <= "11111111";
                end case;

            when "1001" =>  -- ST_HIGHSCORE
                case digit_sel is
                    when "111" => an_o <= "01111111"; seg_o <= "10001001";
                    when "110" => an_o <= "10111111"; seg_o <= "11111001";
                    when "101" | "100" => an_o <= "11111111"; seg_o <= "11111111";
                    when "011" => an_o <= "11110111"; seg_o <= digit_to_seg(hs_d3);
                    when "010" => an_o <= "11111011"; seg_o <= digit_to_seg(hs_d2);
                    when "001" => an_o <= "11111101"; seg_o <= digit_to_seg(hs_d1);
                    when "000" => an_o <= "11111110"; seg_o <= digit_to_seg(hs_d0);
                    when others => an_o <= "11111111"; seg_o <= "11111111";
                end case;

            when others =>
                seg_o <= "11111111";
                an_o  <= "11111111";
        end case;
    end process;

end Behavioral;