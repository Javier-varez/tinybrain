package sw

import (
	"dbt-rules/RULES/rust"
)

var TinybrainFw = rust.Binary{
	Out:     out("tinybrain-fw"),
	Package: in("tinybrain-fw"),
}
