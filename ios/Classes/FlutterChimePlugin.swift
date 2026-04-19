import AmazonChimeSDK
import AmazonChimeSDKMedia
import Flutter
import UIKit

public class FlutterChimePlugin: NSObject, FlutterPlugin {
  private var methodChannel: MethodChannelCoordinator?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FlutterChimePlugin()
    instance.methodChannel = MethodChannelCoordinator(binaryMessenger: registrar.messenger())

    let viewFactory = FlutterVideoTileFactory(messenger: registrar.messenger())
    registrar.register(viewFactory, withId: "videoTile")

    registrar.addApplicationDelegate(instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    methodChannel = nil
  }
}
