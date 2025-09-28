library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alarm_fsm is
  generic (
    t_long  : natural := 5; -- s
    t_short : natural := 2; -- s
    t_gap   : natural := 1 -- s
  );
  port (
    clk_sys        : in std_logic;
    rst_sync       : in std_logic;
    tick_sec       : in std_logic; -- pulso de 1 ciclo
    alarm_active_q : in std_logic; -- 1 = rodar padrão
    beep           : out std_logic
  );
end entity alarm_fsm;

architecture rtl of alarm_fsm is
  type state_t is (idle, l5, g1, l2a, g2, l2b, g3);
  signal state_q, state_d : state_t;
  signal cnt_q, cnt_d     : natural range 0 to 1023 := 0;
begin
  -- registradores
  regs : process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_sync = '1' then
        state_q <= idle;
        cnt_q   <= 0;
      else
        state_q <= state_d;
        cnt_q   <= cnt_d;
      end if;
    end if;
  end process;

  -- próxima transição + contador
  comb : process (state_q, cnt_q, tick_sec, alarm_active_q)
    variable ns   : state_t;
    variable nc   : natural range 0 to 1023;
    variable dur  : natural;
    variable done : boolean;
  begin
    -- defaults
    ns   := state_q;
    nc   := cnt_q;
    dur  := 0;
    done := false;

    if alarm_active_q = '0' then
      ns := idle;
      nc := 0;
    else
      -- duração por estado
      case state_q is
        when idle => dur := 0;
        when l5   => dur   := t_long;
        when g1   => dur   := t_gap;
        when l2a  => dur  := t_short;
        when g2   => dur   := t_gap;
        when l2b  => dur  := t_short;
        when g3   => dur   := t_gap;
      end case;

      -- conta 0..dur-1; done no último tick
      if state_q /= idle then
        if tick_sec = '1' then
          if cnt_q + 1 = dur then
            done := true;
            nc   := 0;
          else
            nc := cnt_q + 1;
          end if;
        end if;
      end if;

      -- transições
      case state_q is
        when idle => ns := l5;
          nc              := 0;
        when l5 => if done then
          ns := g1;
      end if;
      when g1 => if done then
      ns := l2a;
    end if;
    when l2a => if done then
    ns := g2;
  end if;
  when g2 => if done then
  ns := l2b;
end if;
when l2b => if done then
ns := g3;
end if;
when g3 => if done then
ns := l5;
end if;
end case;
end if;

state_d <= ns;
cnt_d   <= nc;
end process;

-- saída moore
outp : process (state_q)
begin
  case state_q is
    when l5 | l2a | l2b => beep <= '1';
    when others         => beep         <= '0';
  end case;
end process;
end architecture rtl;
