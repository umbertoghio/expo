package abi46_0_0.expo.modules.speech

import android.content.Context
import abi46_0_0.expo.modules.core.BasePackage

class SpeechPackage : BasePackage() {
  override fun createExportedModules(context: Context) = listOf(SpeechModule(context))
}
