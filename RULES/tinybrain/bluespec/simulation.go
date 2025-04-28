package bluespec

import (
	"fmt"
	"strings"

	"dbt-rules/RULES/core"
)

func init() {
	core.AssertIsBuildableTarget(&Bluesim{})
	core.AssertIsTestableTarget(&Bluesim{})
}

type Bluesim struct {
	Out       core.OutPath
	TestBench core.Path
	TopModule string
	Deps      []Dep
	Flags     []string
}

func (b Bluesim) intermediatesDir() core.OutPath {
	return b.Out.WithSuffix("_intermediates")
}

func (b Bluesim) bluespecDir() core.OutPath {
	return b.intermediatesDir().WithSuffix("/bluespec")
}

func (b Bluesim) simDir() core.OutPath {
	return b.intermediatesDir().WithSuffix("/simulation")
}

func (b Bluesim) Build(ctx core.Context) {
	importPaths := []string{
		"%/Libraries",
	}
	inputs := []core.Path{}

	allDeps := []Library{}
	for _, dep := range b.Deps {
		lib := dep.BluespecLibrary()
		allDeps = append(allDeps, lib)
		allDeps = append(allDeps, lib.allDeps()...)
	}

	for _, dep := range allDeps {
		importPaths = append(importPaths, dep.bluespecDir().Absolute())
		for _, out := range dep.compilerOuts() {
			inputs = append(inputs, out)
		}
	}

	flags := strings.Join(b.Flags, " ")

	cmd := fmt.Sprintf("rm -rf %q %q %q", b.simDir().Absolute(), b.bluespecDir().Absolute(), b.Out.Absolute())
	cmd = fmt.Sprintf("%s && mkdir -p %q %q", cmd, b.simDir().Absolute(), b.bluespecDir().Absolute())
	cmd = fmt.Sprintf("%s && bsc -quiet --sim %s --simdir %q --bdir %q -p %q -g %q %q", cmd, flags, b.simDir(), b.bluespecDir(), strings.Join(importPaths, ":"), b.TopModule, b.TestBench.Absolute())
	cmd = fmt.Sprintf("%s && bsc -quiet -e %q -sim -o %q %s --simdir %q --bdir %q -p %q -g %q", cmd, b.TopModule, b.Out.Absolute(), flags, b.simDir(), b.bluespecDir(), strings.Join(importPaths, ":"), b.TopModule)

	ctx.AddBuildStep(core.BuildStep{
		Out: b.Out,
		Ins: inputs,
		Cmd: cmd,
	})
}

func (b Bluesim) Test(args []string) string {
	return fmt.Sprintf("%q %s", b.Out.Absolute(), strings.Join(args, " "))
}
