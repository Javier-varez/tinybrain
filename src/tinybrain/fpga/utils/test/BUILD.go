package test

import (
	"dbt-rules/RULES/hdl"

	"tinybrain/fpga/utils"
)

var Test = hdl.Simulation{
	Name: "SyncTestBench",
	Top:  "cdc_sync_tb",
	Srcs: ins("cdc_sync_tb.sv"),
	Libs: []string{"xil_defaultlib"},
	Ips: []hdl.Ip{
		utils.SyncLib,
	},
}
