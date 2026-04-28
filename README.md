# ELE432 HW2 - Multicycle RISC-V Controller

## What Was Done

A hierarchical SystemVerilog controller was implemented for the HW2 multicycle RISC-V controller task.

Implemented modules:

* `controller`
* `mainfsm`
* `aludec`
* `instrdec`

The controller was tested using the provided testbench and test vector file.

## Files

* `controller.sv`
* `controller_testbench.sv`
* `controller.tv`
* `run_controller.do`
* `screenshots/`

## How to Simulate

Run the following command in ModelSim/Questa:

`do run_controller.do`

The script compiles the design, launches the testbench, adds the relevant signals to the waveform window, and runs the simulation.

## Simulation Result

The simulation completed successfully.

`40 tests completed with 0 errors`

Simulation screenshots are included in the `screenshots/` folder.

## Notes

Two issues were noticed during debugging:

* The provided test vectors expect `ImmSrc = XX` for R-type instructions, so the implementation was adjusted accordingly.
* The `ALUControl` encoding expected by the test vector file differs from the encoding shown in the homework PDF table. The implementation follows the provided test vectors.

## Conclusion

The controller was implemented and verified successfully. It passes all 40 provided test vectors with 0 errors.

## Time Spent

**3 hours**
