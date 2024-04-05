package app.weicheng.story_trail

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val CHANNEL = "flutter.native/powerOff"
    private val RESULT_ENABLE = 1
    private lateinit var deviceManger: DevicePolicyManager
    private lateinit var compName: ComponentName

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        compName = ComponentName(this, DeviceAdmin::class.java)
        deviceManger = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "powerOff") {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName)
                intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "You should enable this feature when you need this extra safety lock.")
                startActivityForResult(intent, RESULT_ENABLE)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == RESULT_ENABLE) {
            if (resultCode == Activity.RESULT_OK) {
                deviceManger.lockNow()
            }
        }
    }
}