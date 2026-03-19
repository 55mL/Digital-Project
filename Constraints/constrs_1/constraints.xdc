# Nexys A7 (100T) constraints for countdown_7seg.vhd
# Map board signals to VHDL ports. User LEDs on the Nexys A7 are single-color;
# we'll map the board's 16 user LEDs to the VHDL `led_r` bus. `led_g` and `led_b`
# are left as placeholders (commented) — if you want RGB behavior, provide the
# appropriate PACKAGE_PINs to map them as well.

# Clock and clock constraint (Nexys A7 100 MHz oscillator)
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {clk}];
create_clock -add -name sys_clk -period 10.00 -waveform {0 5} [get_ports {clk}];

# Buttons (board user buttons / reset / start)
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports {reset}];
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {start}];

# 7-segment segment pins (seg[6]..seg[0])
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {seg[6]}];
set_property -dict {PACKAGE_PIN R10 IOSTANDARD LVCMOS33} [get_ports {seg[5]}];
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {seg[4]}];
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports {seg[3]}];
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {seg[2]}];
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {seg[1]}];
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {seg[0]}];

# Decimal point pin (seg DP). If your 7-seg module uses a separate DP pin, set PACKAGE_PIN below and uncomment.
# Replace <DP_PIN> with the actual board pin and remove the leading '# ' to enable.
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {seg[7]}];

# 7-seg digit anodes (an[0]..an[7]) - active low
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {an[0]}];
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {an[1]}];
set_property -dict {PACKAGE_PIN T9  IOSTANDARD LVCMOS33} [get_ports {an[2]}];
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {an[3]}];
# If your board exposes additional anode pins for digits 4..7, provide them here.
# Replace <ANx_PIN> with the actual board pins and uncomment the lines to enable.
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {an[4]}];
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {an[5]}];
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {an[6]}];
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {an[7]}];

# Map Nexys A7 user LEDs to led_r[0..15]
# (replaces previous single `led` bus mapping with the VHDL `led_r` bus)
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {led_r[0]}];
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {led_r[1]}];
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {led_r[2]}];
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {led_r[3]}];
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {led_r[4]}];
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led_r[5]}];
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {led_r[6]}];
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {led_r[7]}];
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led_r[8]}];
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {led_r[9]}];
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {led_r[10]}];
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {led_r[11]}];
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {led_r[12]}];
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {led_r[13]}];
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {led_r[14]}];
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {led_r[15]}];

# Placeholders for led_g and led_b (if you add external RGB LEDs or want to
# repurpose board pins). To enable, replace <PIN> with the correct PACKAGE_PIN
# and uncomment the lines below.
# set_property -dict {PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33} [get_ports {led_g[0]}];
# ...
# set_property -dict {PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33} [get_ports {led_g[15]}];
#
# set_property -dict {PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33} [get_ports {led_b[0]}];
# ...
# set_property -dict {PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33} [get_ports {led_b[15]}];

# Notes:
# - The Nexys A7 on-board user LEDs are single-color; mapping them to led_r is
#   a convenient way to reuse the existing 16 LED pins in your VHDL design.
# - If you later want physical RGB LEDs, provide pin mappings for led_g and
#   led_b or reassign FPGA pins as required by your hardware.
