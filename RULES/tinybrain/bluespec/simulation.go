package bluespec

import (
	"fmt"
	"path/filepath"
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

	// Resources required during simulation
	Resources []core.Path
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

func (b Bluesim) infoDir() core.OutPath {
	return b.intermediatesDir().WithSuffix("/info")
}

func (b Bluesim) resourcesDir() core.OutPath {
	return b.Out.WithSuffix("_resources")
}

func (b Bluesim) copiedResources() []core.OutPath {
	resources := []core.OutPath{}

	for _, src := range b.Resources {
		target := b.resourcesDir().WithSuffix(fmt.Sprintf("/%s", filepath.Base(src.String())))
		resources = append(resources, target)
	}
	return resources
}

func (b Bluesim) Build(ctx core.Context) {
	importPaths := []string{
		"%/Libraries",
	}
	inputs := []core.Path{b.TestBench}

	if len(b.Resources) != 0 {
		copiedResources := b.copiedResources()
		script := executeTemplate(copySrcsTemplate, &copySrcsArgs{
			TargetDir: b.resourcesDir(),
			Srcs:      b.Resources,
		})

		ctx.AddBuildStep(core.BuildStep{
			Outs:   copiedResources,
			Ins:    b.Resources,
			Script: script,
		})

		inputs = append(inputs, asInputs(copiedResources)...)
	}

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

	cmd := fmt.Sprintf("rm -rf %q %q %q %q", b.simDir().Absolute(), b.bluespecDir().Absolute(), b.infoDir().Absolute(), b.Out.Absolute())
	cmd = fmt.Sprintf("%s && mkdir -p %q %q %q", cmd, b.simDir().Absolute(), b.bluespecDir().Absolute(), b.infoDir().Absolute())
	cmd = fmt.Sprintf("%s && bsc -quiet --sim %s --simdir %q --bdir %q --info-dir %q -p %q -g %q %q", cmd, flags, b.simDir(), b.bluespecDir(), b.infoDir(), strings.Join(importPaths, ":"), b.TopModule, b.TestBench.Absolute())
	cmd = fmt.Sprintf("%s && bsc -quiet -e %q -sim -o %q %s --simdir %q --bdir %q --info-dir %q -p %q -g %q", cmd, b.TopModule, b.Out.Absolute(), flags, b.simDir(), b.bluespecDir(), b.infoDir(), strings.Join(importPaths, ":"), b.TopModule)

	ctx.AddBuildStep(core.BuildStep{
		Out: b.Out,
		Ins: inputs,
		Cmd: cmd,
	})
}

func (b Bluesim) Test(args []string) string {
	return fmt.Sprintf("cd %q && %q %s", b.resourcesDir(), b.Out.Absolute(), strings.Join(args, " "))
}
