package fmc

import (
	"dbt-rules/RULES/hdl"
)

var Lib = hdl.Library{
	Srcs: ins(
		"fmc.sv",
		"fmc_data_bus.sv",
	),
}
