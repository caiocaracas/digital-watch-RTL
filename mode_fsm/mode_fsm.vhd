library ieee;
use ieee.std_logic_1164.all;

entity mode_fsm is
  port (
    clk_sys        : in  std_logic;
    rst_sync       : in  std_logic;
    btn_mode_pulse : in  std_logic;
    btn_act_pulse  : in  std_logic;
    inc_hour       : out std_logic;  -- pulso
    inc_min        : out std_logic;  -- pulso
    toggle_en      : out std_logic   -- pulso
  );
end entity mode_fsm;

architecture rtl of mode_fsm is
  type state_t is (s_h, s_m, s_en);
  signal st_q, st_d : state_t;
begin
  regs : process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_sync = '1' then
        st_q <= s_h;
      else
        st_q <= st_d;
      end if;
    end if;
  end process;

  comb : process (st_q, btn_mode_pulse, btn_act_pulse)
    variable inc_h, inc_m, tgl : std_logic := '0';
    variable ns : state_t;
  begin
    inc_h := '0'; inc_m := '0'; tgl := '0';
    ns := st_q;

    -- ações do act no estado atual
    case st_q is
      when s_h => if btn_act_pulse = '1' then inc_h := '1'; end if;
      when s_m => if btn_act_pulse = '1' then inc_m := '1'; end if;
      when s_en=> if btn_act_pulse = '1' then tgl  := '1'; end if;
    end case;

    -- avanço de estado pelo mode
    if btn_mode_pulse = '1' then
      case st_q is
        when s_h  => ns := s_m;
        when s_m  => ns := s_en;
        when s_en => ns := s_h;
      end case;
    end if;

    st_d      <= ns;
    inc_hour  <= inc_h;
    inc_min   <= inc_m;
    toggle_en <= tgl;
  end process;
end architecture rtl;
