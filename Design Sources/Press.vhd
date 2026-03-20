library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Press is
    Port (
        clk  : in STD_LOGIC;
        btn1 : in STD_LOGIC;  -- N17 (Player 1)
        btn2 : in STD_LOGIC;  -- M17 (Player 2)
        an   : out STD_LOGIC_VECTOR(7 downto 0);
        seg  : out STD_LOGIC_VECTOR(6 downto 0)
    );
end Press;

architecture Behavioral of Press is

signal refresh_counter : unsigned(19 downto 0) := (others => '0');
signal digit_select : unsigned(2 downto 0);

-- 00 = PRESS, 01 = START P1, 10 = START P2
signal state : STD_LOGIC_VECTOR(1 downto 0) := "00";

begin

-- Clock divider + state control
process(clk)
begin
    if rising_edge(clk) then
        refresh_counter <= refresh_counter + 1;

        if btn1 = '1' then
            state <= "01"; -- Player 1
        elsif btn2 = '1' then
            state <= "10"; -- Player 2
        end if;

    end if;
end process;

digit_select <= refresh_counter(18 downto 16); -- faster refresh

-- Display logic
process(digit_select, state)
begin

    case state is

    -- =====================
    -- PRESS
    -- =====================
    when "00" =>
        case digit_select is
            when "000" => an <= "01111111"; seg <= "0001100"; -- P
            when "001" => an <= "10111111"; seg <= "0101111"; -- r
            when "010" => an <= "11011111"; seg <= "0000110"; -- E
            when "011" => an <= "11101111"; seg <= "0010010"; -- S
            when "100" => an <= "11110111"; seg <= "0010010"; -- S
            when others => an <= "11111111"; seg <= "1111111";
        end case;

    -- =====================
    -- START P1
    -- =====================
    when "01" =>
        case digit_select is
            when "000" => an <= "01111111"; seg <= "0010010"; -- S
            when "001" => an <= "10111111"; seg <= "0000111"; -- T
            when "010" => an <= "11011111"; seg <= "0001000"; -- A
            when "011" => an <= "11101111"; seg <= "0101111"; -- r
            when "100" => an <= "11110111"; seg <= "0000111"; -- T
            when "101" => an <= "11111011"; seg <= "0001100"; -- P
            when "110" => an <= "11111101"; seg <= "1111001"; -- 1
            when others => an <= "11111111"; seg <= "1111111";
        end case;

    -- =====================
    -- START P2
    -- =====================
    when "10" =>
        case digit_select is
            when "000" => an <= "01111111"; seg <= "0010010"; -- S
            when "001" => an <= "10111111"; seg <= "0000111"; -- T
            when "010" => an <= "11011111"; seg <= "0001000"; -- A
            when "011" => an <= "11101111"; seg <= "0101111"; -- r
            when "100" => an <= "11110111"; seg <= "0000111"; -- T
            when "101" => an <= "11111011"; seg <= "0001100"; -- P
            when "110" => an <= "11111101"; seg <= "0100100"; -- 2
            when others => an <= "11111111"; seg <= "1111111";
        end case;

    when others =>
        an <= "11111111";
        seg <= "1111111";

    end case;

end process;

end Behavioral;