package cpu

import (
	"tinybrain/RULES/bluespec"
)

var Lib = bluespec.Library{
	Out: out("fmc"),
	Srcs: ins(
		"Types.bsv",
		"Alu.bsv",
		"BranchAlu.bsv",
		"CoreMemory.bsv",
		"Cpu.bsv",
		"Decoder.bsv",
		"RegisterFile.bsv",
	),
}
