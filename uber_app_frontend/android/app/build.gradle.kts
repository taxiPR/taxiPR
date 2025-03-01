plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.uber_app_frontend"
    compileSdk = 34 // Versión del SDK de compilación (ajusta si es necesario)

    ndkVersion = "27.0.12077973" // Versión del NDK requerida

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.uber_app_frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21 // Versión mínima del SDK
        targetSdk = 34 // Versión objetivo del SDK
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
    getByName("release") {
        // Habilita la reducción de código y recursos solo para la versión de release
        isMinifyEnabled = true // Habilita la reducción de código
        isShrinkResources = true // Habilita la reducción de recursos
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
    getByName("debug") {
        // Deshabilita la reducción de código y recursos para la versión de debug
        isMinifyEnabled = false
        isShrinkResources = false
    }
}
}

flutter {
    source = "../.."
}