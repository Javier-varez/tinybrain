package blob

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"dbt-rules/RULES/cc"
	"dbt-rules/RULES/core"
)

func init() {
	core.AssertIsBuildableTarget(&Blob{})
}

func namespaceToPath(s string) string {
	return strings.Replace(s, "::", "/", -1)
}

func namespaceToSnake(s string) string {
	return strings.Replace(s, "::", "_", -1)
}

type blobArgs struct {
	BinFilePath    string
	Namespace      string
	NamespaceSnake string
	Name           string
}

var sourceTemplate *template.Template = template.Must(template.New("SourceTemplate").Parse(`
.syntax unified

	.section .rodata
	.global blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob
	.type blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob, "object"
blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob:
	.incbin "{{ .BinFilePath }}"
blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob_end:

	.align 2
	.global blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob_length
	.type blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob_length, "object"
blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob_length:
	.4byte  blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob_end - blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob
`))

var headerTemplate *template.Template = template.Must(template.New("HeaderTemplate").Parse(`
#pragma once

#include <span>
#include <cstdint>

namespace {{ .Namespace }} {

namespace detail {
extern "C" {
extern unsigned char blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob[];
extern size_t blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob_length;
};
} // namespace detail

/**
 * \brief Returns the data inside the blob, which has static storage duration.
 */
[[nodiscard]] inline std::span<const uint8_t> {{ .Name }}_blob() noexcept{
	return std::span<const uint8_t>{
		detail::blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob,
		detail::blob_lib_{{ .NamespaceSnake }}_{{ .Name }}_blob_length,
	};
}

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

func (b *Blob) sourceFile() core.OutPath {
	return b.Out.WithSuffix(".S")
}

func (b *Blob) headerFile() core.OutPath {
	return b.Out.WithSuffix(fmt.Sprintf(".includes/%s/%s_blob.hh", namespaceToPath(b.Namespace), b.Name))
}

func (b *Blob) Build(ctx core.Context) {
	args := blobArgs{
		BinFilePath:    b.Src.Absolute(),
		Name:           b.Name,
		Namespace:      b.Namespace,
		NamespaceSnake: namespaceToSnake(b.Namespace),
	}

	generateTemplateRule(ctx, b.sourceFile(), sourceTemplate, &args, []core.Path{b.headerFile()})
	generateTemplateRule(ctx, b.headerFile(), headerTemplate, &args, nil)
}

func (b *Blob) CcLibrary(toolchain cc.Toolchain) cc.Library {
	return cc.Library{
		Out:           b.Out,
		GeneratedSrcs: []core.Path{b.sourceFile()},
		Includes:      []core.Path{b.Out.WithSuffix(".includes")},
	}
}
