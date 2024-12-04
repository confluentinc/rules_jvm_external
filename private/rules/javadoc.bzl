load("@rules_java//java:defs.bzl", "JavaInfo")
load(":maven_project_jar.bzl", "DEFAULT_EXCLUDED_WORKSPACES")

_JavadocInfo = provider(
    fields = {
        "element_list": "The element-list or package-list file generated by javadoc",
        "url": "The URL at which this documentation will be hosted",
    },
)

_DEFAULT_JAVADOCOPTS = [
    "-notimestamp",
    "-use",
    "-quiet",
    "-Xdoclint:-missing",
    "-encoding",
    "UTF8",
]

def generate_javadoc(
        ctx,
        javadoc,
        source_jars,
        classpath,
        javadocopts,
        doc_deps,
        doc_resources,
        excluded_packages,
        output,
        element_list):
    inputs = []
    transitive_inputs = []
    args = ctx.actions.args()

    args.add("--out", output)
    args.add("--element-list", element_list)

    args.add_all(source_jars, before_each = "--in")
    inputs.extend(source_jars)

    args.add_all(ctx.files.doc_resources, before_each = "--resources")
    inputs.extend(ctx.files.doc_resources)

    args.add_all(classpath, before_each = "--cp")
    transitive_inputs.append(classpath)

    args.add_all(excluded_packages, before_each = "--exclude-packages")
    args.add_all(ctx.attr.included_packages, before_each = "--include-packages")

    for dep in doc_deps:
        dep_info = dep[_JavadocInfo]
        args.add("-linkoffline")
        args.add(dep_info.url)
        args.add(dep_info.element_list.dirname)
        inputs.append(dep_info.element_list)

    javadocopts = [
        ctx.expand_make_variables("javadocopts", opt, ctx.var)
        for opt in javadocopts
    ]
    args.add_all(javadocopts)

    ctx.actions.run(
        executable = javadoc,
        outputs = [output, element_list],
        inputs = depset(inputs, transitive = transitive_inputs),
        arguments = [args],
    )

def _javadoc_impl(ctx):
    sources = []
    for dep in ctx.attr.deps:
        sources.extend(dep[JavaInfo].source_jars)

    jar_file = ctx.actions.declare_file("%s.jar" % ctx.attr.name)

    # This needs to be a in a separate directory as javadoc accepts the containing directory as
    # an argument rather than the file itself.
    element_list = ctx.actions.declare_file("%s-element-list-dir/element-list" % ctx.attr.name)

    # javadoc may need to inspect compile-time dependencies (neverlink)
    # of the runtime classpath.
    classpath = depset(
        transitive = [dep[JavaInfo].transitive_runtime_jars for dep in ctx.attr.deps] +
                     [dep[JavaInfo].transitive_compile_time_jars for dep in ctx.attr.deps],
    )

    # javadoc options and javac options overlap, but we cannot
    # necessarily rely on those to derive the javadoc options we need
    # from dep[JavaInfo].compilation_info (which, FWIW, always returns
    # `None` https://github.com/bazelbuild/bazel/issues/10170). For this
    # reason we allow people to set javadocopts via the rule attrs.
    generate_javadoc(
        ctx,
        ctx.executable._javadoc,
        sources,
        classpath,
        ctx.attr.javadocopts,
        ctx.attr.doc_deps,
        ctx.attr.doc_resources,
        ctx.attr.excluded_packages,
        jar_file,
        element_list,
    )

    providers = [
        DefaultInfo(files = depset([jar_file])),
    ]
    if ctx.attr.doc_url:
        providers.append(
            _JavadocInfo(
                element_list = element_list,
                url = ctx.attr.doc_url,
            ),
        )

    return providers

javadoc = rule(
    _javadoc_impl,
    doc = "Generate a javadoc from all the `deps`",
    attrs = {
        "deps": attr.label_list(
            doc = """The java libraries to generate javadocs for.

          The source jars of each dep will be used to generate the javadocs.
          Currently docs for transitive dependencies are not generated.
          """,
            mandatory = True,
            providers = [
                [JavaInfo],
            ],
        ),
        "javadocopts": attr.string_list(
            doc = """javadoc options.
            Note sources and classpath are derived from the deps. Any additional
            options can be passed here. If nothing is passed, a default list of options is used:
            %s
            """ % _DEFAULT_JAVADOCOPTS,
            default = _DEFAULT_JAVADOCOPTS,
        ),
        "doc_deps": attr.label_list(
            doc = """`javadoc` targets referenced by the current target.

            Use this to automatically add appropriate `-linkoffline` javadoc options to resolve
            references to packages documented by the given javadoc targets that have `url`
            specified.
            """,
            providers = [
                [_JavadocInfo],
            ],
        ),
        "doc_url": attr.string(
            doc = """The URL at which this documentation will be hosted.

            This information is only used by javadoc targets depending on this target.
            """,
        ),
        "doc_resources": attr.label_list(
            doc = "Resources to include in the javadoc jar.",
            allow_empty = True,
            allow_files = True,
            default = [],
        ),
        "excluded_packages": attr.string_list(
            doc = """A list of packages to exclude from the generated javadoc. Wildcards are supported at the end of
            the package name. For example, `com.example.*` will exclude all the subpackages of `com.example`, while
            `com.example` will exclude only the files directly in `com.example`.""",
            allow_empty = True,
            default = [],
        ),
        "included_packages": attr.string_list(
            doc = """A list of packages to include in the generated javadoc. Wildcards are supported at the end of
            the package name. For example, `com.example.*` will include all the subpackages of `com.example`, while
            `com.example` will include only the files directly in `com.example`.""",
            allow_empty = True,
            default = [],
        ),
        "excluded_workspaces": attr.string_list(
            doc = "A list of bazel workspace names to exclude from the generated jar",
            allow_empty = True,
            default = DEFAULT_EXCLUDED_WORKSPACES,
        ),
        "additional_dependencies": attr.label_keyed_string_dict(
            doc = "Mapping of `Label`s to the excluded workspace names. Note that this must match the values passed to the `pom_file` rule so the `pom.xml` correctly lists these dependencies.",
            allow_empty = True,
            providers = [
                [JavaInfo],
            ],
        ),
        "_javadoc": attr.label(
            default = "//private/tools/java/com/github/bazelbuild/rules_jvm_external/javadoc:javadoc",
            cfg = "exec",
            executable = True,
        ),
    },
)
