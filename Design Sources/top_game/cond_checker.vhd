library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cond_checker is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        active      : in  STD_LOGIC;  
        color_latch : in  STD_LOGIC_VECTOR(1 downto 0);
        x_val       : in  integer range 0 to 511;
        sw_in       : in  STD_LOGIC_VECTOR(15 downto 0);
        cond_ok     : out STD_LOGIC;
        hold_pass   : out STD_LOGIC
    );
end cond_checker;

architecture Behavioral of cond_checker is
    constant ONE_SEC  : integer := 100_000_000;
    signal cond_ok_i  : STD_LOGIC := '0';
    signal hold_cnt   : integer range 0 to ONE_SEC := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            cond_ok_i <= '0';
            if active = '1' then
                case color_latch is
                    when "01" =>   -- Green
                        if (x_val >= 370 and x_val <= 398) and sw_in(15) = '1' then
                            cond_ok_i <= '1';
                        end if;
                    when "10" =>   -- Yellow
                        if (x_val >= 370 and x_val <= 398) and sw_in(0) = '1' then
                            cond_ok_i <= '1';
                        end if;
                    when "11" =>   -- Red
                        if (x_val >= 241 and x_val <= 270) and sw_in(15) = '1' and sw_in(0) = '1' then
                            cond_ok_i <= '1';
                        end if;
                    when others =>
                        cond_ok_i <= '0';
                end case;
            end if;
        end if;
    end process;

    cond_ok <= cond_ok_i;

    -- Hold counter
    process(clk)
    begin
        if rising_edge(clk) then
            hold_pass <= '0';
            if active = '1' then
                if cond_ok_i = '1' then
                    if hold_cnt >= (ONE_SEC / 2) - 1 then
                        hold_cnt  <= 0;
                        hold_pass <= '1';
                    else
                        hold_cnt <= hold_cnt + 1;
                    end if;
                else
                    hold_cnt <= 0;
                end if;
            else
                hold_cnt  <= 0;
                hold_pass <= '0';
            end if;
        end if;
    end process;

end Behavioral;