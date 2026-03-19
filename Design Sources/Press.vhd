library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Press is
    Port (
        clk : in STD_LOGIC;
        btn : in STD_LOGIC;      -- N17 button
        an  : out STD_LOGIC_VECTOR(7 downto 0);
        seg : out STD_LOGIC_VECTOR(6 downto 0)
    );
end Press;

architecture Behavioral of Press is

signal refresh_counter : unsigned(19 downto 0) := (others => '0');
signal digit_select : unsigned(2 downto 0);
signal show_start : STD_LOGIC := '0';

begin

-- clock divider
process(clk)
begin
    if rising_edge(clk) then
        refresh_counter <= refresh_counter + 1;

        -- once button pressed → permanently show START
        if btn = '1' then
            show_start <= '1';
        end if;

    end if;
end process;

digit_select <= refresh_counter(19 downto 17);

process(digit_select, show_start)
begin

    if show_start = '1' then

        -- START
        case digit_select is

            when "000" =>
                an <= "11101111";  -- S
                seg <= "0010010";

            when "001" =>
                an <= "11110111";  -- T
                seg <= "0000111";

            when "010" =>
                an <= "11111011";  -- A
                seg <= "0001000";

            when "011" =>
                an  <= "11110111";
                seg <= "0101111";

            when "100" =>
                an <= "11111110";  -- T
                seg <= "0000111";

            when others =>
                an <= "11111111";
                seg <= "1111111";

        end case;

    else

        -- PRESS
        case digit_select is

            when "000" =>
                an <= "11101111";  -- P
                seg <= "0001100";

            when "001" =>
                an  <= "11110111";
                seg <= "0101111";

            when "010" =>
                an <= "11111011";  -- E
                seg <= "0000110";

            when "011" =>
                an <= "11111101";  -- S
                seg <= "0010010";

            when "100" =>
                an <= "11111110";  -- S
                seg <= "0010010";

            when others =>
                an <= "11111111";
                seg <= "1111111";

        end case;

    end if;

end process;

end Behavioral;