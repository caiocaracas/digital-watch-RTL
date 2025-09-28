library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_div is
  generic (
    ticks_per_sec : natural := 50_000_000  -- 1 s @ 50 mhz
  );
  port (
    clk_sys  : in  std_logic;
    rst_sync : in  std_logic;
    tick_sec : out std_logic               -- pulso de 1 ciclo
  );
end entity clk_div;

architecture rtl of clk_div is
  signal cnt_q, cnt_d : natural := 0;
  signal tick_q       : std_logic := '0';
begin
  -- registradores
  regs : process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_sync = '1' then
        cnt_q  <= 0;
        tick_q <= '0';
      else
        cnt_q  <= cnt_d;
        tick_q <= '0';
        if cnt_q = ticks_per_sec - 1 then
          tick_q <= '1';
        end if;
      end if;
    end if;
  end process;

  -- próximo valor do contador
  comb : process (cnt_q)
  begin
    if cnt_q = ticks_per_sec - 1 then
      cnt_d <= 0;
    else
      cnt_d <= cnt_q + 1;
    end if;
  end process;

  tick_sec <= tick_q;
end architecture rtl;
