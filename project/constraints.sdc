# 50 MHz board clock
create_clock -name MAX10_CLK1_50 -period 20.0 [get_ports MAX10_CLK1_50]

# multicycle path for ALU divider
# Extra cycles for division: SETUP_RAM, WAIT_RAM_ALU, WAIT_ALU_DIV.
set_multicycle_path 3 -setup -through [get_nets *divider*]

set_multicycle_path 2 -hold -through [get_nets *divider*]