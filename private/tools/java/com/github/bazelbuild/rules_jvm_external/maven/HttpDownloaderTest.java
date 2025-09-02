package com.github.bazelbuild.rules_jvm_external.maven;

import com.github.bazelbuild.rules_jvm_external.resolver.remote.HttpDownloader;
import com.github.bazelbuild.rules_jvm_external.resolver.ui.AnsiConsoleListener;

public class HttpDownloaderTest {

    public static void main(String[] args) throws Exception {
        Thread thread = new Thread(() -> {
            try {
                System.out.println("Hello from non-daemon thread");
                while (true) {
                    System.out.println("Still alive");
                    Thread.sleep(1000);
                }
            } catch (InterruptedException e) {
                // Ignore
                System.out.println("interrupted");
            }
        });
        thread.setDaemon(false);
        thread.start();
        Thread.sleep(1000);
        System.exit(0);
    }
}
