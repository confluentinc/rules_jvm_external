java_library(
    name = "create_jar_lib",
    srcs = ["CreateJar.java"],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external",
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external/zip",
    ],
)

java_binary(
    name = "javadoc",
    srcs = ["JavadocJarMaker.java"],
    main_class = "com.github.bazelbuild.rules_jvm_external.javadoc.JavadocJarMaker",
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":create_jar_lib",
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external",
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external/zip",
    ],
)

java_binary(
    name = "create_jar",
    srcs = ["CreateJar.java"],
    main_class = "com.github.bazelbuild.rules_jvm_external.javadoc.CreateJar",
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external",
        "//private/tools/java/com/github/bazelbuild/rules_jvm_external/zip",
    ],
)
