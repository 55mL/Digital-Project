library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity difficulty_ctrl is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        decrease    : in  STD_LOGIC;   
        reset_diff  : in  STD_LOGIC;   
        time_val_ms : out integer range 1000 to 5000
    );
end difficulty_ctrl;

architecture Behavioral of difficulty_ctrl is
    constant CD_START_MS : integer := 5000;
    constant CD_MIN_MS   : integer := 1000;
    constant CD_DEC_MS   : integer := 200;
    signal   val_i       : integer range CD_MIN_MS to CD_START_MS := CD_START_MS;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or reset_diff = '1' then
                val_i <= CD_START_MS;
            elsif decrease = '1' then
                if val_i - CD_DEC_MS >= CD_MIN_MS then
                    val_i <= val_i - CD_DEC_MS;
                else
                    val_i <= CD_MIN_MS;
                end if;
            end if;
        end if;
    end process;

    time_val_ms <= val_i;
end Behavioral;