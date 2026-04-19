import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class VideoTile extends StatelessWidget {
  final int? tileId;
  const VideoTile({super.key, required this.tileId});

  @override
  Widget build(BuildContext context) {
    Widget videoTile;

    if (Platform.isIOS) {
      videoTile = UiKitView(
        viewType: 'videoTile',
        creationParams: tileId,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isAndroid) {
      videoTile = PlatformViewLink(
        viewType: 'videoTile',
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
              return AndroidViewSurface(
                controller: controller as AndroidViewController,
                gestureRecognizers:
                    const <Factory<OneSequenceGestureRecognizer>>{},
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              );
            },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          final AndroidViewController controller =
              PlatformViewsService.initExpensiveAndroidView(
                id: params.id,
                viewType: 'videoTile',
                layoutDirection: TextDirection.ltr,
                creationParams: tileId,
                creationParamsCodec: const StandardMessageCodec(),
                onFocus: () => params.onFocusChanged,
              );
          controller.addOnPlatformViewCreatedListener(
            params.onPlatformViewCreated,
          );
          controller.create();
          return controller;
        },
      );
    } else {
      videoTile = const Text('Unrecognized Platform.');
    }

    return videoTile;
  }
}
