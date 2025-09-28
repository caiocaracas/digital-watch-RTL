# Digital Clock with Alarm (VHDL)

A compact 24‑hour digital clock with alarm in VHDL‑2008. Includes a self‑checking testbench and a simple path to synthesis (Vivado 2025.1).

## Features
- 24h time output: `hh:mm:ss`.
- Alarm pattern: 5s long beep + two 2s short beeps, looping until user action.
- Two buttons:
  - **Mode**: cycles through set hour → set minute → enable/disable alarm.
  - **Act**: increments selected field or toggles alarm enable.
- Button **positive‑edge detection without** using `rising_edge()` (explicit edge logic).
- Both buttons high simultaneously: reset to **12:00:00**.
- Generic `CLK_FREQ_HZ` (1–50 MHz). Testbench supports simulation acceleration via `SIM_ACCEL`.

## Repository Layout
```
src/    # synthesizable VHDL (VHDL‑2008)
tb/     # self‑checking testbenches (VUnit or plain GHDL)
sim/    # scripts, waves, logs
docs/   # statement and diagrams
constr/ # example XDC constraints
```

## Quickstart — Simulation

### Option A — GHDL + GTKWave
```bash
# analyze
ghdl -a --std=08 src/**/*.vhd tb/**/*.vhd
# elaborate (top TB is tb_clock_alarm)
ghdl -e --std=08 tb_clock_alarm
# run accelerated sim and dump wave
ghdl -r --std=08 tb_clock_alarm --stop-time=200ms --wave=sim/clock_alarm.ghw
gtkwave sim/clock_alarm.ghw &
```

### Option B — VUnit (optional)
```bash
python3 -m pip install vunit_hdl
python3 tb/run_vunit.py -v
```

## Synthesis (Vivado 2025.1)
- Top entity: `clock_alarm_top`
  - Ports: `clk_sys, rst_sync, btn_mode, btn_act : in std_logic`
  - `hh, mm, ss : out std_logic_vector; alarm_out : out std_logic`
- Example XDC:
```tcl
create_clock -name sys_clk -period 20.000 [get_ports clk_sys]
set_input_delay  -clock sys_clk 2.0  [get_ports {btn_mode btn_act}]
set_output_delay -clock sys_clk 2.0  [get_ports alarm_out]
```

## Design Notes
- FSM with **registered outputs** and clear synchronous reset.
- Two‑FF synchronizers + explicit edge detection for buttons.
- `src/` keeps synthesizable code only; non‑synth TB utilities live in `tb/`.

## Tests
- Second/minute/hour rollovers.
- Mode cycling and increment/toggle behavior.
- Alarm match and **5s + 2s + 2s** pattern looping.
- Stop on user action; double‑press reset to **12:00:00**.

## Requirements
- GHDL (or ModelSim/Questa), GTKWave; Python 3 + VUnit (optional).
- Xilinx Vivado 2025.1 for FPGA synthesis/implementation.
