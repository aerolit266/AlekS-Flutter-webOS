import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(const Directionality(
      textDirection: TextDirection.ltr,
      child: RemoteSmoke(),
    ));

class RemoteSmoke extends StatefulWidget {
  const RemoteSmoke({super.key});

  @override
  State<RemoteSmoke> createState() => _RemoteSmokeState();
}

class _RemoteSmokeState extends State<RemoteSmoke> {
  static const labels = ['One', 'Two', 'Three', 'Four'];
  int selected = 0;
  int? confirmed;

  static const remote = 'com.aleks.webos6/remote';
  static const keys = [
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.enter,
  ];

  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
      remote,
      (message) async {
        if (message == null || message.lengthInBytes != 1) return null;
        final code = message.getUint8(0);
        if (code >= keys.length) return null;
        applyKey(keys[code]);
        return ByteData(2)
          ..setUint8(0, selected)
          ..setUint8(1, confirmed == selected ? 1 : 0);
      },
    );
  }

  @override
  void dispose() {
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(remote, null);
    super.dispose();
  }

  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    return applyKey(event.logicalKey);
  }

  KeyEventResult applyKey(LogicalKeyboardKey key) {
    final offset = switch (key) {
      LogicalKeyboardKey.arrowLeft => selected.isOdd ? -1 : 0,
      LogicalKeyboardKey.arrowRight => selected.isEven ? 1 : 0,
      LogicalKeyboardKey.arrowUp => selected >= 2 ? -2 : 0,
      LogicalKeyboardKey.arrowDown => selected < 2 ? 2 : 0,
      LogicalKeyboardKey.enter => 0,
      _ => null,
    };
    if (offset == null) return KeyEventResult.ignored;

    setState(() {
      selected += offset;
      if (key == LogicalKeyboardKey.enter) confirmed = selected;
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: handleKey,
      child: ColoredBox(
        color: const Color(0xff101619),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Flutter on webOS', style: TextStyle(
                color: Color(0xffffffff), fontSize: 28,
              )),
              const SizedBox(height: 16),
              for (var row = 0; row < 2; row++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = row * 2; i < row * 2 + 2; i++)
                      Container(
                        width: 100,
                        height: 50,
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        color: selected == i
                            ? const Color(0xff65dac1)
                            : const Color(0xff293e46),
                        child: Text(labels[i], style: TextStyle(
                          color: selected == i
                              ? const Color(0xff101619)
                              : const Color(0xffffffff),
                        )),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(confirmed == null ? 'Press OK' : 'OK: ${labels[confirmed!]}',
                style: const TextStyle(color: Color(0xffffffff))),
            ],
          ),
        ),
      ),
    );
  }
}
