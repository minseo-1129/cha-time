import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()

if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val generatedLauncherResDir =
    layout.buildDirectory.dir("generated/tea_launcher_res")

android {
    namespace = "com.teawithyou.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            res.srcDir(generatedLauncherResDir.get().asFile)
        }
    }

    defaultConfig {
        applicationId = "com.teawithyou.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Release signing is enabled only when android/key.properties exists.
            // This prevents the upload keystore and passwords from being committed.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val generateTeaLauncherIcon by tasks.registering {
    val partsDir = file("launcher_icon_base64")
    val outputFile = generatedLauncherResDir.map {
        it.file("mipmap-nodpi/tea_release_icon_v5.png")
    }

    inputs.dir(partsDir)
    outputs.file(outputFile)

    doLast {
        val encoded = partsDir
            .listFiles()
            ?.filter { it.isFile && it.extension == "txt" }
            ?.sortedBy { it.name }
            ?.joinToString("") { it.readText().trim() }
            ?: error("Tea launcher icon parts were not found.")

        val target = outputFile.get().asFile
        target.parentFile.mkdirs()
        target.writeBytes(
            Base64.getDecoder().decode(encoded)
        )
    }
}

tasks.matching { it.name == "preBuild" }.configureEach {
    dependsOn(generateTeaLauncherIcon)
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
