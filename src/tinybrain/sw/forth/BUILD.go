package forth

import (
	"tinybrain/RULES/cc"
)

var ForthInterpreter = cc.Binary{
	Out:          out("forth-fw"),
	Srcs:         ins("main.cc", "startup.cc"),
	LinkerScript: in("cortex-m.ld"),
}
