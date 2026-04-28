# Clean previous work library
if {[file exists work]} {
    vdel -lib work -all
}

# Create work library
vlib work
vmap work work

# Compile files
vlog -sv controller.sv
vlog -sv controller_testbench.sv

# Start simulation
vsim -voptargs=+acc work.testbench

add wave *

# Run all tests
run -all
