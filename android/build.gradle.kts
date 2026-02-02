// File: android/build.gradle.kts (Top-Level)

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
}

// Optimizare: Mutăm folderul de build
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)

    // ✅ FIX CRITIC PENTRU PACHETELE VECHI (precum perfect_volume_control)
    // Acest bloc se execută pentru fiecare sub-proiect (inclusiv pachetele din pub cache).
    afterEvaluate {
        // Verificăm dacă proiectul este o librărie Android
        if (project.plugins.hasPlugin("com.android.library")) {
            // Accesăm configurația Android a librăriei
            val android = project.extensions.findByType(
                com.android.build.gradle.LibraryExtension::class.java
            )
            // Dacă namespace-ul lipsește (cum e cazul la perfect_volume_control)...
            if (android != null) {
                // ✅ FIX 1: Namespace (pentru perfect_volume_control)
                if (android.namespace == null) {
                    android.namespace = project.group.toString()
                }

                android.compileSdk = 36
            }
        }
    }
}

// Configurăm sursele de pachete (repositories)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Sarcină pentru curățarea folderului de build
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}