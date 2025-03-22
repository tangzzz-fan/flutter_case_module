import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  /// 发送消息的回调函数
  final Function(String) onSendMessage;

  /// 附加功能按钮的回调函数（可选）
  final VoidCallback? onAttachmentPressed;

  /// 输入框提示文本
  final String hintText;

  /// 发送按钮颜色
  final Color sendButtonColor;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    this.onAttachmentPressed,
    this.hintText = '输入消息...',
    this.sendButtonColor = Colors.blue,
  }) : super(key: key);

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    // 监听文本变化以更新发送按钮状态
    _textController.addListener(_updateSendButtonState);
  }

  /// 更新发送按钮的可用状态
  void _updateSendButtonState() {
    final canSend = _textController.text.isNotEmpty;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  /// 发送消息并清空输入框
  void _handleSend() {
    if (_canSend) {
      widget.onSendMessage(_textController.text);
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_updateSendButtonState);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用MediaQuery获取底部安全区域的高度
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // 使用Theme获取当前主题颜色
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 3,
          )
        ],
      ),
      child: Row(
        children: [
          // 附加功能按钮
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加附件',
            onPressed: widget.onAttachmentPressed ??
                () {
                  // 如果没有提供回调，则显示一个提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('附件功能暂未实现')),
                  );
                },
          ),
          // 可扩展的文本输入框
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ??
                    theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          // 发送按钮
          IconButton(
            icon: Icon(
              Icons.send,
              color: _canSend ? widget.sendButtonColor : theme.disabledColor,
            ),
            tooltip: '发送消息',
            onPressed: _canSend ? _handleSend : null,
          ),
        ],
      ),
    );
  }
}
