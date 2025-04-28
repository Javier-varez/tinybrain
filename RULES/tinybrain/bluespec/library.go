package bluespec

import (
	"fmt"
	"log"
	"path/filepath"
	"strings"
	"text/template"

	"dbt-rules/RULES/core"
)

func init() {
	core.AssertIsBuildableTarget(&Library{})
}

type Library struct {
	Out  core.OutPath
	Srcs []core.Path
}

var copySrcsTemplate = template.Must(template.New("Script").Parse(`#!/bin/bash -e
{{ $targetDir := .TargetDir }}
rm -rf "{{ $targetDir }}"
mkdir -p "{{ $targetDir }}"
{{ range .Srcs }}cp "{{ . }}" "{{ $targetDir }}"{{ end }}
`))

type copySrcsArgs struct {
	TargetDir core.OutPath
	Srcs      []core.Path
}

func asInputs(outPaths []core.OutPath) []core.Path {
	paths := []core.Path{}
	for _, path := range outPaths {
		paths = append(paths, path)
	}
	return paths
}

func executeTemplate(t *template.Template, data any) string {
	templateStrBuffer := strings.Builder{}
	if err := t.Execute(&templateStrBuffer, data); err != nil {
		log.Fatalf("Unable to template copySrcsTemplate: %s", err)
	}
	return templateStrBuffer.String()
}

func (l Library) intermediatesDir() core.OutPath {
	return l.Out.WithSuffix("_intermediates")
}

func (l Library) srcsDir() core.OutPath {
	return l.intermediatesDir().WithSuffix("/srcs")
}

func (l Library) bluespecDir() core.OutPath {
	return l.Out
}

func (l Library) topLevelOut() core.OutPath {
	return l.Out.WithSuffix("/GeneratedLibraryTopLevel.bo")
}

func (l *Library) copiedSrcs() []core.OutPath {
	copiedSrcs := []core.OutPath{}

	for _, src := range l.Srcs {
		target := l.srcsDir().WithSuffix(fmt.Sprintf("/%s", filepath.Base(src.String())))
		copiedSrcs = append(copiedSrcs, target)
	}
	return copiedSrcs
}

func (l *Library) compilerOuts() []core.OutPath {
	outs := []core.OutPath{}

	for _, src := range l.Srcs {
		base := filepath.Base(src.String())
		name := strings.TrimSuffix(base, filepath.Ext(base))
		outs = append(outs, l.bluespecDir().WithSuffix(fmt.Sprintf("/%s.bo", name)))
	}
	return outs
}

func (l Library) copySrcs(ctx core.Context) []core.Path {
	copiedSrcs := l.copiedSrcs()
	script := executeTemplate(copySrcsTemplate, &copySrcsArgs{
		TargetDir: l.srcsDir(),
		Srcs:      l.Srcs,
	})

	ctx.AddBuildStep(core.BuildStep{
		Outs:   copiedSrcs,
		Ins:    l.Srcs,
		Script: script,
	})

	return asInputs(copiedSrcs)
}

var topLevelTemplate = template.Must(template.New("Script").Parse(`package GeneratedLibraryTopLevel;

{{ range .Srcs }}
import {{ . }}::*;
{{ end }}

endpackage
`))

type topLevelArgs struct {
	Srcs []string
}

func (l Library) generateTopLevel(ctx core.Context, srcs []core.Path) core.OutPath {
	args := topLevelArgs{}
	for _, src := range srcs {
		base := filepath.Base(src.Absolute())
		name := strings.TrimSuffix(base, filepath.Ext(base))
		args.Srcs = append(args.Srcs, name)
	}

	data := executeTemplate(topLevelTemplate, &args)
	topLevel := l.srcsDir().WithSuffix("/GeneratedLibraryTopLevel.bsv")

	ctx.AddBuildStep(core.BuildStep{
		Out:  topLevel,
		Ins:  l.Srcs,
		Data: data,
	})
	return topLevel
}

func (l Library) Build(ctx core.Context) {
	inputs := l.copySrcs(ctx)
	topLevelSrc := l.generateTopLevel(ctx, inputs)

	inputs = append(inputs, topLevelSrc)

	bluespecDir := l.bluespecDir()
	srcsDir := l.srcsDir()
	outputs := l.compilerOuts()
	topLevelOut := l.topLevelOut()

	ctx.AddBuildStep(core.BuildStep{
		Outs: outputs,
		Ins:  inputs,
		Cmd:  fmt.Sprintf("rm -rf %q && mkdir -p %q && bsc --bdir %q -p %q:%%/Libraries -u %q && rm -rf %q", bluespecDir, bluespecDir, bluespecDir, srcsDir, topLevelSrc, topLevelOut),
	})
}
