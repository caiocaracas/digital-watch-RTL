library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alarm_regs is
  port (
    clk_sys   : in  std_logic;
    rst_sync  : in  std_logic;
    inc_hour  : in  std_logic;  -- pulso
    inc_min   : in  std_logic;  -- pulso
    toggle_en : in  std_logic;  -- pulso
    alrm_h    : out std_logic_vector(4 downto 0); -- 0..23
    alrm_m    : out std_logic_vector(5 downto 0); -- 0..59
    alrm_en   : out std_logic
  );
end entity alarm_regs;

architecture rtl of alarm_regs is
  signal h_q, h_d : std_logic_vector(4 downto 0); -- horas
  signal m_q, m_d : std_logic_vector(5 downto 0); -- minutos
  signal e_q, e_d : std_logic;                    -- enable
begin
  -- registradores
  regs : process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_sync = '1' then
        h_q <= (others => '0');        -- 00
        m_q <= (others => '0');        -- 00
        e_q <= '0';                    -- desativado
      else
        h_q <= h_d;
        m_q <= m_d;
        e_q <= e_d;
      end if;
    end if;
  end process;

  -- próxima atualização (rolagem mod 24/60; toggle no enable)
  comb : process (h_q, m_q, e_q, inc_hour, inc_min, toggle_en)
    variable h_u : unsigned(4 downto 0);
    variable m_u : unsigned(5 downto 0);
  begin
    h_d <= h_q;
    m_d <= m_q;
    e_d <= e_q;

    if inc_hour = '1' then
      h_u := unsigned(h_q) + 1;
      if h_u = 24 then
        h_d <= (others => '0');
      else
        h_d <= std_logic_vector(h_u);
      end if;
    end if;

    if inc_min = '1' then
      m_u := unsigned(m_q) + 1;
      if m_u = 60 then
        m_d <= (others => '0');
      else
        m_d <= std_logic_vector(m_u);
      end if;
    end if;

    if toggle_en = '1' then
      e_d <= not e_q;
    end if;
  end process;

  alrm_h <= h_q;
  alrm_m <= m_q;
  alrm_en <= e_q;
end architecture rtl;
