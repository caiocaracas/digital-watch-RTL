library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity time_core is
  port (
    clk_sys     : in std_logic;
    rst_sync    : in std_logic;
    tick_sec    : in std_logic;
    btn_a_level : in std_logic; -- reset especial com os dois níveis = '1'
    btn_b_level : in std_logic;
    hh          : out std_logic_vector(4 downto 0); -- 0..23
    mm          : out std_logic_vector(5 downto 0); -- 0..59
    ss          : out std_logic_vector(5 downto 0) -- 0..59
  );
end entity time_core;

architecture rtl of time_core is
  signal h_q, h_d : unsigned(4 downto 0) := (others => '0'); -- horas
  signal m_q, m_d : unsigned(5 downto 0) := (others => '0'); -- minutos
  signal s_q, s_d : unsigned(5 downto 0) := (others => '0'); -- segundos
begin
  -- registradores
  regs : process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_sync = '1' then
        h_q <= (others => '0');
        m_q <= (others => '0');
        s_q <= (others => '0');
      else
        h_q <= h_d;
        m_q <= m_d;
        s_q <= s_d;
      end if;
    end if;
  end process;

  -- próxima contagem / reset especial
  comb : process (h_q, m_q, s_q, tick_sec, btn_a_level, btn_b_level)
    variable h : unsigned(h_q'range);
    variable m : unsigned(m_q'range);
    variable s : unsigned(s_q'range);
  begin
    h := h_q;
    m := m_q;
    s := s_q;

    if (btn_a_level = '1') and (btn_b_level = '1') then
      h := to_unsigned(12, h'length);
      m := (others => '0');
      s := (others => '0');
    elsif tick_sec = '1' then
      if s = to_unsigned(59, s'length) then
        s := (others => '0');
        if m = to_unsigned(59, m'length) then
          m := (others => '0');
          if h = to_unsigned(23, h'length) then
            h := (others => '0');
          else
            h := h + 1;
          end if;
        else
          m := m + 1;
        end if;
      else
        s := s + 1;
      end if;
    end if;

    h_d <= h;
    m_d <= m;
    s_d <= s;
  end process;

  hh <= std_logic_vector(h_q);
  mm <= std_logic_vector(m_q);
  ss <= std_logic_vector(s_q);
end architecture rtl;
