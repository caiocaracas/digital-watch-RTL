library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity btn_sync_db is
  generic (
    db_count_max : natural := 1_000_000  -- ~20 ms @ 50 mhz
  );
  port (
    clk_sys    : in  std_logic;
    rst_sync   : in  std_logic;
    btn_in_raw : in  std_logic;
    btn_level  : out std_logic            -- nível limpo
  );
end entity btn_sync_db;

architecture rtl of btn_sync_db is
  signal s1_q, s2_q : std_logic := '0';
  signal stable_q, stable_d : std_logic := '0';
  signal cnt_q, cnt_d : natural := 0;
begin
  regs : process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_sync = '1' then
        s1_q <= '0'; s2_q <= '0';
        stable_q <= '0'; cnt_q <= 0;
      else
        s1_q <= btn_in_raw;
        s2_q <= s1_q;
        stable_q <= stable_d;
        cnt_q    <= cnt_d;
      end if;
    end if;
  end process;

  comb : process (s2_q, stable_q, cnt_q)
  begin
    stable_d <= stable_q;
    cnt_d    <= cnt_q;

    if s2_q = stable_q then
      cnt_d <= 0;
    else
      if cnt_q = db_count_max then
        stable_d <= s2_q;
        cnt_d    <= 0;
      else
        cnt_d    <= cnt_q + 1;
      end if;
    end if;
  end process;

  btn_level <= stable_q;
end architecture rtl;
