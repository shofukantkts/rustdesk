import 'dart:async';
import 'dart:math' as math;

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
    required this.isLinux,
    required this.onTabSelected,
    required this.onClose,
    required this.onHeightChanged,
  });

  final RemoteKeyboardTab tab;
  final InputModel inputModel;
  final bool isMac;
  final bool isLinux;
  final ValueChanged<RemoteKeyboardTab> onTabSelected;
  final VoidCallback onClose;
  final ValueChanged<double> onHeightChanged;

  @override
  State<RemoteKeyboardPanel> createState() => _RemoteKeyboardPanelState();
}

class _RemoteKeyboardPanelState extends State<RemoteKeyboardPanel> {
  static const _headerHeight = 56.0;
  static const _headerColor = Color(0xFF272730);
  static const _panelColor = Color(0xFF050509);
  static const _keyColor = Color(0xFF282830);
  static const _selectedColor = Color(0xFF5A9BFF);
  static const _shiftedKeys = <String, String>{
    'VK_1': '!',
    'VK_2': '@',
    'VK_3': '#',
    'VK_4': '\$',
    'VK_5': '%',
    'VK_6': '^',
    'VK_7': '&',
    'VK_8': '*',
    'VK_9': '(',
    'VK_0': ')',
    'VK_A': 'A',
    'VK_B': 'B',
    'VK_C': 'C',
    'VK_D': 'D',
    'VK_E': 'E',
    'VK_F': 'F',
    'VK_G': 'G',
    'VK_H': 'H',
    'VK_I': 'I',
    'VK_J': 'J',
    'VK_K': 'K',
    'VK_L': 'L',
    'VK_M': 'M',
    'VK_N': 'N',
    'VK_O': 'O',
    'VK_P': 'P',
    'VK_Q': 'Q',
    'VK_R': 'R',
    'VK_S': 'S',
    'VK_T': 'T',
    'VK_U': 'U',
    'VK_V': 'V',
    'VK_W': 'W',
    'VK_X': 'X',
    'VK_Y': 'Y',
    'VK_Z': 'Z',
    'VK_MINUS': '_',
    'VK_PLUS': '+',
    'VK_LBRACKET': '{',
    'VK_RBRACKET': '}',
    'VK_BACKSLASH': '|',
    'VK_SEMICOLON': ':',
    'VK_QUOTE': '"',
    'VK_COMMA': '<',
    'VK_PERIOD': '>',
    'VK_SLASH': '?',
    'VK_BACKQUOTE': '~',
  };

  final PageController _pageController = PageController();
  int _keyboardPage = 0;
  bool _combinedKeyMode = false;
  double? _reportedHeight;
  Timer? _keyRepeatTimer;

  bool get _hasActiveModifiers =>
      widget.inputModel.ctrl ||
      widget.inputModel.shift ||
      widget.inputModel.alt ||
      widget.inputModel.command;

  @override
  void initState() {
    super.initState();
    _combinedKeyMode = _hasActiveModifiers;
  }

