library ieee;
use ieee.std_logic_1164.all;

entity ClkGen is
port
 (clk_100MHz_i       : in    std_logic;
  clk_100MHz_o       : out   std_logic;
  clk_200MHz_o       : out   std_logic;
  reset_i            : in    std_logic;
  locked_o           : out   std_logic
 );
end ClkGen;

architecture behavioral of ClkGen is
begin
    -- Simple pass-through for simulation
    clk_100MHz_o <= clk_100MHz_i;
    clk_200MHz_o <= '0'; -- Not used in top level
    locked_o <= '1';     -- Always locked in simulation
end behavioral;