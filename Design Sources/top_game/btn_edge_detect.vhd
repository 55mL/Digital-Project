library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity btn_edge_detect is
    Port (
        clk       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        btn_in    : in  STD_LOGIC;
        btn_pulse : out STD_LOGIC
    );
end btn_edge_detect;

architecture Behavioral of btn_edge_detect is
    signal btn_prev : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                btn_prev  <= '0';
                btn_pulse <= '0';
            else
                btn_pulse <= btn_in and (not btn_prev);
                btn_prev  <= btn_in;
            end if;
        end if;
    end process;
end Behavioral;