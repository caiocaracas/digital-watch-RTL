library ieee;
use ieee.std_logic_1164.all;

entity digital_watch is
  generic (
    ticks_per_sec : natural := 50_000_000;
    db_count_max  : natural := 1_000_000
  );
  port (
    clk_sys   : in std_logic;
    rst_sync  : in std_logic;
    btn_a_raw : in std_logic;
    btn_b_raw : in std_logic;
    beep_out  : out std_logic;
    hh_out    : out std_logic_vector(4 downto 0);
    mm_out    : out std_logic_vector(5 downto 0);
    ss_out    : out std_logic_vector(5 downto 0)
  );
end entity digital_watch;

architecture rtl of digital_watch is
  -- components
  component clk_div
    generic (ticks_per_sec : natural := 50_000_000);
    port (
      clk_sys  : in std_logic;
      rst_sync : in std_logic;
      tick_sec : out std_logic
    );
  end component;

  component btn_sync_db
    generic (db_count_max : natural := 1_000_000);
    port (
      clk_sys    : in std_logic;
      rst_sync   : in std_logic;
      btn_in_raw : in std_logic;
      btn_level  : out std_logic
    );
  end component;

  component edge_detect
    port (
      clk_sys   : in std_logic;
      rst_sync  : in std_logic;
      level_in  : in std_logic;
      pulse_out : out std_logic
    );
  end component;

  component mode_fsm
    port (
      clk_sys        : in std_logic;
      rst_sync       : in std_logic;
      btn_mode_pulse : in std_logic;
      btn_act_pulse  : in std_logic;
      inc_hour       : out std_logic;
      inc_min        : out std_logic;
      toggle_en      : out std_logic
    );
  end component;

  component alarm_regs
    port (
      clk_sys   : in std_logic;
      rst_sync  : in std_logic;
      inc_hour  : in std_logic;
      inc_min   : in std_logic;
      toggle_en : in std_logic;
      alrm_h    : out std_logic_vector(4 downto 0);
      alrm_m    : out std_logic_vector(5 downto 0);
      alrm_en   : out std_logic
    );
  end component;

  component time_core
    port (
      clk_sys     : in std_logic;
      rst_sync    : in std_logic;
      tick_sec    : in std_logic;
      btn_a_level : in std_logic;
      btn_b_level : in std_logic;
      hh          : out std_logic_vector(4 downto 0);
      mm          : out std_logic_vector(5 downto 0);
      ss          : out std_logic_vector(5 downto 0)
    );
  end component;

  component alarm_fsm
    generic (
      t_long  : natural := 5;
      t_short : natural := 2;
      t_gap   : natural := 1
    );
    port (
      clk_sys        : in std_logic;
      rst_sync       : in std_logic;
      tick_sec       : in std_logic;
      alarm_active_q : in std_logic;
      beep           : out std_logic
    );
  end component;

  -- sinais internos
  signal tick_sec : std_logic;

  signal btn_a_level, btn_b_level : std_logic;
  signal btn_a_pulse, btn_b_pulse : std_logic;
  signal btn_any_pulse            : std_logic;

  signal inc_hour, inc_min, toggle_en : std_logic;

  signal alrm_h  : std_logic_vector(4 downto 0);
  signal alrm_m  : std_logic_vector(5 downto 0);
  signal alrm_en : std_logic;

  signal hh : std_logic_vector(4 downto 0);
  signal mm : std_logic_vector(5 downto 0);
  signal ss : std_logic_vector(5 downto 0);

  signal alarm_match    : std_logic;
  signal alarm_active_q : std_logic := '0';
  signal alarm_active_d : std_logic;
begin
  -- divisor
  u_div : clk_div
  generic map(ticks_per_sec => ticks_per_sec)
  port map
  (
    clk_sys  => clk_sys,
    rst_sync => rst_sync,
    tick_sec => tick_sec
  );

  -- debounce/sync
  u_db_a : btn_sync_db
  generic map(db_count_max => db_count_max)
  port map
    (clk_sys, rst_sync, btn_a_raw, btn_a_level);

  u_db_b : btn_sync_db
  generic map(db_count_max => db_count_max)
  port map
    (clk_sys, rst_sync, btn_b_raw, btn_b_level);

  -- flanco 0→1
  u_ed_a : edge_detect
  port map
    (clk_sys, rst_sync, btn_a_level, btn_a_pulse);

  u_ed_b : edge_detect
  port map
    (clk_sys, rst_sync, btn_b_level, btn_b_pulse);

  btn_any_pulse <= btn_a_pulse or btn_b_pulse;

  -- ui
  u_mode : mode_fsm
  port map
  (
    clk_sys        => clk_sys,
    rst_sync       => rst_sync,
    btn_mode_pulse => btn_a_pulse,
    btn_act_pulse  => btn_b_pulse,
    inc_hour       => inc_hour,
    inc_min        => inc_min,
    toggle_en      => toggle_en
  );

  -- registros do alarme
  u_aregs : alarm_regs
  port map
  (
    clk_sys   => clk_sys,
    rst_sync  => rst_sync,
    inc_hour  => inc_hour,
    inc_min   => inc_min,
    toggle_en => toggle_en,
    alrm_h    => alrm_h,
    alrm_m    => alrm_m,
    alrm_en   => alrm_en
  );

  -- relógio
  u_time : time_core
  port map
  (
    clk_sys     => clk_sys,
    rst_sync    => rst_sync,
    tick_sec    => tick_sec,
    btn_a_level => btn_a_level,
    btn_b_level => btn_b_level,
    hh          => hh,
    mm          => mm,
    ss          => ss
  );

  alarm_match <= '1' when (hh = alrm_h and mm = alrm_m) else
    '0';

  alarm_ff : process (clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_sync = '1' then
        alarm_active_q <= '0';
      else
        alarm_active_q <= alarm_active_d;
      end if;
    end if;
  end process;

  alarm_comb : process (alarm_active_q, alarm_match, alrm_en, btn_any_pulse)
  begin
    alarm_active_d <= alarm_active_q;
    if btn_any_pulse = '1' then
      alarm_active_d <= '0';
    elsif (alarm_match = '1') and (alrm_en = '1') then
      alarm_active_d <= '1';
    end if;
  end process;

  -- padrão de beep
  u_alarm : alarm_fsm
  port map
  (
    clk_sys        => clk_sys,
    rst_sync       => rst_sync,
    tick_sec       => tick_sec,
    alarm_active_q => alarm_active_q,
    beep           => beep_out
  );

  -- saídas
  hh_out <= hh;
  mm_out <= mm;
  ss_out <= ss;
end architecture rtl;
