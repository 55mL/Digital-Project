library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RandomColor is
    Port ( clk        : in  STD_LOGIC;  
           btn_random : in  STD_LOGIC;  
           led17_r    : out STD_LOGIC;  
           led17_g    : out STD_LOGIC;  
           led17_b    : out STD_LOGIC;  
           color_out  : out STD_LOGIC_VECTOR(1 downto 0) 
         ); 
end RandomColor;

architecture Behavioral of RandomColor is

    signal fast_counter : integer range 0 to 255 := 0;
    signal random_val   : integer range 0 to 255 := 0;
    signal btn_reg      : STD_LOGIC := '0';

    signal target_r     : STD_LOGIC := '0';
    signal target_g     : STD_LOGIC := '0';
    signal target_b     : STD_LOGIC := '0';

    signal pwm_counter  : integer range 0 to 100 := 0;
    constant BRIGHTNESS : integer := 5; 

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if fast_counter = 255 then
                fast_counter <= 0;
            else
                fast_counter <= fast_counter + 1;
            end if;

            
            if btn_random = '1' and btn_reg = '0' then
                random_val <= fast_counter;
            end if;

            btn_reg <= btn_random;
        end if;
    end process;

    process(random_val)
    begin
        target_r <= '0';
        target_g <= '0';
        target_b <= '0';
        color_out <= "00"; 

        if ((random_val >= 0 and random_val <= 9) or       
            (random_val >= 28 and random_val <= 40) or     
            (random_val >= 67 and random_val <= 74) or     
            (random_val >= 100 and random_val <= 115) or   
            (random_val >= 141 and random_val <= 150) or   
            (random_val >= 179 and random_val <= 190) or   
            (random_val >= 216 and random_val <= 225) or   
            (random_val >= 246 and random_val <= 251)) then 
            
            target_g <= '1';   
            color_out <= "01"; -- Green
            
        elsif ((random_val >= 10 and random_val <= 18) or     
               (random_val >= 41 and random_val <= 55) or     
               (random_val >= 75 and random_val <= 88) or     
               (random_val >= 116 and random_val <= 125) or   
               (random_val >= 151 and random_val <= 165) or   
               (random_val >= 191 and random_val <= 200) or   
               (random_val >= 226 and random_val <= 235) or   
               (random_val = 252 or random_val = 253)) then   
                
            target_r <= '1';
            target_g <= '1';
            color_out <= "10";  -- Yellow
        else
            target_r <= '1';
            color_out <= "11";  -- Red
        end if;
    end process;
    process(clk)
    begin
        if rising_edge(clk) then
            if pwm_counter >= 100 then
                pwm_counter <= 0;
            else
                pwm_counter <= pwm_counter + 1;
            end if;
            if pwm_counter < BRIGHTNESS then
                led17_r <= target_r;
                led17_g <= target_g;
                led17_b <= target_b;
            else
                led17_r <= '0';
                led17_g <= '0';
                led17_b <= '0';
            end if;
        end if;
    end process;

end Behavioral;