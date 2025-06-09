package test

import (
	"dbt-rules/RULES/hdl"

	"tinybrain/fpga/uart"
)

var Test = hdl.Simulation{
	Name: "UartTestBench",
	Top:  "uart_tb",
	Srcs: ins("uart_tb.sv"),
	Libs: []string{"xil_defaultlib"},
	Ips: []hdl.Ip{
		uart.Lib,
	},
}
