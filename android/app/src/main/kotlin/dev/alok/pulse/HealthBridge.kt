package dev.alok.pulse

import android.content.Intent
import android.net.Uri
import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateGroupByPeriodRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.Period

/**
 * Read-only daily steps from Health Connect, for the "pulse/health" channel.
 * Asks for one permission (read steps) and never writes anything.
 */
class HealthBridge(private val activity: FragmentActivity) : MethodChannel.MethodCallHandler {

    private val permissions = setOf(HealthPermission.getReadPermission(StepsRecord::class))
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var pending: MethodChannel.Result? = null

    // Registered while the activity is being created, as the result API requires.
    private val launcher: ActivityResultLauncher<Set<String>> =
        activity.registerForActivityResult(PermissionController.createRequestPermissionResultContract()) { granted ->
            pending?.success(granted.containsAll(permissions))
            pending = null
        }

    private fun available() =
        HealthConnectClient.getSdkStatus(activity) == HealthConnectClient.SDK_AVAILABLE

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> {
                if (!available()) return result.success("notInstalled")
                scope.launch {
                    try {
                        val granted = HealthConnectClient.getOrCreate(activity)
                            .permissionController.getGrantedPermissions()
                        result.success(if (granted.containsAll(permissions)) "granted" else "denied")
                    } catch (e: Exception) {
                        result.success("notInstalled")
                    }
                }
            }

            "request" -> {
                if (!available()) return result.success(false)
                pending?.success(false)
                pending = result
                try {
                    launcher.launch(permissions)
                } catch (e: Exception) {
                    pending = null
                    result.success(false)
                }
            }

            "install" -> {
                val market = Uri.parse(
                    "market://details?id=com.google.android.apps.healthdata&url=healthconnect%3A%2F%2Fonboarding",
                )
                try {
                    activity.startActivity(Intent(Intent.ACTION_VIEW, market).setPackage("com.android.vending"))
                } catch (e: Exception) {
                    val web = Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata")
                    activity.startActivity(Intent(Intent.ACTION_VIEW, web))
                }
                result.success(null)
            }

            "steps" -> {
                if (!available()) return result.success(emptyMap<String, Int>())
                val days = (call.argument<Int>("days") ?: 30).coerceIn(1, 366)
                scope.launch {
                    try {
                        val today = LocalDate.now()
                        val start = today.minusDays((days - 1).toLong()).atStartOfDay()
                        val end = today.plusDays(1).atStartOfDay()
                        val buckets = HealthConnectClient.getOrCreate(activity).aggregateGroupByPeriod(
                            AggregateGroupByPeriodRequest(
                                metrics = setOf(StepsRecord.COUNT_TOTAL),
                                timeRangeFilter = TimeRangeFilter.between(start, end),
                                timeRangeSlicer = Period.ofDays(1),
                            ),
                        )
                        val out = HashMap<String, Int>()
                        for (b in buckets) {
                            val n = b.result[StepsRecord.COUNT_TOTAL] ?: continue
                            out[b.startTime.toLocalDate().toString()] = n.toInt()
                        }
                        result.success(out)
                    } catch (e: Exception) {
                        result.success(emptyMap<String, Int>())
                    }
                }
            }

            "openedForRationale" -> {
                val action = activity.intent?.action
                result.success(action == RATIONALE || action == Intent.ACTION_VIEW_PERMISSION_USAGE)
            }

            else -> result.notImplemented()
        }
    }

    companion object {
        const val RATIONALE = "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"
    }
}
