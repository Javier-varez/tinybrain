package test

import (
	"dbt-rules/RULES/hdl"

	"tinybrain/fpga/fmc"
)

var Test = hdl.Simulation{
	Name: "FmcTestBench",
	Top:  "fmc_tb",
	Srcs: ins("fmc_tb.sv"),
	Libs: []string{"xil_defaultlib"},
	Ips: []hdl.Ip{
		fmc.Lib,
	},
}