  @override
  void dispose() {
    _keyRepeatTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  double _panelHeight(BuildContext context) {
    if (widget.tab == RemoteKeyboardTab.inputMethod) return _headerHeight;
    final media = MediaQuery.of(context);
    final availableHeight =
        math.max(0.0, media.size.height - media.viewInsets.bottom);
    final portrait = media.size.height > media.size.width;
    final maxHeight = math.max(_headerHeight, availableHeight - 72.0);
    final preferredHeight = math.min(
        availableHeight * (portrait ? 0.58 : 0.72), portrait ? 520.0 : 360.0);
    final minimumHeight = math.min(portrait ? 360.0 : 220.0, maxHeight);
    return preferredHeight.clamp(minimumHeight, maxHeight).toDouble();
  }

  void _reportHeight(BuildContext context, double panelHeight) {
    final height = panelHeight + MediaQuery.paddingOf(context).bottom;
    if (_reportedHeight == height) return;
    _reportedHeight = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reportedHeight == height) {
        widget.onHeightChanged(height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight = _panelHeight(context);
    _reportHeight(context, panelHeight);
    return ColoredBox(
      color: _panelColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: panelHeight,
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
      height: _headerHeight,
      child: ColoredBox(
        color: _headerColor,
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return Row(
            children: [
              for (final (tab, label) in tabs)
                Expanded(
                  child: InkWell(
                    onTap: tab == widget.tab
                        ? null
                        : () => widget.onTabSelected(tab),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: compact ? 4 : 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: TextStyle(
                                color: widget.tab == tab
                                    ? _selectedColor
                                    : Colors.white,
                                fontSize: compact ? 15 : 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: compact ? 40 : 64,
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
                width: compact ? 48 : 56,
                child: IconButton(
                  tooltip: translate('Close'),
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildShortcuts() {
    final modifier = widget.isMac ? 'Cmd' : 'Ctrl';
    final usesCommand = widget.isMac;
    final systemKey = widget.isMac
        ? 'Cmd'
        : widget.isLinux
            ? 'Super'
            : 'Win';
    final desktopShortcut = widget.isMac ? 'F11' : '$systemKey+D';
    final lockShortcut = widget.isMac ? 'Ctrl+Cmd+Q' : '$systemKey+L';
    final switchShortcut = widget.isMac ? 'Cmd+Tab' : 'Alt+Tab';
    final shortcuts = <_RemoteShortcut>[
      _RemoteShortcut('Caps Lock', translate('Caps lock'),
          () => _sendShortcutKey('VK_CAPITAL')),
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
      if (!widget.isMac)
        _RemoteShortcut(systemKey, translate(widget.isLinux ? 'Apps' : 'Start'),
            () => _sendShortcutKey('Meta')),
      _RemoteShortcut(
        desktopShortcut,
        translate('Show desktop'),
        () => widget.isMac
            ? _sendShortcutKey('VK_F11')
            : _sendChord('VK_D', command: true),
      ),
      _RemoteShortcut(
          switchShortcut,
          translate('Switch windows'),
          () => widget.isMac
              ? _sendChord('VK_TAB', command: true)
              : _sendChord('VK_TAB', alt: true)),
      _RemoteShortcut(lockShortcut, translate('Lock screen'), () {
        if (widget.isMac) {
          _sendChord('VK_Q', ctrl: true, command: true);
        } else {
          _sendShortcutKey('LOCK_SCREEN');
        }
      }),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 6
          : constraints.maxWidth >= 700
              ? 5
              : constraints.maxWidth >= 480
                  ? 4
                  : 3;
      final compact = constraints.maxWidth < 600;
      return GridView.builder(
        padding:
            EdgeInsets.fromLTRB(compact ? 8 : 32, 10, compact ? 8 : 32, 24),
        physics: const BouncingScrollPhysics(),
        itemCount: shortcuts.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: compact ? 1.35 : 1.65,
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 21),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shortcut.description,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
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
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final sidePadding = compact ? 6.0 : 42.0;
      final keySpacing = compact ? 2.0 : 4.0;
      return Column(
        children: [
          _buildKeyboardControls(compact, sidePadding, keySpacing),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _keyboardPage = page),
              children: [
                _buildKeyPage(_pageOneRows, sidePadding, keySpacing),
                _buildKeyPage(_pageTwoRows, sidePadding, keySpacing),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 7, top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var page = 0; page < 2; page++)
                  GestureDetector(
                    onTap: () => _pageController.animateToPage(page,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut),
                    child: Container(
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
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildKeyboardControls(
      bool compact, double sidePadding, double keySpacing) {
    final commandKeyLabel = widget.isMac
        ? 'Cmd'
        : widget.isLinux
            ? 'Super'
            : 'Win';
    final modifierRow = Row(
      children: [
        for (final modifier in [
          ('Ctrl', 'VK_CONTROL', widget.inputModel.ctrl),
          ('Shift', 'VK_SHIFT', widget.inputModel.shift),
          ('Alt', 'VK_MENU', widget.inputModel.alt),
          (commandKeyLabel, 'Meta', widget.inputModel.command),
        ])
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: keySpacing),
              child: _keyCap(
                modifier.$1,
                onTap: () => _toggleModifier(modifier.$2),
                active: modifier.$3,
              ),
            ),
          ),
      ],
    );

    if (compact) {
      return SizedBox(
        height: 82,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 2),
          child: Column(
            children: [
              SizedBox(height: 36, child: _buildCombinedKeyToggle()),
              Expanded(child: modifierRow),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 190, child: _buildCombinedKeyToggle()),
            Expanded(child: modifierRow),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedKeyToggle() {
    return Row(
      children: [
        Checkbox(
          value: _combinedKeyMode,
          activeColor: _selectedColor,
          checkColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: _setCombinedKeyMode,
        ),
        Expanded(
          child: InkWell(
            onTap: () => _setCombinedKeyMode(!_combinedKeyMode),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                translate('Combined key mode'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
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
      _KeyboardKey('⌫', 'VK_BACK', repeat: true),
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
      _KeyboardKey('_\n-', 'VK_MINUS'),
      _KeyboardKey('+\n=', 'VK_PLUS'),
      _KeyboardKey('{\n[', 'VK_LBRACKET'),
      _KeyboardKey('}\n]', 'VK_RBRACKET'),
      _KeyboardKey('|\n\\', 'VK_BACKSLASH'),
      _KeyboardKey(':\n;', 'VK_SEMICOLON'),
      _KeyboardKey("\"\n'", 'VK_QUOTE'),
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
      _KeyboardKey('▲', 'VK_UP', repeat: true),
    ],
    [
      for (var key = 9; key <= 12; key++) _KeyboardKey('F$key', 'VK_F$key'),
      _KeyboardKey('Del', 'VK_DELETE', repeat: true),
      _KeyboardKey('End', 'VK_END'),
      _KeyboardKey('PgDn', 'VK_NEXT'),
      _KeyboardKey('◀', 'VK_LEFT', repeat: true),
      _KeyboardKey('▼', 'VK_DOWN', repeat: true),
      _KeyboardKey('▶', 'VK_RIGHT', repeat: true),
    ],
  ];

  Widget _buildKeyPage(
      List<List<_KeyboardKey>> rows, double sidePadding, double keySpacing) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sidePadding, 4, sidePadding, 0),
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
                          padding: EdgeInsets.symmetric(horizontal: keySpacing),
                          child: _keyCap(
                            key.label,
                            onTap: () => key.key == 'VK_SHIFT'
                                ? _toggleModifier(key.key)
                                : _sendKey(key.key),
                            active: key.key == 'VK_SHIFT' &&
                                widget.inputModel.shift,
                            repeat: key.repeat,
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
      {required VoidCallback onTap, bool active = false, bool repeat = false}) {
    return Listener(
      onPointerUp: repeat ? (_) => _stopKeyRepeat() : null,
      onPointerCancel: repeat ? (_) => _stopKeyRepeat() : null,
      child: Material(
        color: active ? _selectedColor : _keyColor,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          onLongPress: repeat ? () => _startKeyRepeat(onTap) : null,
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
      ),
    );
  }

  void _startKeyRepeat(VoidCallback action) {
    _keyRepeatTimer?.cancel();
    action();
    _keyRepeatTimer =
        Timer.periodic(const Duration(milliseconds: 75), (_) => action());
  }

  void _stopKeyRepeat() {
    _keyRepeatTimer?.cancel();
    _keyRepeatTimer = null;
  }

  void _toggleModifier(String key) {
    if (!_combinedKeyMode) {
      _sendKey(key);
      return;
    }
    setState(() {
      switch (key) {
        case 'VK_CONTROL':
          widget.inputModel.ctrl = !widget.inputModel.ctrl;
          break;
        case 'VK_SHIFT':
          widget.inputModel.shift = !widget.inputModel.shift;
          break;
        case 'VK_MENU':
          widget.inputModel.alt = !widget.inputModel.alt;
          break;
        case 'Meta':
          widget.inputModel.command = !widget.inputModel.command;
          break;
      }
    });
  }

  void _setCombinedKeyMode(bool? value) {
    setState(() {
      _combinedKeyMode = value ?? false;
      if (!_combinedKeyMode) {
        widget.inputModel.ctrl = false;
        widget.inputModel.shift = false;
        widget.inputModel.alt = false;
        widget.inputModel.command = false;
      }
    });
  }

  void _sendKey(String key) {
    final model = widget.inputModel;
    final isPlainShift =
        model.shift && !model.ctrl && !model.alt && !model.command;
    model.inputKey(isPlainShift ? (_shiftedKeys[key] ?? key) : key);
  }

  void _sendShortcutKey(String key) {
    final model = widget.inputModel;
    final saved = (model.ctrl, model.shift, model.alt, model.command);
    model.ctrl = false;
    model.shift = false;
    model.alt = false;
    model.command = false;
    try {
      model.inputKey(key);
    } finally {
      model.ctrl = saved.$1;
      model.shift = saved.$2;
      model.alt = saved.$3;
      model.command = saved.$4;
    }
  }

  void _sendChord(String key,
      {bool ctrl = false, bool alt = false, bool command = false}) {
    final model = widget.inputModel;
    final saved = (model.ctrl, model.shift, model.alt, model.command);
    model.ctrl = ctrl;
    model.shift = false;
    model.alt = alt;
    model.command = command;
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
  const _KeyboardKey(this.label, this.key,
      {this.flex = 1, this.repeat = false});

  final String label;
  final String key;
  final int flex;
  final bool repeat;
}
