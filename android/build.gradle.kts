// Top-level build file where you can add configuration options common to all sub-projects/modules.
//
// This file is used to configure repositories and build settings for all subprojects.
// Flutter automatically manages build directories, so manual manipulation is not recommended.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Note: Flutter handles build directory configuration automatically.
// Manual build directory manipulation can cause build issues and is not recommended.
// The following code has been removed to prevent potential build problems:
// - Custom build directory paths
// - evaluationDependsOn which can cause circular dependencies

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
