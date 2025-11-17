package forth

import (
	"tinybrain/RULES/cc"
)

var ForthInterpreter = cc.Binary{
	Out:          out("forth-fw"),
	Srcs:         ins("startup.cc", "semihosting.S", "forth.S", "forth.cc"),
	LinkerScript: in("cortex-m.ld"),
}
