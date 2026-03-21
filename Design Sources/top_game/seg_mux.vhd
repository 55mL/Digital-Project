library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seg_mux is
    Port (
        sel     : in  STD_LOGIC;   
        cd_seg  : in  STD_LOGIC_VECTOR(7 downto 0);
        cd_an   : in  STD_LOGIC_VECTOR(7 downto 0);
        txt_seg : in  STD_LOGIC_VECTOR(7 downto 0);
        txt_an  : in  STD_LOGIC_VECTOR(7 downto 0);
        seg_o   : out STD_LOGIC_VECTOR(7 downto 0);
        an_o    : out STD_LOGIC_VECTOR(7 downto 0)
    );
end seg_mux;

architecture Behavioral of seg_mux is
begin
    seg_o <= cd_seg  when sel = '0' else txt_seg;
    an_o  <= cd_an   when sel = '0' else txt_an;
end Behavioral;