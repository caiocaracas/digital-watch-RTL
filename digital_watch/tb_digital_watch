library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_digital_watch is end entity;

architecture sim of tb_digital_watch is
  component digital_watch
    generic (
      ticks_per_sec : natural := 1;   -- 1 ciclo = 1 s lógico
      db_count_max  : natural := 2
    );
    port (
      clk_sys   : in  std_logic;
      rst_sync  : in  std_logic;
      btn_a_raw : in  std_logic;
      btn_b_raw : in  std_logic;
      beep_out  : out std_logic;
      hh_out    : out std_logic_vector(4 downto 0);
      mm_out    : out std_logic_vector(5 downto 0);
      ss_out    : out std_logic_vector(5 downto 0)
    );
  end component;

  constant T : time := 10 ns;

  signal clk_sys   : std_logic := '0';
  signal rst_sync  : std_logic := '1';
  signal btn_a_raw : std_logic := '0';
  signal btn_b_raw : std_logic := '0';
  signal beep_out  : std_logic;
  signal hh        : std_logic_vector(4 downto 0);
  signal mm        : std_logic_vector(5 downto 0);
  signal ss        : std_logic_vector(5 downto 0);

  -- utilitário
  procedure wait_cycles(n : natural) is
  begin
    for i in 1 to n loop
      wait for T;
    end loop;
  end procedure;

begin
  -- clock
  clk_proc : process
  begin
    clk_sys <= '0'; wait for T/2;
    clk_sys <= '1'; wait for T/2;
  end process;

  -- dut
  dut: digital_watch
    generic map (ticks_per_sec => 1, db_count_max => 2)
    port map (
      clk_sys   => clk_sys,
      rst_sync  => rst_sync,
      btn_a_raw => btn_a_raw,
      btn_b_raw => btn_b_raw,
      beep_out  => beep_out,
      hh_out    => hh,
      mm_out    => mm,
      ss_out    => ss
    );

  stim : process
  begin
    -- reset global
    wait_cycles(10);
    rst_sync <= '0';

    -- reset especial: ambos botões pressionados
    btn_a_raw <= '1'; btn_b_raw <= '1'; wait_cycles(10);
    btn_a_raw <= '0'; btn_b_raw <= '0'; wait_cycles(10);

    -- espera alguns segundos
    wait_cycles(50);

    -- programar alarme simples:
    -- 1) entra em S_M
    btn_a_raw <= '1'; wait_cycles(5); btn_a_raw <= '0'; wait_cycles(5);
    -- 2) incrementa minutos +1
    btn_b_raw <= '1'; wait_cycles(5); btn_b_raw <= '0'; wait_cycles(5);
    -- 3) entra em S_EN
    btn_a_raw <= '1'; wait_cycles(5); btn_a_raw <= '0'; wait_cycles(5);
    -- 4) habilita alarme
    btn_b_raw <= '1'; wait_cycles(5); btn_b_raw <= '0'; wait_cycles(5);
    -- 5) volta para S_H
    btn_a_raw <= '1'; wait_cycles(5); btn_a_raw <= '0'; wait_cycles(5);

    -- espera virar minuto e beep começa
    wait_cycles(70);

    -- beep ativo por alguns ciclos
    wait_cycles(200);

    -- cancelar alarme
    btn_b_raw <= '1'; wait_cycles(5); btn_b_raw <= '0'; wait_cycles(20);

    wait for 200 ns;
    assert false report "tb_digital_watch finalizado" severity note;
    wait;
  end process;
end architecture sim;
