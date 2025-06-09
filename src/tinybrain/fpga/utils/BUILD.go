package utils

import (
	"dbt-rules/RULES/hdl"
)

var ResetLib = hdl.Library{
	Srcs: ins(
		"reset.sv",
	),
}

var SyncLib = hdl.Library{
	Srcs: ins(
		"cdc_sync.sv",
	),
}

var PkgLib = hdl.Library{
	Srcs: ins(
		"utils_pkg.sv",
	),
}
