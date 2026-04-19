package com.retozu.flutter_amazon_chime

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle

class MediaProjectionPermissionActivity : Activity() {
    companion object {
        private const val REQUEST_CODE_CAPTURE_PERM = 1001
        var onPermissionResult: ((resultCode: Int, data: Intent?) -> Unit)? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(mediaProjectionManager.createScreenCaptureIntent(), REQUEST_CODE_CAPTURE_PERM)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_CAPTURE_PERM) {
            onPermissionResult?.invoke(resultCode, data)
            onPermissionResult = null
        }
        finish()
    }
}
