allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        // ✅ FIX pentru pluginuri Android (usage_stats / lStar)
        if (project.plugins.hasPlugin("com.android.application") ||
            project.plugins.hasPlugin("com.android.library")) {

            project.extensions.findByName("android")?.let { androidExt ->
                if (androidExt is com.android.build.gradle.BaseExtension) {
                    androidExt.compileSdkVersion(36)
                }
            }
        }

        // ✅ FIX CRITIC PENTRU ISAR (Namespace Error)
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.getByType(
                com.android.build.gradle.BaseExtension::class.java
            )
            if (android.namespace == null) {
                android.namespace = project.group.toString()
            }
        }
    }
}


subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}