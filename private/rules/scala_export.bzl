load("@bazel_skylib//rules:run_binary.bzl", "run_binary")
load("@io_bazel_rules_scala//scala:scala.bzl", "make_scala_doc_rule", "scala_library", "scaladoc_intransitive_aspect")
load(":java_export.bzl", "maven_export")
load(":maven_project_jar.bzl", "DEFAULT_EXCLUDED_WORKSPACES")

scala_doc = make_scala_doc_rule(aspect = scaladoc_intransitive_aspect)

SCALA_LIBS = [
    #    "@io_bazel_rules_scala_scala_library//jar",
    #    "@io_bazel_rules_scala_scala_reflect//jar",
]

def scala_export(
        name,
        maven_coordinates,
        deploy_env = [],
        excluded_workspaces = {name: None for name in DEFAULT_EXCLUDED_WORKSPACES},
        exclusions = {},
        pom_template = None,
        visibility = None,
        tags = [],
        testonly = None,
        publish_maven_metadata = True,
        **kwargs):
    """Extends `scala_library` to allow maven artifacts to be uploaded. This
    rule is the Scala version of `java_export`.

    This macro can be used as a drop-in replacement for `scala_library`, but
    also generates an implicit `name.publish` target that can be run to publish
    maven artifacts derived from this macro to a maven repository. The publish
    rule understands the following variables (declared using `--define` when
    using `bazel run`):

      * `maven_repo`: A URL for the repo to use. May be "https" or "file".
      * `maven_user`: The user name to use when uploading to the maven repository.
      * `maven_password`: The password to use when uploading to the maven repository.

    This macro also generates a `name-pom` target that creates the `pom.xml` file
    associated with the artifacts. The template used is derived from the (optional)
    `pom_template` argument, and the following substitutions are performed on
    the template file:

      * `{groupId}`: Replaced with the maven coordinates group ID.
      * `{artifactId}`: Replaced with the maven coordinates artifact ID.
      * `{version}`: Replaced by the maven coordinates version.
      * `{type}`: Replaced by the maven coordintes type, if present (defaults to "jar")
      * `{dependencies}`: Replaced by a list of maven dependencies directly relied upon
        by scala_library targets within the artifact.

    The "edges" of the artifact are found by scanning targets that contribute to
    runtime dependencies for the following tags:

      * `maven_coordinates=group:artifact:type:version`: Specifies a dependency of
        this artifact.
      * `maven:compile-only`: Specifies that this dependency should not be listed
        as a dependency of the artifact being generated.

    To skip generation of the javadoc jar, add the `no-javadocs` tag to the target.
    To skip generation of the scaladoc jar, add the `no-scaladocs` tag to the target.

    Generated rules:
      * `name`: A `scala_library` that other rules can depend upon.
      * `name-docs`: A javadoc jar file.
      * `name-scaladocs`: A scaladoc jar file.
      * `name-pom`: The pom.xml file.
      * `name.publish`: To be executed by `bazel run` to publish to a maven repo.

    Args:
      name: A unique name for this target
      maven_coordinates: The maven coordinates for this target.
      pom_template: The template to be used for the pom.xml file.
      deploy_env: A list of labels of java targets to exclude from the generated jar
      visibility: The visibility of the target
      publish_maven_metadata: Whether to publish a maven-metadata.xml
      kwargs: These are passed to [`scala_library`](https://github.com/bazelbuild/rules_scala/blob/master/docs/scala_library.md),
        and so may contain any valid parameter for that rule.
    """
    maven_coordinates_tags = ["maven_coordinates=%s" % maven_coordinates]
    lib_name = "%s-lib" % name

    javadocopts = kwargs.pop("javadocopts", None)
    doc_resources = kwargs.pop("doc_resources", [])
    classifier_artifacts = kwargs.pop("classifier_artifacts", {})

    updated_deploy_env = [] + deploy_env
    for lib in SCALA_LIBS:
        if lib not in deploy_env:
            updated_deploy_env.append(lib)

    scala_library(
        name = lib_name,
        tags = tags + maven_coordinates_tags,
        testonly = testonly,
        **kwargs
    )

    if "no-scaladocs" not in tags:
        scaladocs_name = name + "-scaladocs-html"
        scala_doc(
            name = scaladocs_name,
            deps = [":" + lib_name],
        )

        scaladocs_jar_name = name + "-scaladocs"
        run_binary(
            name = scaladocs_jar_name,
            srcs = [":" + scaladocs_name] + doc_resources,
            outs = [name + "-scaladocs.jar"],
            args = [
                "$(location " + name + "-scaladocs.jar)",  # output jar
                "$(location :" + scaladocs_name + ")",  # input directory
            ] + [
                "$(location " + resource + ")"
                for resource in doc_resources
            ],  # extra resources
            tool = "@rules_jvm_external//private/tools/java/com/github/bazelbuild/rules_jvm_external/javadoc:create_jar",
        )
        classifier_artifacts["scaladoc"] = scaladocs_jar_name

    maven_export(
        name = name,
        maven_coordinates = maven_coordinates,
        classifier_artifacts = classifier_artifacts,
        lib_name = lib_name,
        deploy_env = updated_deploy_env,
        excluded_workspaces = excluded_workspaces,
        exclusions = exclusions,
        pom_template = pom_template,
        visibility = visibility,
        tags = tags,
        testonly = testonly,
        javadocopts = javadocopts,
        doc_resources = doc_resources,
        publish_maven_metadata = publish_maven_metadata,
    )
