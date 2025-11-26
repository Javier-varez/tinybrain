package forth

import (
	"dbt-rules/RULES/cc"

	"tinybrain/RULES/blob"
	tbcc "tinybrain/RULES/cc"
)

var forthSources = blob.Blob{
	Out:       out("forth_sources"),
	Src:       in("forth.f"),
	Name:      "forth",
	Namespace: "tinybrain::sw::forth",
}

var ForthInterpreter = tbcc.Binary{
	Out:          out("forth-fw"),
	Srcs:         ins("startup.cc", "semihosting.S", "forth.S", "forth.cc", "debug.cc", "main.cc", "embedded.cc", "io.cc"),
	LinkerScript: in("cortex-m.ld"),
	Deps: []cc.Dep{
		&forthSources,
	},
}
