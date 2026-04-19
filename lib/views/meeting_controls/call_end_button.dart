import 'package:flutter/material.dart';
import 'package:flutter_amazon_chime/styles/style.dart';

class CallEndButton extends StatelessWidget {
  const CallEndButton({super.key});

  @override
  Widget build(BuildContext context) {
    final icon = Icons.call_end;

    return FilledButton(
      style: Style.circleButton.copyWith(
        backgroundColor: WidgetStatePropertyAll(ChimeColors.error),
      ),
      child: Icon(icon, color: ChimeColors.surface),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }
}
