package test

import (
	"tinybrain/RULES/bluespec"

	"tinybrain/cpu"
	"tinybrain/cpu/test/resources"
)

var flags = []string{
	"-keep-fires",
	"-aggressive-conditions",
	"-check-assert",
}

var AluTests = bluespec.Bluesim{
	Out:       out("AluTests"),
	TestBench: in("AluTestBench.bsv"),
	TopModule: "mkTestBench",
	Flags:     flags,
	Deps: []bluespec.Dep{
		cpu.Lib,
	},
}

var CoreMemoryTests = bluespec.Bluesim{
	Out:       out("CoreMemoryTests"),
	TestBench: in("CoreMemoryTestBench.bsv"),
	TopModule: "mkTestBench",
	Flags:     flags,
	Deps: []bluespec.Dep{
		cpu.Lib,
	},
	Resources: resources.Resources,
}

var DecoderTests = bluespec.Bluesim{
	Out:       out("DecoderTests"),
	TestBench: in("DecoderTestBench.bsv"),
	TopModule: "mkTestBench",
	Flags:     flags,
	Deps: []bluespec.Dep{
		cpu.Lib,
	},
}

var RegisterFileTests = bluespec.Bluesim{
	Out:       out("RegisterFileTests"),
	TestBench: in("RegisterFileTestBench.bsv"),
	TopModule: "mkTestBench",
	Flags:     flags,
	Deps: []bluespec.Dep{
		cpu.Lib,
	},
}

var CpuTests = bluespec.Bluesim{
	Out:       out("CpuTests"),
	TestBench: in("TestBench.bsv"),
	TopModule: "mkTestBench",
	Flags:     flags,
	Deps: []bluespec.Dep{
		cpu.Lib,
	},
	Resources: resources.Resources,
}
