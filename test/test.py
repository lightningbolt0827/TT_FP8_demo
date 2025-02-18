# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 ns (100 MHz)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.ui_in.value = 0x00
    dut.uio_in.value = 0x00

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)
    
    dut.ui_in.value = 0x3E
    dut.uio_in.value = 0x42

    await ClockCycles(dut.clk, 12)
    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.uo_out.value == 0xDA

    await ClockCycles(dut.clk, 1)
    
    assert dut.uo_out.value == 0x44
    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
