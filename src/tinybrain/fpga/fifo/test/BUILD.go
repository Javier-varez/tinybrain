package test

import (
	"dbt-rules/RULES/hdl"

	"tinybrain/fpga/fifo"
)

var FifoTest = hdl.Simulation{
	Name: "FifoTestBench",
	Top:  "fifo_tb",
	Srcs: ins("fifo_tb.sv"),
	Libs: []string{"xil_defaultlib"},
	Ips: []hdl.Ip{
		fifo.Lib,
	},
}

var CdcFifoTest = hdl.Simulation{
	Name: "CdcFifoTestBench",
	Top:  "cdc_fifo_tb",
	Srcs: ins("cdc_fifo_tb.sv"),
	Libs: []string{"xil_defaultlib"},
	Ips: []hdl.Ip{
		fifo.Lib,
	},
}
