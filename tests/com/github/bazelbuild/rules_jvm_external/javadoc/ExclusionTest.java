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
            "com/example/internal/InternalThing.java",
            "package com.example.internal; public class InternalThing {}"
        ));

    JavadocJarMaker.main(
        new String[] {
            "--in",
            inputJar.toAbsolutePath().toString(),
            "--out",
            outputJar.toAbsolutePath().toString(),
            "--element-list",
            elementList.toAbsolutePath().toString()
        });

    Map<String, String> contents = readJar(outputJar);
    System.out.println(contents);
  }
}
