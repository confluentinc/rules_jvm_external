load("//:defs.bzl", "artifact")

java_test(
    name = "LockFileConverterTest",
    srcs = ["LockFileConverterTest.java"],
    data = [
        ":unsorted.json",
    ],
    test_class = "com.github.bazelbuild.rules_jvm_external.resolver.lockfile.LockFileConverterTest",
    deps = [
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external/coursier",
        "@bazel_tools//tools/java/runfiles",
        artifact(
            "com.google.guava:guava",
            repository_name = "exclusion_testing",
        ),
        artifact(
            "junit:junit",
            repository_name = "regression_testing_coursier",
        ),
        artifact("org.hamcrest:hamcrest"),
        artifact("org.hamcrest:hamcrest_core"),
    ],
)

java_test(
    name = "V2LockFileTest",
    srcs = ["V2LockFileTest.java"],
    test_class = "com.github.bazelbuild.rules_jvm_external.resolver.lockfile.V2LockFileTest",
    deps = [
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external",
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external/resolver",
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external/resolver/lockfile",
        artifact(
            "com.google.code.gson:gson",
            repository_name = "rules_jvm_external_deps",
        ),
        artifact(
            "com.google.guava:guava",
            repository_name = "exclusion_testing",
        ),
        artifact(
            "junit:junit",
            repository_name = "regression_testing_coursier",
        ),
        artifact("org.hamcrest:hamcrest"),
        artifact("org.hamcrest:hamcrest_core"),
    ],
)
