import java.io.File
import org.gradle.api.tasks.Delete

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
        classpath("com.google.gms:google-services:4.4.2") // Firebase
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Corrige o buildDir para Kotlin DSL (sem warnings)
rootProject.buildDir = File("../build")

subprojects {
    buildDir = File(rootProject.buildDir, name)
    evaluationDependsOn(":app")
}

// Corrige sintaxe da task clean
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
