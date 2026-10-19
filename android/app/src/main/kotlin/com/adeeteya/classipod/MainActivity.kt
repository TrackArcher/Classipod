package com.adeeteya.classipod

import android.content.pm.LauncherApps
import android.os.Process
import android.os.UserManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INSTALLED_APPS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLaunchableApps" -> {
                    try {
                        result.success(getLaunchableApps())
                    } catch (e: Exception) {
                        result.error("GET_APPS_FAILED", e.message, null)
                    }
                }

                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    val userSerial = call.argument<Number>("userSerial")?.toLong()
                    if (packageName == null || userSerial == null) {
                        result.error("INVALID_ARGS", "Missing packageName or userSerial", null)
                        return@setMethodCallHandler
                    }
                    try {
                        launchApp(packageName, userSerial)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("LAUNCH_FAILED", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun getLaunchableApps(): List<Map<String, Any>> {
        val launcherApps = getSystemService(LauncherApps::class.java)
        val userManager = getSystemService(UserManager::class.java)
        val apps = mutableListOf<Map<String, Any>>()
        val seen = mutableSetOf<String>()

        for (user in userManager.userProfiles) {
            val userSerial = userManager.getSerialNumberForUser(user)
            val activities = launcherApps.getActivityList(null, user)
            for (activity in activities) {
                val packageName = activity.componentName.packageName // Fixed property name
                val key = "$packageName:$userSerial"
                if (!seen.add(key)) continue

                var label = activity.label?.toString() ?: packageName
                if (userManager.userProfiles.size > 1 && user != Process.myUserHandle()) {
                    val suffix = " (Work)" // Simplified to avoid argument signature mismatch
                    if (!label.endsWith(suffix)) {
                        label += suffix
                    }
                }

                apps.add(
                    mapOf(
                        "label" to label,
                        "packageName" to packageName,
                        "userSerial" to userSerial,
                    ),
                )
            }
        }

        apps.sortBy { (it["label"] as String).lowercase() }
        return apps
    }

    private fun launchApp(packageName: String, userSerial: Long) {
        val launcherApps = getSystemService(LauncherApps::class.java)
        val userManager = getSystemService(UserManager::class.java)
        val user =
            userManager.userProfiles.firstOrNull {
                userManager.getSerialNumberForUser(it) == userSerial
            } ?: Process.myUserHandle()

        val activities = launcherApps.getActivityList(packageName, user)
        val component = activities.firstOrNull()?.componentName // Fixed property name
            ?: throw IllegalStateException("No launchable activity for $packageName")

        launcherApps.startMainActivity(component, user, null, null)
    }

    companion object {
        private const val INSTALLED_APPS_CHANNEL = "com.adeeteya.classipod/installed_apps"
    }
}