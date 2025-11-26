package blob

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"
	"unicode"

	"dbt-rules/RULES/cc"
	"dbt-rules/RULES/core"
)

func init() {
	core.AssertIsBuildableTarget(&Blob{})
}

func namespaceToPath(s string) string {
	return strings.Replace(s, "::", "/", -1)
}

func camelCaseToSnakeCase(s string) string {
	result := []rune{}
	for _, e := range s {
		if unicode.IsUpper(e) {
			result = append(result, '_', unicode.ToLower(e))
		} else {
			result = append(result, e)
		}
	}
	return string(result)
}

type blobArgs struct {
	UsrHeader string
	XxdHeader string
	Namespace string
	Name      string
}

var sourceTemplate *template.Template = template.Must(template.New("SourceTemplate").Parse(`
#include <span>
#include <cstdint>

#include <{{ .UsrHeader }}>

namespace {{ .Namespace }} {

namespace {
#include <{{ .XxdHeader }}>
}

std::span<const uint8_t> {{ .Name }}Blob() noexcept{
	return std::span<const uint8_t>{blob, blob_len};
}

} // namespace {{ .Namespace }}
`))

var headerTemplate *template.Template = template.Must(template.New("HeaderTemplate").Parse(`
#pragma once

#include <span>
#include <cstdint>

namespace {{ .Namespace }} {

/**
 * \brief Returns the data inside the blob, which has static storage duration.
 */
[[nodiscard]] std::span<const uint8_t> {{ .Name }}Blob() noexcept;

} // namespace {{ .Namespace }}
`))

func generateTemplateRule(ctx core.Context, out core.OutPath, tmpl *template.Template, data any, additionalDeps []core.Path) {
	templateOutput := bytes.NewBufferString("")
	err := tmpl.Execute(templateOutput, data)
	if err == nil {
		ctx.AddBuildStep(core.BuildStep{
			Out:  out,
			Data: templateOutput.String(),
			Ins:  additionalDeps,
		})
	} else {
		ctx.AddBuildStep(core.BuildStep{
			Out: out,
			Cmd: `echo "Error generating template" && false`,
			Ins: additionalDeps,
		})
	}
}

type Blob struct {
	Out       core.OutPath // Output path of the blob
	Src       core.Path    // Source path of the blob
	Name      string       // Name of the blob, used to generate the array name
	Namespace string       // Namespace where to place the code
}

func (b *Blob) xxdFile() core.OutPath {
	return b.Out.WithSuffix(".xxd.h")
}

func (b *Blob) sourceFile() core.OutPath {
	return b.Out.WithSuffix(".cc")
}

func (b *Blob) headerFile() core.OutPath {
	return b.Out.WithSuffix(fmt.Sprintf(".includes/%s/%s_blob.hh", namespaceToPath(b.Namespace), camelCaseToSnakeCase(b.Name)))
}

func (b *Blob) Build(ctx core.Context) {
	ctx.AddBuildStep(core.BuildStep{
		Out: b.xxdFile(),
		In:  b.Src,
		Cmd: "xxd -i -n blob $in > $out",
	})

	args := blobArgs{
		UsrHeader: b.headerFile().Absolute(),
		XxdHeader: b.xxdFile().Absolute(),
		Name:      b.Name,
		Namespace: b.Namespace,
	}

	generateTemplateRule(ctx, b.sourceFile(), sourceTemplate, &args, []core.Path{b.headerFile(), b.xxdFile()})
	generateTemplateRule(ctx, b.headerFile(), headerTemplate, &args, nil)
}

func (b *Blob) CcLibrary(toolchain cc.Toolchain) cc.Library {
	return cc.Library{
		Out:           b.Out,
		GeneratedSrcs: []core.Path{b.sourceFile()},
		Includes:      []core.Path{b.Out.WithSuffix(".includes")},
	}
}
