library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Press_tb is
end Press_tb;

architecture sim of Press_tb is
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

    signal clk : std_logic := '0';
    signal btn : std_logic := '0';
    signal an  : std_logic_vector(7 downto 0);
    signal seg : std_logic_vector(6 downto 0);

    procedure wait_for_digit(
        constant expected_an  : in std_logic_vector(7 downto 0);
        constant expected_seg : in std_logic_vector(6 downto 0);
        constant timeout      : in time
    ) is
        variable elapsed : time := 0 ns;
    begin
        while elapsed < timeout loop
            wait until rising_edge(clk);
            elapsed := elapsed + CLK_PERIOD;
            if an = expected_an then
                assert seg = expected_seg
                    report "Segment mismatch for an=" & to_hstring(expected_an)
                    severity error;
                return;
            end if;
        end loop;

        assert false
            report "Timeout waiting for an=" & to_hstring(expected_an)
            severity error;
    end procedure;

begin
    -- DUT instance
    dut: entity work.Press
        port map (
            clk => clk,
            btn => btn,
            an  => an,
            seg => seg
        );

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2;

    stim_proc: process
    begin
        -- Let counters settle and scan a few digits.
        wait_for_digit(x"EF", "0001100", 12 ms); -- P in PRESS
        wait_for_digit(x"FB", "0000110", 12 ms); -- E in PRESS
        wait_for_digit(x"FD", "0010010", 12 ms); -- S in PRESS

        -- Press button and verify START appears and stays latched.
        btn <= '1';
        wait for 3 * CLK_PERIOD;
        btn <= '0';

        wait_for_digit(x"EF", "0010010", 12 ms); -- S in START
        wait_for_digit(x"FB", "0001000", 12 ms); -- A in START
        wait_for_digit(x"FE", "0000111", 12 ms); -- T in START

        -- Wait longer to ensure it does not revert back to PRESS.
        wait for 4 ms;
        assert not (an = x"EF" and seg = "0001100")
            report "Unexpected revert to PRESS after button latch"
            severity error;

        assert false report "Simulation PASSED" severity note;
        wait;
    end process;
end sim;
