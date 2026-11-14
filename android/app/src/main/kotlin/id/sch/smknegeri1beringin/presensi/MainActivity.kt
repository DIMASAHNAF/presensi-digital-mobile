package id.sch.smknegeri1beringin.presensi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "id.sch.smknegeri1beringin.presensi/mock_location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isMockLocation" -> {
                        result.success(MockLocationDetector.isMockLocationActive(applicationContext))
                    }
                    "getDeviceId" -> {
                        val id = android.provider.Settings.Secure.getString(
                            applicationContext.contentResolver,
                            android.provider.Settings.Secure.ANDROID_ID
                        )
                        result.success(id)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
