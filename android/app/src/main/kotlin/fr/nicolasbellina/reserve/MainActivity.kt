package fr.nicolasbellina.reserve

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/** Storage Access Framework : uniquement les fichiers choisis par l'utilisateur. */
class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var exportText: String? = null
    private val exportCode = 7101
    private val importCode = 7102
    private val maxBytes = 2 * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "fr.nicolasbellina.reserve/documents").setMethodCallHandler { call, result ->
            if (call.method != "export" && call.method != "import") {
                result.notImplemented()
            } else if (pending != null) {
                result.error("busy", "Un sélecteur est déjà ouvert.", null)
            } else {
                try {
                    val intent: Intent
                    val code: Int
                    if (call.method == "export") {
                        val text = call.argument<String>("json") ?: throw IllegalArgumentException()
                        if (text.toByteArray(Charsets.UTF_8).size > maxBytes) throw IllegalArgumentException()
                        exportText = text
                        intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_TITLE, "reserve-${System.currentTimeMillis()}.json")
                        }
                        code = exportCode
                    } else {
                        intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "application/octet-stream"))
                        }
                        code = importCode
                    }
                    pending = result
                    @Suppress("DEPRECATION")
                    startActivityForResult(intent, code)
                } catch (_: Exception) {
                    pending = null
                    exportText = null
                    result.error("picker", "Impossible d'ouvrir le sélecteur.", null)
                }
            }
        }
    }

    @Deprecated("API compatible avec FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != exportCode && requestCode != importCode) return
        val result = pending ?: return
        val text = exportText
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null
            exportText = null
            result.success(if (requestCode == exportCode) false else null)
            return
        }
        // Les accès disque ne bloquent pas le thread UI.
        Thread {
            try {
                val response: Any
                if (requestCode == exportCode) {
                    val output = contentResolver.openOutputStream(uri, "w") ?: throw IllegalStateException()
                    output.use { it.write((text ?: throw IllegalStateException()).toByteArray(Charsets.UTF_8)) }
                    response = true
                } else {
                    val input = contentResolver.openInputStream(uri) ?: throw IllegalStateException()
                    val bytes = ByteArrayOutputStream()
                    input.use {
                        val buffer = ByteArray(8192)
                        while (true) {
                            val count = it.read(buffer)
                            if (count < 0) break
                            if (bytes.size() + count > maxBytes) throw IllegalArgumentException()
                            bytes.write(buffer, 0, count)
                        }
                    }
                    response = bytes.toString("UTF-8")
                }
                runOnUiThread { pending = null; exportText = null; result.success(response) }
            } catch (_: Exception) {
                runOnUiThread { pending = null; exportText = null; result.error("file", "Lecture ou écriture impossible (2 Mo maximum).", null) }
            }
        }.start()
    }
}
