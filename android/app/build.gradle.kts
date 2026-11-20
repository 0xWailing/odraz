import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName: String = localProperties.getProperty("flutter.versionName") ?: "1.0"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "xyz.whaling.odraz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "xyz.whaling.odraz"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // 当 key.properties 存在时使用 release 签名，否则 fallback 到 debug 签名
            val useReleaseSigning = keystorePropertiesFile.exists()
            signingConfig = if (useReleaseSigning) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            applicationVariants.all {
                outputs.all {
                    val outputImpl = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
                    outputImpl.outputFileName = "odraz-${name}-${versionCode}-${versionName}.apk"
                }
            }
        }
        debug {
            applicationVariants.all {
                outputs.all {
                    val outputImpl = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
                    outputImpl.outputFileName = "odraz-${name}-${versionCode}-${versionName}.apk"
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

// Rebuilds the embedded Go server (libs/server.aar) whenever the Go sources change,
// so `flutter run` and Android Studio always run the current server. If `go` or
// `gomobile` cannot be found it warns and keeps the existing libs/server.aar.
// Build it by hand with `make server-aar` if you prefer.
val goProjectDir = rootProject.projectDir.parentFile
val serverAar = file("libs/server.aar")

fun findTool(name: String): File? {
    val home = System.getProperty("user.home")
    val dirs = (System.getenv("PATH") ?: "").split(File.pathSeparator) +
        listOf("$home/go/bin", "/usr/local/go/bin", "/usr/lib/golang/bin", "/opt/homebrew/bin")
    return dirs.map { File(it, name) }.firstOrNull { it.canExecute() }
}

val buildGoServer = tasks.register<Exec>("buildGoServer") {
    group = "build"
    description = "Builds libs/server.aar from ./server/run with gomobile (only when Go sources changed)"
    val goTool = findTool("go")
    val gomobile = findTool("gomobile")
    val sdkDir = localProperties.getProperty("sdk.dir")
    val ndkDir = sdkDir?.let { File(it, "ndk/${flutter.ndkVersion}") }
    val builtAar = layout.buildDirectory.file("go/server.aar").get().asFile

    onlyIf {
        val ok = goTool != null && gomobile != null
        if (!ok) {
            logger.warn("buildGoServer: go/gomobile not found, using the existing libs/server.aar")
        }
        ok
    }
    workingDir = goProjectDir
    inputs.files(
        fileTree(goProjectDir.resolve("server")) { include("**/*.go") },
        fileTree(goProjectDir.resolve("proto")) { include("*.go") },
        goProjectDir.resolve("go.mod"),
        goProjectDir.resolve("go.sum"),
    )
    outputs.files(builtAar, serverAar)
    doFirst { builtAar.parentFile.mkdirs() }

    environment("CGO_ENABLED", "0")
    environment(
        "PATH",
        listOfNotNull(gomobile?.parent, goTool?.parent, System.getenv("PATH"))
            .joinToString(File.pathSeparator)
    )
    environment("JAVA_HOME", System.getProperty("java.home"))
    if (sdkDir != null) environment("ANDROID_HOME", sdkDir)
    if (ndkDir != null && ndkDir.isDirectory) environment("ANDROID_NDK_HOME", ndkDir.path)
    commandLine(
        gomobile?.path ?: "gomobile", "bind", "-target=android", "-androidapi", "21",
        "-ldflags", "-s -w", "-o", builtAar.path, "./server/run"
    )
    // gomobile also writes server-sources.jar next to the AAR; only the AAR is copied
    // into libs so the tracked sources jar does not change on every build.
    doLast { builtAar.copyTo(serverAar, overwrite = true) }
}

tasks.matching { it.name == "preBuild" }.configureEach { dependsOn(buildGoServer) }

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7")
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))
    implementation(files("libs/server.aar")) // 引入.aar文件
    implementation("androidx.core:core-ktx:1.7.0")
    implementation("androidx.appcompat:appcompat:1.4.1")
    implementation("com.google.android.material:material:1.5.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.2")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.3")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.4.0")
}
