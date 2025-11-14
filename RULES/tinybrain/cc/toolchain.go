package cc

import (
	dbt_cc "dbt-rules/RULES/cc"
	"dbt-rules/RULES/core"
)

var buildType = core.StringFlag{
	Name:          "build-type",
	Description:   "The C++ build type to execute",
	AllowedValues: []string{"debug", "release"},
	DefaultFn:     func() string { return "debug" },
}.Register()

type ArmGcc struct {
	WithSemihosting bool
}

func (t *ArmGcc) Name() string {
	return "arm-embedded"
}

func (t *ArmGcc) CCompiler() string {
	return "arm-none-eabi-gcc"
}

func (t *ArmGcc) CxxCompiler() string {
	return "arm-none-eabi-g++"
}

func (t *ArmGcc) Assembler() string {
	return "arm-none-eabi-as"
}

func (t *ArmGcc) Archiver() string {
	return "arm-none-eabi-ar"
}

func (t *ArmGcc) Link() string {
	return "arm-none-eabi-g++"
}

func (t *ArmGcc) ObjcopyCommand() string {
	return "arm-none-eabi-objcopy"
}

func (t *ArmGcc) commonCFlags() []string {
	flags := []string{
		"-mcpu=cortex-m7",
		"-mthumb",
		"-Wl,--gc-sections",
		"-Wall",
		"-Wextra",
		"-Werror",
	}

	switch buildType.Value() {
	case "debug":
		flags = append(flags, "-g3")
	case "release":
		flags = append(flags, "-g3", "-Os")
	}

	return flags
}

func (t *ArmGcc) CFlags() []string {
	return append([]string{"--std=c23"}, t.commonCFlags()...)
}

func (t *ArmGcc) CxxFlags() []string {
	return append([]string{"-fno-exceptions", "-fno-rtti", "--std=gnu++23"}, t.commonCFlags()...)
}

func (t *ArmGcc) AsFlags() []string {
	flags := []string{"-mcpu=cortex-m7", "-mthumb"}

	switch buildType.Value() {
	case "debug":
		flags = append(flags, "-g3")
	case "release":
		flags = append(flags, "-g3")
	}

	return flags
}

func (t *ArmGcc) LdFlags() []string {
	flags := t.CxxFlags()
	if t.WithSemihosting {
		flags = append(flags, "--specs=rdimon.specs")
	} else {
		flags = append(flags, "--specs=nosys.specs")
	}
	flags = append(flags, "--specs=nano.specs")
	return flags
}

func (t *ArmGcc) StdDeps() []dbt_cc.Dep {
	return []dbt_cc.Dep{}
}

func (t *ArmGcc) Script() core.Path {
	return nil
}

func (t *ArmGcc) LinkerFlavor() dbt_cc.LinkerFlavor {
	return dbt_cc.Gcc
}
