package com.example.mobile_app

import android.os.Build
import com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
	override fun getRenderMode(): RenderMode = RenderMode.texture

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		if (isProbablyEmulator()) {
			// nfc_manager crashes on some emulator images (API 36). Register only required plugins.
			flutterEngine.plugins.add(FlutterSecureStoragePlugin())
			return
		}

		GeneratedPluginRegistrant.registerWith(flutterEngine)
	}

	private fun isProbablyEmulator(): Boolean {
		val fingerprint = Build.FINGERPRINT.lowercase()
		val model = Build.MODEL.lowercase()
		val product = Build.PRODUCT.lowercase()
		val hardware = Build.HARDWARE.lowercase()
		val device = Build.DEVICE.lowercase()
		val manufacturer = Build.MANUFACTURER.lowercase()
		val brand = Build.BRAND.lowercase()
		val hasX86Abi = Build.SUPPORTED_ABIS.any {
			val abi = it.lowercase()
			abi.contains("x86")
		}

		return fingerprint.startsWith("generic") ||
			Build.FINGERPRINT.lowercase().contains("emulator") ||
			model.contains("emulator") ||
			model.contains("android sdk built for") ||
			model.contains("sdk_gphone") ||
			product.contains("sdk_gphone") ||
			product.contains("sdk_google") ||
			product.contains("google_sdk") ||
			hardware.contains("ranchu") ||
			hardware.contains("goldfish") ||
			manufacturer.contains("genymotion") ||
			hasX86Abi ||
			(brand.startsWith("generic") && device.startsWith("generic"))
	}
}
