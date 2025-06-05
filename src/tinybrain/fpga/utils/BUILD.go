package utils

import (
	"dbt-rules/RULES/hdl"
)

var ResetLib = hdl.Library{
	Srcs: ins(
		"reset.sv",
	),
}
