library ieee;
use ieee.std_logic_1164.all;

entity edge_detect is
  port (
    clk_sys   : in  std_logic;
    rst_sync  : in  std_logic;
    level_in  : in  std_logic;   -- do debounce
    pulse_out : out std_logic
  );
end entity edge_detect;

architecture rtl of edge_detect is
  signal prev_q : std_logic := '0';
begin
  regs : process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_sync = '1' then
        prev_q <= '0';
      else
        prev_q <= level_in;
      end if;
    end if;
  end process;

  pulse_out <= level_in and not prev_q;
end architecture rtl;
