package id.sch.smknegeri1beringin.presensi

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.provider.Settings

/**
 * Deteksi lokasi palsu (Fake GPS / Mock Location) pada Android.
 *
 * Menggabungkan beberapa sinyal karena tidak ada satu API yang lengkap:
 *  - Location.isMock / isFromMockProvider (API 18 / 31+)
 *  - LocationManager.getLastKnownLocation semua provider, dicek isMock
 *  - Setting "Mock Location" app aktif (developer options)
 */
object MockLocationDetector {

    fun isMockLocationActive(context: Context): Boolean {
        // 1. Cek apakah ada aplikasi "Mock Location" yang dipilih di Developer Options.
        if (isMockAppSelected(context)) return true

        // 2. Cek provider GPS/network apakah lokasi terakhir berasal dari mock provider.
        return try {
            val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val providers = lm.getProviders(true) ?: emptyList()
            for (provider in providers) {
                val loc: Location? = try {
                    lm.getLastKnownLocation(provider)
                } catch (_: SecurityException) {
                    null
                } catch (_: Exception) {
                    null
                }
                if (loc != null && isLocationMocked(loc)) return true
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun isLocationMocked(loc: Location): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            loc.isMock
        } else {
            loc.isFromMockProvider
        }
    }

    private fun isMockAppSelected(context: Context): Boolean {
        return try {
            val mockLocation = Settings.Secure.getString(
                context.contentResolver,
                "mock_location"
            )
            // "1" berarti ada app mock location yang diaktifkan sebagai mock provider.
            mockLocation == "1"
        } catch (_: Exception) {
            false
        }
    }
}
