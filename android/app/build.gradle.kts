import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.alok.pulse"
    // flutter_local_notifications and androidx.core 1.19 compile against 37.
    compileSdk = 37
    // A local build can pick an installed NDK: -P pulse.ndk=<version>.
    ndkVersion = (project.findProperty("pulse.ndk") as String?) ?: flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Scheduled notifications use java.time on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "dev.alok.pulse"
        // Health Connect's client library needs Android 8.0 (API 26).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release key from android/key.properties (local) or PULSE_KEYSTORE* env (CI).
    // Without one, release builds fall back to the debug key.
    val keyProps = Properties().apply {
        val f = rootProject.file("key.properties")
        if (f.exists()) f.inputStream().use { load(it) }
    }
    val storePath = keyProps.getProperty("storeFile") ?: System.getenv("PULSE_KEYSTORE")
    val storePass = keyProps.getProperty("password") ?: System.getenv("PULSE_KEYSTORE_PASSWORD")

    signingConfigs {
        if (storePath != null && storePass != null) {
            create("release") {
                storeFile = file(storePath)
                storePassword = storePass
                keyAlias = "pulse"
                keyPassword = storePass
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.health.connect:connect-client:1.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("androidx.fragment:fragment-ktx:1.8.9")
}

flutter {
    source = "../.."
}
