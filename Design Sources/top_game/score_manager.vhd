library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity score_manager is
    Port (
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        inc_score  : in  STD_LOGIC;   
        reset_score: in  STD_LOGIC;   
        update_hs  : in  STD_LOGIC;   
        score      : out integer range 0 to 9999;
        high_score : out integer range 0 to 9999
    );
end score_manager;

architecture Behavioral of score_manager is
    signal score_i      : integer range 0 to 9999 := 0;
    signal high_score_i : integer range 0 to 9999 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                score_i      <= 0;
                high_score_i <= 0;
            else
                if reset_score = '1' then
                    score_i <= 0;
                elsif inc_score = '1' then
                    if score_i < 9999 then
                        score_i <= score_i + 1;
                    end if;
                end if;

                if update_hs = '1' then
                    if score_i > high_score_i then
                        high_score_i <= score_i;
                    end if;
                end if;
            end if;
        end if;
    end process;

    score      <= score_i;
    high_score <= high_score_i;
end Behavioral;