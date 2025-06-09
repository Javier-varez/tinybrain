package fifo

import (
	"dbt-rules/RULES/hdl"
)

var Lib = hdl.Library{
	Srcs: ins(
		"fifo.sv",
	),
}
