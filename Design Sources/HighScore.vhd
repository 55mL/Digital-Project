library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HighScore is
    Port (
        clk : in STD_LOGIC;
        an  : out STD_LOGIC_VECTOR(7 downto 0);
        seg : out STD_LOGIC_VECTOR(6 downto 0)
    );
end HighScore;

architecture Behavioral of HighScore is

signal refresh_counter : unsigned(19 downto 0) := (others => '0');
signal digit_select : unsigned(2 downto 0);

-- score value
signal score : integer range 0 to 9999 := 0;

signal d0,d1,d2,d3 : integer range 0 to 9;

begin

-- clock divider
process(clk)
begin
    if rising_edge(clk) then
        refresh_counter <= refresh_counter + 1;
    end if;
end process;

digit_select <= refresh_counter(19 downto 17);

-- split score into digits
d0 <= score mod 10;
d1 <= (score / 10) mod 10;
d2 <= (score / 100) mod 10;
d3 <= (score / 1000) mod 10;

process(digit_select)
begin

case digit_select is

    -- H
    when "000" =>
        an  <= "01111111";
        seg <= "0001001";

    -- I
    when "001" =>
        an  <= "10111111";
        seg <= "1111001";

    -- blank
    when "010" =>
        an <= "11011111";
        seg <= "1111111";

    -- blank
    when "011" =>
        an <= "11101111";
        seg <= "1111111";

    -- digit 3
    when "100" =>
        an <= "11110111";
        case d3 is
            when 0 => seg <= "1000000";
            when 1 => seg <= "1111001";
            when 2 => seg <= "0100100";
            when 3 => seg <= "0110000";
            when 4 => seg <= "0011001";
            when 5 => seg <= "0010010";
            when 6 => seg <= "0000010";
            when 7 => seg <= "1111000";
            when 8 => seg <= "0000000";
            when 9 => seg <= "0010000";
        end case;

    -- digit 2
    when "101" =>
        an <= "11111011";
        case d2 is
            when 0 => seg <= "1000000";
            when 1 => seg <= "1111001";
            when 2 => seg <= "0100100";
            when 3 => seg <= "0110000";
            when 4 => seg <= "0011001";
            when 5 => seg <= "0010010";
            when 6 => seg <= "0000010";
            when 7 => seg <= "1111000";
            when 8 => seg <= "0000000";
            when 9 => seg <= "0010000";
        end case;

    -- digit 1
    when "110" =>
        an <= "11111101";
        case d1 is
            when 0 => seg <= "1000000";
            when 1 => seg <= "1111001";
            when 2 => seg <= "0100100";
            when 3 => seg <= "0110000";
            when 4 => seg <= "0011001";
            when 5 => seg <= "0010010";
            when 6 => seg <= "0000010";
            when 7 => seg <= "1111000";
            when 8 => seg <= "0000000";
            when 9 => seg <= "0010000";
        end case;

    -- digit 0
    when "111" =>
        an <= "11111110";
        case d0 is
            when 0 => seg <= "1000000";
            when 1 => seg <= "1111001";
            when 2 => seg <= "0100100";
            when 3 => seg <= "0110000";
            when 4 => seg <= "0011001";
            when 5 => seg <= "0010010";
            when 6 => seg <= "0000010";
            when 7 => seg <= "1111000";
            when 8 => seg <= "0000000";
            when 9 => seg <= "0010000";
        end case;

end case;

end process;

end Behavioral;