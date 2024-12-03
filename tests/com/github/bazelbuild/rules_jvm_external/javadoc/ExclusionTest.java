package com.github.bazelbuild.rules_jvm_external.javadoc;

import com.google.common.collect.ImmutableMap;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.IOException;
import java.nio.file.Path;
import java.util.Map;

import static com.github.bazelbuild.rules_jvm_external.ZipUtils.createJar;
import static com.github.bazelbuild.rules_jvm_external.ZipUtils.readJar;

public class ExclusionTest {
  @Rule
  public TemporaryFolder temp = new TemporaryFolder();

  @Test
  public void testJavadocPackageExclusion() throws IOException {
    Path inputJar = temp.newFile("in.jar").toPath();
    Path outputJar = temp.newFile("out.jar").toPath();
    Path elementList = temp.newFile("element-list").toPath();
    // deleting the file since JavadocJarMaker fails on existing files, we just need to supply the
    // path.
    elementList.toFile().delete();

    createJar(
        inputJar,
        ImmutableMap.of(
            "com/example/Main.java",
            "package com.example; public class Main { public static void main(String[] args) {} }",
            "com/example/processor/Processor.java",
            "package com.example.processor; public class Processor {}",
            "com/example/processor/internal/InternalProcessor.java",
            "package com.example.processor.internal; public class InternalProcessor {}",
            "com/example/state/internal/InternalThing.java",
            "package com.example.state.internal; public class InternalThing {}",
            "com/example/state/Thing.java",
            "package com.example.state; public class Thing {}",
            "com/example/query/Query.java",
            "package com.example.query; public class Query {}",
            "com/example/query/internal/InternalQuery.java",
            "package com.example.query.internal; public class InternalQuery {}"
        ));

    JavadocJarMaker.main(
        new String[] {
            "--in",
            inputJar.toAbsolutePath().toString(),
            "--out",
            outputJar.toAbsolutePath().toString(),
            "--exclude-packages",
            "com.example.processor.internal",
            "--exclude-packages",
            "com.example.state.internal",
            "--exclude-packages",
            "com.example.query.internal",
            "--element-list",
            elementList.toAbsolutePath().toString()
        });

    Map<String, String> contents = readJar(outputJar);

    assert contents.containsKey("com/example/Main.html");

    assert contents.containsKey("com/example/processor/Processor.html");
    assert !contents.containsKey("com/example/processor/internal/InternalProcessor.html");

    assert contents.containsKey("com/example/state/Thing.html");
    assert !contents.containsKey("com/example/state/internal/InternalThing.html");

    assert contents.containsKey("com/example/query/Query.html");
    assert !contents.containsKey("com/example/query/internal/InternalQuery.html");
  }

  @Test
  public void testJavadocPackageExclusionWithAsterisk() throws IOException {
    Path inputJar = temp.newFile("in.jar").toPath();
    Path outputJar = temp.newFile("out.jar").toPath();
    Path elementList = temp.newFile("element-list").toPath();
    // deleting the file since JavadocJarMaker fails on existing files, we just need to supply the
    // path.
    elementList.toFile().delete();

    createJar(
        inputJar,
        ImmutableMap.of(
            "com/example/Main.java",
            "package com.example; public class Main { public static void main(String[] args) {} }",
            "com/example/processor/Processor.java",
            "package com.example.processor; public class Processor {}",
            "com/example/processor/internal/InternalProcessor.java",
            "package com.example.processor.internal; public class InternalProcessor {}",
            "com/example/processor/internal/other/OtherProcessor.java",
            "package com.example.processor.internal.other; public class OtherProcessor {}"
        ));

    JavadocJarMaker.main(
        new String[] {
            "--in",
            inputJar.toAbsolutePath().toString(),
            "--out",
            outputJar.toAbsolutePath().toString(),
            "--exclude-packages",
            "com.example.processor.internal.*",
            "--element-list",
            elementList.toAbsolutePath().toString()
        });

    Map<String, String> contents = readJar(outputJar);

    assert contents.containsKey("com/example/Main.html");
    assert contents.containsKey("com/example/processor/Processor.html");
    assert !contents.containsKey("com/example/processor/internal/InternalProcessor.html");
    assert !contents.containsKey("com/example/processor/internal/other/OtherProcessor.html");
  }

  @Test
  public void testJavadocPackageToplevelExcluded() throws IOException {
    Path inputJar = temp.newFile("in.jar").toPath();
    Path outputJar = temp.newFile("out.jar").toPath();
    Path elementList = temp.newFile("element-list").toPath();
    // deleting the file since JavadocJarMaker fails on existing files, we just need to supply the
    // path.
    elementList.toFile().delete();

    createJar(
        inputJar,
        ImmutableMap.of(
            "com/example/Main.java",
            "package com.example; public class Main { public static void main(String[] args) {} }",
            "io/example/processor/Processor.java",
            "package io.example.processor; public class Processor {}"
        ));

    JavadocJarMaker.main(
        new String[] {
            "--in",
            inputJar.toAbsolutePath().toString(),
            "--out",
            outputJar.toAbsolutePath().toString(),
            "--exclude-packages",
            "io.example.*",
            "--element-list",
            elementList.toAbsolutePath().toString()
        });

    Map<String, String> contents = readJar(outputJar);

    assert contents.containsKey("com/example/Main.html");
    assert !contents.containsKey("io/example/processor/Processor.html");
  }
}
