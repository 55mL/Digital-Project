library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sSegDemo is
   port(
      clk_i         : in std_logic;
      mode_i        : in std_logic_vector(1 downto 0); -- 00: Press Start, 01: Playing, 10: Game Over / High Score
      score_i       : in integer range 0 to 99;
      hi_score_i    : in integer range 0 to 99;
      seg_o         : out std_logic_vector(7 downto 0);
      an_o          : out std_logic_vector(7 downto 0)
   );
end sSegDemo;

architecture Behavioral of sSegDemo is
    signal refresh_counter : unsigned(19 downto 0) := (others => '0');
    signal digit_select : unsigned(2 downto 0);
    
    signal d_score_10, d_score_1 : integer range 0 to 9;
    signal d_hi_10, d_hi_1 : integer range 0 to 9;

    function to_seg(n : integer) return std_logic_vector is
    begin
        case n is
            when 0 => return "11000000"; -- 0
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
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;

    digit_select <= refresh_counter(19 downto 17);
    
    d_score_10 <= score_i / 10;
    d_score_1  <= score_i mod 10;
    d_hi_10    <= hi_score_i / 10;
    d_hi_1     <= hi_score_i mod 10;

    process(digit_select, mode_i, score_i, hi_score_i, d_score_10, d_score_1, d_hi_10, d_hi_1)
    begin
        an_o <= (others => '1');
        seg_o <= (others => '1');
        an_o(to_integer(digit_select)) <= '0';

        case mode_i is
            when "00" => -- PRESS START
                case digit_select is
                    when "111" => seg_o <= "10001100"; -- P
                    when "110" => seg_o <= "10101111"; -- r
                    when "101" => seg_o <= "10000110"; -- E
                    when "100" => seg_o <= "10010010"; -- S
                    when "011" => seg_o <= "10010010"; -- S
                    when "010" => seg_o <= "11111111"; -- blank
                    when "001" => seg_o <= "10010010"; -- S
                    when "000" => seg_o <= "10000111"; -- t
                    when others => null;
                end case;

            when "01" => -- PLAYING (Score)
                case digit_select is
                    when "111" => seg_o <= "10010010"; -- S
                    when "110" => seg_o <= "11000110"; -- C
                    when "101" => seg_o <= "11000000"; -- O
                    when "100" => seg_o <= "10101111"; -- r
                    when "011" => seg_o <= "10000110"; -- E
                    when "001" => seg_o <= to_seg(d_score_10);
                    when "000" => seg_o <= to_seg(d_score_1);
                    when others => null;
                end case;

            when "10" => -- GAME OVER / HI SCORE
                if refresh_counter(21) = '0' then -- GO + Score
                    case digit_select is
                        when "111" => seg_o <= "11000010"; -- G
                        when "110" => seg_o <= "11000000"; -- O
                        when "001" => seg_o <= to_seg(d_score_10);
                        when "000" => seg_o <= to_seg(d_score_1);
                        when others => null;
                    end case;
                else -- HI + HiScore
                    case digit_select is
                        when "111" => seg_o <= "10010001"; -- H
                        when "110" => seg_o <= "11111001"; -- I
                        when "001" => seg_o <= to_seg(d_hi_10);
                        when "000" => seg_o <= to_seg(d_hi_1);
                        when others => null;
                    end case;
                end if;
            when others => null;
        end case;
    end process;
end Behavioral;