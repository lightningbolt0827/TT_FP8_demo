# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer 

@cocotb.test()
async def test_project(dut):
    
    dut._log.info("Start")
    # Manually set clk to 0 before starting the clock
    dut.clk.value = 0  # Ensure initial state is LOW
    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(10, units="ns")
    # Set the clock period to 10 ns (100 MHz)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())


    #await ClockCycles(dut.clk, 1)
    await Timer(10, units="ns")
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.ui_in.value = 0xDF
    dut.uio_in.value = 0x3D

    # Wait for one clock cycle to see the output values
    #await ClockCycles(dut.clk, 1)
    await Timer(20, units="ns")
    dut.ui_in.value = 0x44
    dut.uio_in.value = 0x48

    #await ClockCycles(dut.clk, 11)
    await Timer(200, units="ns")
    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.uo_out.value == 0x2C

    #await ClockCycles(dut.clk, 1)
    await Timer(20, units="ns")
    assert dut.uo_out.value == 0x51
    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
