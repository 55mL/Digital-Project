library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        tick_out_1hz  : out std_logic;
        tick_out_1khz : out std_logic
    );
end clock_divider;

architecture Behavioral of clock_divider is
    -- เหลือแค่ตัวแปรสำหรับนับเลข ไม่ต้องมี signal tick_1hz อีกแล้ว
    signal cnt_1hz  : unsigned(27 downto 0) := (others => '0');
    signal cnt_1khz : unsigned(16 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cnt_1hz       <= (others => '0');
                cnt_1khz      <= (others => '0');
                tick_out_1hz  <= '0';
                tick_out_1khz <= '0';
            else
                -- ให้สัญญาณเป็น 0 ไว้ตลอดเวลา (จนกว่าจะนับครบ)
                tick_out_1hz  <= '0';
                tick_out_1khz <= '0';

                -- สร้าง 1 Hz Pulse (นับถึง 99,999,999 สำหรับคล็อก 100MHz)
                if cnt_1hz = 99_999_999 then
                    cnt_1hz      <= (others => '0');
                    tick_out_1hz <= '1'; -- ส่ง Pulse ออกไป 1 รอบคล็อก
                else
                    cnt_1hz <= cnt_1hz + 1;
                end if;

                -- สร้าง 1 kHz Pulse (นับถึง 99,999 สำหรับคล็อก 100MHz)
                if cnt_1khz = 99_999 then
                    cnt_1khz      <= (others => '0');
                    tick_out_1khz <= '1'; -- ส่ง Pulse ออกไป 1 รอบคล็อก
                else
                    cnt_1khz <= cnt_1khz + 1;
                end if;
            end if;
        end if;
    end process;

    -- *** ลบบรรทัด tick_out_1hz <= tick_1hz; ด้านล่างสุดทิ้งไปเลยครับ ***

end Behavioral;