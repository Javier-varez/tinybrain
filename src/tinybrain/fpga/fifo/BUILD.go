package fifo

import (
	"dbt-rules/RULES/hdl"

	"tinybrain/fpga/utils"
)

var Lib = hdl.Library{
	Srcs: ins(
		"fifo.sv",
		"cdc_fifo.sv",
	),
	IpDeps: []hdl.Ip{
		utils.PkgLib,
		utils.SyncLib,
	},
}
