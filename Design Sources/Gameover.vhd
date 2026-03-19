library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity GameOver is
    Port (
        clk : in STD_LOGIC;
        an  : out STD_LOGIC_VECTOR(7 downto 0);
        seg : out STD_LOGIC_VECTOR(6 downto 0)
    );
end GameOver;

architecture Behavioral of GameOver is

signal refresh_counter : unsigned(19 downto 0) := (others => '0');
signal digit_select : unsigned(2 downto 0);

begin

process(clk)
begin
    if rising_edge(clk) then
        refresh_counter <= refresh_counter + 1;
    end if;
end process;

digit_select <= refresh_counter(19 downto 17);

process(digit_select)
begin

    case digit_select is

        when "000" =>
            an <= "01111111"; seg <= "0000010"; -- G

        when "001" =>
            an <= "10111111"; seg <= "0001000"; -- A

        when "010" =>
            an <= "11011111"; seg <= "1001000"; -- M

        when "011" =>
            an <= "11101111"; seg <= "0000110"; -- E

        when "100" =>
            an <= "11110111"; seg <= "1000000"; -- O

        when "101" =>
            an <= "11111011"; seg <= "1100011"; -- V

        when "110" =>
            an <= "11111101"; seg <= "0000110"; -- E

        when "111" =>
            an <= "11111110"; seg <= "0101111"; -- r

    end case;

end process;

end Behavioral;