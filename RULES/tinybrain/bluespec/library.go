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
	Deps []Dep
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

func (l Library) topLevelSrcDir() core.OutPath {
	return l.intermediatesDir().WithSuffix("/top_level")
}

func (l Library) topLevelSrc() core.OutPath {
	return l.topLevelSrcDir().WithSuffix("/GeneratedLibraryTopLevel.bsv")
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

func (l Library) generateTopLevel(ctx core.Context, srcs []core.Path) {
	args := topLevelArgs{}
	for _, src := range srcs {
		base := filepath.Base(src.Absolute())
		name := strings.TrimSuffix(base, filepath.Ext(base))
		args.Srcs = append(args.Srcs, name)
	}

	data := executeTemplate(topLevelTemplate, &args)

	ctx.AddBuildStep(core.BuildStep{
		Out:  l.topLevelSrc(),
		Ins:  l.Srcs,
		Data: data,
	})
}

func (l Library) Build(ctx core.Context) {
	inputs := l.copySrcs(ctx)
	l.generateTopLevel(ctx, inputs)

	inputs = append(inputs, l.topLevelSrc())

	bluespecDir := l.bluespecDir()
	srcsDir := l.srcsDir()
	outputs := l.compilerOuts()
	topLevelOut := l.topLevelOut()

	importedPaths := []string{
		"%/Libraries",
		srcsDir.Absolute(),
	}
	for _, dep := range l.Deps {
		otherLib := dep.BluespecLibrary()
		importedPaths = append(importedPaths, otherLib.bluespecDir().Absolute())
		for _, lib := range otherLib.compilerOuts() {
			inputs = append(inputs, lib)
		}
	}

	ctx.AddBuildStep(core.BuildStep{
		Outs: outputs,
		Ins:  inputs,
		Cmd:  fmt.Sprintf("rm -rf %q && mkdir -p %q && bsc --bdir %q -p %q -u %q && rm -rf %q", bluespecDir, bluespecDir, bluespecDir, strings.Join(importedPaths, ":"), l.topLevelSrc(), topLevelOut),
	})
}

func (l Library) BluespecLibrary() Library {
	return l
}
