package test

import (
	"dbt-rules/RULES/hdl"

	"tinybrain/fpga/fifo"
)

var Test = hdl.Simulation{
	Name: "FifoTestBench",
	Top:  "fifo_tb",
	Srcs: ins("fifo_tb.sv"),
	Libs: []string{"xil_defaultlib"},
	Ips: []hdl.Ip{
		fifo.Lib,
	},
}
