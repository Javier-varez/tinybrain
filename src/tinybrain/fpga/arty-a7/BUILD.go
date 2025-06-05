package arty_a7

import (
	"dbt-rules/RULES/hdl"

	"tinybrain/fpga/fmc"
	"tinybrain/fpga/utils"
)

var Fpga = hdl.Fpga{
	Name: "ArtyNorthbridge",
	Top:  "top",
	Part: "xc7a100tcsg324-1",
	Library: hdl.Library{
		Srcs: ins(
			"top.sv",
			"arty.xdc",
		),
		IpDeps: []hdl.Ip{
			fmc.Lib,
			utils.ResetLib,
		},
	},
}
