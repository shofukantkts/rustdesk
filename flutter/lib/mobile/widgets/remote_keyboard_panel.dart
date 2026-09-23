import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/input_model.dart';

enum RemoteKeyboardTab { inputMethod, shortcuts, computer }

class RemoteKeyboardPanel extends StatefulWidget {
  const RemoteKeyboardPanel({
    super.key,
    required this.tab,
    required this.inputModel,
    required this.isMac,
    required this.onTabSelected,
    required this.onClose,
  });

  final RemoteKeyboardTab tab;
  final InputModel inputModel;
  final bool isMac;
  final ValueChanged<RemoteKeyboardTab> onTabSelected;
  final VoidCallback onClose;

  @override
  State<RemoteKeyboardPanel> createState() => _RemoteKeyboardPanelState();
}

class _RemoteKeyboardPanelState extends State<RemoteKeyboardPanel> {
  static const _headerColor = Color(0xFF272730);
  static const _panelColor = Color(0xFF050509);
  static const _keyColor = Color(0xFF282830);
  static const _selectedColor = Color(0xFF5A9BFF);

  final PageController _pageController = PageController();
  int _keyboardPage = 0;
  bool _combinedKeyMode = false;
  bool _ctrl = false;
  bool _shift = false;
  bool _alt = false;
  bool _command = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _panelHeight(BuildContext context) {
    if (widget.tab == RemoteKeyboardTab.inputMethod) return 64;
    final media = MediaQuery.of(context);
    final height = (media.size.height - media.viewInsets.bottom)
        .clamp(240.0, double.infinity);
    final maxHeight = (height - 72.0).clamp(180.0, double.infinity);
    return (height * 0.72).clamp(180.0, maxHeight).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _panelColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _panelHeight(context),
          child: Column(
            children: [
              _buildHeader(),
              if (widget.tab == RemoteKeyboardTab.shortcuts)
                Expanded(child: _buildShortcuts())
              else if (widget.tab == RemoteKeyboardTab.computer)
                Expanded(child: _buildComputerKeyboard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tabs = <(RemoteKeyboardTab, String)>[
      (RemoteKeyboardTab.inputMethod, translate('Input method')),
      (RemoteKeyboardTab.shortcuts, translate('Shortcuts')),
      (RemoteKeyboardTab.computer, translate('Computer keyboard')),
    ];

    return SizedBox(
      height: 64,
      child: ColoredBox(
        color: _headerColor,
        child: Row(
          children: [
            for (final (tab, label) in tabs)
              Expanded(
                child: InkWell(
                  onTap: tab == widget.tab
                      ? null
                      : () => widget.onTabSelected(tab),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.tab == tab
                                ? _selectedColor
                                : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 74,
                          height: 2,
                          color: widget.tab == tab
                              ? _selectedColor
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 72,
              child: IconButton(
                tooltip: translate('Close'),
                onPressed: widget.onClose,
                icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcuts() {
    final modifier = widget.isMac ? 'Cmd' : 'Ctrl';
    final usesCommand = widget.isMac;
    final desktopShortcut = widget.isMac ? 'Cmd+F11' : 'Win+D';
    final lockShortcut = widget.isMac ? 'Ctrl+Cmd+Q' : 'Win+L';
    final systemKey = widget.isMac ? 'Cmd' : 'Win';
    final shortcuts = <_RemoteShortcut>[
      _RemoteShortcut('Caps Lock', translate('Caps lock'),
          () => _sendKey('VK_CAPITAL')),
      _RemoteShortcut('$modifier+C', translate('Copy'),
          () => _sendChord('VK_C', ctrl: !usesCommand, command: usesCommand)),
      _RemoteShortcut('$modifier+V', translate('Paste'),
          () => _sendChord('VK_V', ctrl: !usesCommand, command: usesCommand)),
      _RemoteShortcut('$modifier+X', translate('Cut'),
          () => _sendChord('VK_X', ctrl: !usesCommand, command: usesCommand)),
      _RemoteShortcut('$modifier+A', translate('Select All'),
          () => _sendChord('VK_A', ctrl: !usesCommand, command: usesCommand)),
      _RemoteShortcut('$modifier+Z', translate('Undo'),
          () => _sendChord('VK_Z', ctrl: !usesCommand, command: usesCommand)),
      _RemoteShortcut('$modifier+S', translate('Save'),
          () => _sendChord('VK_S', ctrl: !usesCommand, command: usesCommand)),
      _RemoteShortcut(systemKey, translate('Start'), () => _sendKey('Meta')),
      _RemoteShortcut(
        desktopShortcut,
        translate('Show desktop'),
        () => widget.isMac
            ? _sendKey('VK_F11')
            : _sendChord('VK_D', command: true),
      ),
      _RemoteShortcut('$systemKey+Tab', translate('Switch windows'),
          () => _sendChord('VK_TAB', command: true)),
      _RemoteShortcut(lockShortcut, translate('Lock screen'), () {
        if (widget.isMac) {
          _sendChord('VK_Q', ctrl: true, command: true);
        } else {
          _sendKey('LOCK_SCREEN');
        }
      }),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 6
          : constraints.maxWidth >= 620
              ? 5
              : 3;
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(42, 10, 42, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shortcuts.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth >= 620 ? 1.65 : 1.25,
        ),
        itemBuilder: (context, index) {
          final shortcut = shortcuts[index];
          return Material(
            color: _keyColor,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: shortcut.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shortcut.label,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 21),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shortcut.description,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildComputerKeyboard() {
    final commandKeyLabel = widget.isMac ? 'Cmd' : 'Win';
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 190,
                  child: Row(
                    children: [
                      Checkbox(
                        value: _combinedKeyMode,
                        activeColor: _selectedColor,
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        onChanged: _setCombinedKeyMode,
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _setCombinedKeyMode(!_combinedKeyMode),
                          child: Text(
                            translate('Combined key mode'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final modifier in [
                  ('Ctrl', 'VK_CONTROL', _ctrl),
                  ('Shift', 'VK_SHIFT', _shift),
                  ('Alt', 'VK_MENU', _alt),
                  (commandKeyLabel, 'Meta', _command),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _keyCap(
                        modifier.$1,
                        onTap: () => _toggleModifier(modifier.$2),
                        active: modifier.$3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _keyboardPage = page),
            children: [
              _buildKeyPage(_pageOneRows),
              _buildKeyPage(_pageTwoRows),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 7, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var page = 0; page < 2; page++)
                Container(
                  width: 32,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: page == _keyboardPage
                        ? Colors.white
                        : const Color(0xFF77777F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static final _pageOneRows = <List<_KeyboardKey>>[
    [
      for (var key = 1; key <= 9; key++) _KeyboardKey('$key', 'VK_$key'),
      _KeyboardKey('0', 'VK_0'),
    ],
    [for (final key in 'QWERTYUIOP'.split('')) _KeyboardKey(key, 'VK_$key')],
    [
      for (final key in 'ASDFGHJKL'.split('')) _KeyboardKey(key, 'VK_$key'),
      _KeyboardKey('⌫', 'VK_BACK'),
    ],
    [
      _KeyboardKey('Shift', 'VK_SHIFT', flex: 2),
      for (final key in 'ZXCVBNM'.split('')) _KeyboardKey(key, 'VK_$key'),
      _KeyboardKey('Space', 'VK_SPACE', flex: 2),
      _KeyboardKey('Enter', 'VK_ENTER', flex: 2),
    ],
  ];

  static final _pageTwoRows = <List<_KeyboardKey>>[
    [
      _KeyboardKey('-\n_', 'VK_MINUS'),
      _KeyboardKey('+\n=', 'VK_PLUS'),
      _KeyboardKey('[\n{', 'VK_LBRACKET'),
      _KeyboardKey(']\n}', 'VK_RBRACKET'),
      _KeyboardKey('\\\n|', 'VK_BACKSLASH'),
      _KeyboardKey(';\n:', 'VK_SEMICOLON'),
      _KeyboardKey("'\n\"", 'VK_QUOTE'),
      _KeyboardKey('<\n,', 'VK_COMMA'),
      _KeyboardKey('>\n.', 'VK_PERIOD'),
      _KeyboardKey('?\n/', 'VK_SLASH'),
    ],
    [
      for (var key = 1; key <= 4; key++) _KeyboardKey('F$key', 'VK_F$key'),
      _KeyboardKey('PrtScr', 'VK_SNAPSHOT'),
      _KeyboardKey('ScrLk', 'VK_SCROLL'),
      _KeyboardKey('Pause', 'VK_PAUSE'),
      _KeyboardKey('Esc', 'VK_ESCAPE'),
      _KeyboardKey('Tab', 'VK_TAB'),
      _KeyboardKey('~\n`', 'VK_BACKQUOTE'),
    ],
    [
      for (var key = 5; key <= 8; key++) _KeyboardKey('F$key', 'VK_F$key'),
      _KeyboardKey('Ins', 'VK_INSERT'),
      _KeyboardKey('Home', 'VK_HOME'),
      _KeyboardKey('PgUp', 'VK_PRIOR'),
      _KeyboardKey('Caps', 'VK_CAPITAL'),
      _KeyboardKey('▲', 'VK_UP'),
    ],
    [
      for (var key = 9; key <= 12; key++) _KeyboardKey('F$key', 'VK_F$key'),
      _KeyboardKey('Del', 'VK_DELETE'),
      _KeyboardKey('End', 'VK_END'),
      _KeyboardKey('PgDn', 'VK_NEXT'),
      _KeyboardKey('◀', 'VK_LEFT'),
      _KeyboardKey('▼', 'VK_DOWN'),
      _KeyboardKey('▶', 'VK_RIGHT'),
    ],
  ];

  Widget _buildKeyPage(List<List<_KeyboardKey>> rows) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 4, 42, 0),
      child: Column(
        children: [
          for (final row in rows)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        flex: key.flex,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _keyCap(
                            key.label,
                            onTap: () => _sendKey(key.key),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _keyCap(String label,
      {required VoidCallback onTap, bool active = false}) {
    return Material(
      color: active ? const Color(0xFF454552) : _keyColor,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleModifier(String key) {
    if (!_combinedKeyMode) {
      _sendKey(key);
      return;
    }
    setState(() {
      switch (key) {
        case 'VK_CONTROL':
          _ctrl = !_ctrl;
          break;
        case 'VK_SHIFT':
          _shift = !_shift;
          break;
        case 'VK_MENU':
          _alt = !_alt;
          break;
        case 'Meta':
          _command = !_command;
          break;
      }
    });
  }

  void _setCombinedKeyMode(bool? value) {
    setState(() {
      _combinedKeyMode = value ?? false;
      if (!_combinedKeyMode) {
        _ctrl = false;
        _shift = false;
        _alt = false;
        _command = false;
      }
    });
  }

  void _sendKey(String key) {
    final model = widget.inputModel;
    final saved = (model.ctrl, model.shift, model.alt, model.command);
    model.ctrl = saved.$1 || _ctrl;
    model.shift = saved.$2 || _shift;
    model.alt = saved.$3 || _alt;
    model.command = saved.$4 || _command;
    try {
      model.inputKey(key);
    } finally {
      model.ctrl = saved.$1;
      model.shift = saved.$2;
      model.alt = saved.$3;
      model.command = saved.$4;
    }
  }

  void _sendChord(String key, {bool ctrl = false, bool command = false}) {
    final model = widget.inputModel;
    final saved = (model.ctrl, model.shift, model.alt, model.command);
    model.ctrl = saved.$1 || ctrl;
    model.shift = saved.$2;
    model.alt = saved.$3;
    model.command = saved.$4 || command;
    try {
      model.inputKey(key);
    } finally {
      model.ctrl = saved.$1;
      model.shift = saved.$2;
      model.alt = saved.$3;
      model.command = saved.$4;
    }
  }
}

class _RemoteShortcut {
  const _RemoteShortcut(this.label, this.description, this.onPressed);

  final String label;
  final String description;
  final VoidCallback onPressed;
}

class _KeyboardKey {
  const _KeyboardKey(this.label, this.key, {this.flex = 1});

  final String label;
  final String key;
  final int flex;
}
