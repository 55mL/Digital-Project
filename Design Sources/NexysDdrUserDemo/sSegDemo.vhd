library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sSegDemo is
   port(
      clk_i         : in std_logic;
      rstn_i        : in std_logic;
      accel_x_i     : in std_logic_vector(8 downto 0); 
      accel_y_i     : in std_logic_vector(8 downto 0); 
      game_status_i : in std_logic_vector(1 downto 0); 
      seg_o         : out std_logic_vector(7 downto 0);
      an_o          : out std_logic_vector(7 downto 0)
   );
end sSegDemo;

architecture Behavioral of sSegDemo is

component sSegDisplay is
port(
   ck       : in  std_logic;
   number   : in  std_logic_vector(63 downto 0);
   seg      : out std_logic_vector(7 downto 0);
   an       : out std_logic_vector(7 downto 0));
end component;

signal dispVal : std_logic_vector(63 downto 0);

function bin2bcd(bin : std_logic_vector(8 downto 0)) return std_logic_vector is
    variable bcd : std_logic_vector(20 downto 0) := (others => '0');
begin
    bcd(8 downto 0) := bin;
    for i in 0 to 8 loop
        if bcd(12 downto 9) > 4 then bcd(12 downto 9) := bcd(12 downto 9) + 3; end if;
        if bcd(16 downto 13) > 4 then bcd(16 downto 13) := bcd(16 downto 13) + 3; end if;
        if bcd(20 downto 17) > 4 then bcd(20 downto 17) := bcd(20 downto 17) + 3; end if;
        bcd := bcd(19 downto 0) & '0';
    end loop;
    return bcd(20 downto 9);
end function;

function hex2seg(hex : std_logic_vector(3 downto 0)) return std_logic_vector is
begin
    case hex is
        when x"0" => return x"C0";
        when x"1" => return x"F9";
        when x"2" => return x"A4";
        when x"3" => return x"B0";
        when x"4" => return x"99";
        when x"5" => return x"92";
        when x"6" => return x"82";
        when x"7" => return x"F8";
        when x"8" => return x"80";
        when x"9" => return x"90";
        when others => return x"FF";
    end case;
end function;

signal bcd_x : std_logic_vector(11 downto 0);
signal game_status_pattern : std_logic_vector(31 downto 0);

begin

   bcd_x <= bin2bcd(accel_x_i);
   
   process(game_status_i)
   begin
       if game_status_i = "01" then 
           game_status_pattern <= x"8C" & x"88" & x"92" & x"92";
       elsif game_status_i = "10" then 
           game_status_pattern <= x"8E" & x"88" & x"F9" & x"C7";
       else 
           game_status_pattern <= x"FF" & x"FF" & x"FF" & x"FF";
       end if;
   end process;

   dispVal <=  game_status_pattern &             
               x"FF" &                           
               hex2seg(bcd_x(11 downto 8)) &     
               hex2seg(bcd_x(7 downto 4)) &      
               hex2seg(bcd_x(3 downto 0));       
               
   Disp: sSegDisplay
   port map(
      ck       => clk_i,
      number   => dispVal,
      seg      => seg_o,
      an       => an_o);

end Behavioral;