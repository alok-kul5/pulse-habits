package dev.alok.pulse

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity, so Health Connect's permission screen can hand back a result.
class MainActivity : FlutterFragmentActivity() {
    private val health = HealthBridge(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pulse/health").setMethodCallHandler(health)
    }
}
