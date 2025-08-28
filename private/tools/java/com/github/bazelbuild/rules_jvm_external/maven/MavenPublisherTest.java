package com.github.bazelbuild.rules_jvm_external.maven;

import com.sun.net.httpserver.HttpServer;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.junit.Test;

public class MavenPublisherTest {

  @Test
  public void testPublishLocal() throws Exception {
    // Create a temp file called pom.xml
    File pom = File.createTempFile("pom", ".xml");

    // Create a temp file called example-project.jar
    File jar = File.createTempFile("example-project", ".jar");

    MavenPublisher.run(
        "com.example:example:1.0.0",
        pom.getAbsolutePath(),
        jar.getAbsolutePath(),
        true,
        null,
        Paths.get(System.getenv("TEST_TMPDIR")).toUri().toString());
  }

  @Test
  public void testPublishHttp() throws Exception {
    final Path root = Paths.get(System.getenv("TEST_TMPDIR"));
    HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
    server.createContext(
        "/",
        ex -> {
          String method = ex.getRequestMethod();
          Path target = root.resolve("." + ex.getRequestURI().getPath()).normalize();

          if ("PUT".equals(method)) {
            Files.createDirectories(target.getParent());
            try (InputStream in = ex.getRequestBody();
                OutputStream out = Files.newOutputStream(target)) {
              in.transferTo(out);
            }
            ex.sendResponseHeaders(201, 0);
          } else if ("GET".equals(method) && Files.exists(target)) {
            byte[] data = Files.readAllBytes(target);
            ex.sendResponseHeaders(200, data.length);
            try (OutputStream out = ex.getResponseBody()) {
              out.write(data);
            }
          } else {
            ex.sendResponseHeaders(404, -1);
          }
          ex.close();
        });
    server.start();

    // Create a temp file called pom.xml
    File pom = File.createTempFile("pom", ".xml");

    // Create a temp file called example-project.jar
    File jar = File.createTempFile("example-project", ".jar");

    MavenPublisher.run(
        "com.example:example:1.0.0",
        pom.getAbsolutePath(),
        jar.getAbsolutePath(),
        true,
        null,
        "http://localhost:" + server.getAddress().getPort() + "/repository");
  }
}
