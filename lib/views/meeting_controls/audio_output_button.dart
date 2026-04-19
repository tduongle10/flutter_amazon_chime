import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/logger.dart';
import 'package:flutter_amazon_chime/chime_session.dart';
import 'package:flutter_amazon_chime/styles/style.dart';
import 'package:provider/provider.dart';

class AudioOutputButton extends StatelessWidget {
  const AudioOutputButton({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<ChimeSession>(context);

    return Builder(
      builder: (context) => FilledButton(
        style: Style.circleButton.copyWith(
          backgroundColor: WidgetStatePropertyAll(ChimeColors.surfaceVariant),
        ),
        child: Icon(Icons.volume_up, color: ChimeColors.onSurface),
        onPressed: () {
          showAudioDevicePopup(session, context);
        },
      ),
    );
  }

  IconData _iconForDevice(String name) {
    final n = name.toLowerCase();
    if (n.contains('bluetooth')) return Icons.bluetooth;
    if (n.contains('headphone') ||
        n.contains('headset') ||
        n.contains('wired')) {
      return Icons.headphones;
    }
    if (n.contains('speaker')) return Icons.volume_up;
    if (n.contains('receiver') ||
        n.contains('earpiece') ||
        n.contains('phone')) {
      return Icons.phone_in_talk;
    }
    return Icons.speaker;
  }

  void showAudioDevicePopup(
    ChimeSession session,
    BuildContext context,
  ) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);

    const gap = 8.0;
    const menuWidth = 260.0;

    final device = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Stack(
          children: [
            Positioned(
              left: buttonTopLeft.dx,
              bottom: overlay.size.height - buttonTopLeft.dy + gap,
              child: FadeTransition(
                opacity: curved,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  widthFactor: 1,
                  heightFactor: curved.value,
                  child: _AudioMenu(
                    width: menuWidth,
                    devices: session.deviceList,
                    selected: session.selectedAudioDevice,
                    iconFor: _iconForDevice,
                    onSelect: (d) => Navigator.of(context).pop(d),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (device == null) {
      logger.w('No device chosen.');
      return;
    }

    logger.i('$device was chosen.');
    await session.updateCurrentDevice(device);
  }
}

class _AudioMenu extends StatelessWidget {
  const _AudioMenu({
    required this.width,
    required this.devices,
    required this.selected,
    required this.iconFor,
    required this.onSelect,
  });

  final double width;
  final List<String> devices;
  final String? selected;
  final IconData Function(String) iconFor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChimeColors.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Audio',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            ...devices.map((d) {
              final isSelected = d == selected;
              return InkWell(
                onTap: () => onSelect(d),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        iconFor(d),
                        size: 22,
                        color: isSelected
                            ? Colors.blue.shade600
                            : Colors.black87,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.blue.shade600
                                : Colors.black87,
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 20,
                          color: Colors.blue.shade600,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
