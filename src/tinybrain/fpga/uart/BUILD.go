package uart

import (
	"dbt-rules/RULES/hdl"
)

var Lib = hdl.Library{
	Srcs: ins(
		"uart_tx.sv",
	),
}
