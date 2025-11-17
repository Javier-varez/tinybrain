package cc

import (
	"fmt"
	"slices"
	"strings"

	"dbt-rules/RULES/cc"
	dbt_cc "dbt-rules/RULES/cc"
	"dbt-rules/RULES/core"
)

func init() {
	core.AssertIsBuildableTarget(&Binary{})
	core.AssertIsRunnableTarget(&Binary{})

	cc.RegisterToolchainAsDefault(&ArmGcc{})
}

type Binary struct {
	Out          core.OutPath
	Srcs         []core.Path
	Deps         []cc.Dep
	CxxFlags     []string
	AsFlags      []string
	LinkerFlags  []string
	LinkerScript core.Path
	Toolchain    cc.Toolchain

	inner *dbt_cc.Binary
}

func (b *Binary) getInner() *dbt_cc.Binary {
	if b.inner != nil {
		return b.inner
	}

	b.inner = &dbt_cc.Binary{
		Out:         b.Out,
		Srcs:        b.Srcs,
		Deps:        b.Deps,
		CxxFlags:    b.CxxFlags,
		AsFlags:     b.AsFlags,
		Script:      b.LinkerScript,
		LinkerFlags: b.LinkerFlags,
		Toolchain:   b.Toolchain,
	}
	return b.inner
}

func (b *Binary) Build(ctx core.Context) {
	b.getInner().Build(ctx)
}

func (b *Binary) Run(args []string) string {
	qemuArgs := []string{}
	if slices.Contains(args, "debug") {
		qemuArgs = append(qemuArgs, "-S", "-s")
	}

	compiledElf := b.getInner().Out
	return fmt.Sprintf("qemu-system-arm -cpu cortex-m7 -machine mps2-an500 -kernel %q -display none -semihosting-config enable=true,chardev=cid -chardev stdio,id=cid %s", compiledElf.Absolute(), strings.Join(qemuArgs, " "))
}
