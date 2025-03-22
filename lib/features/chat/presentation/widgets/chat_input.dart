import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_ui_providers.dart';
import '../../data/providers/auth_providers.dart';

class ChatInput extends ConsumerStatefulWidget {
  final String chatRoomId;

  const ChatInput({
    Key? key,
    required this.chatRoomId,
  }) : super(key: key);

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _isComposing = false;
  bool _isButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isComposing = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || !_isButtonEnabled) return;

    final content = _controller.text.trim();
    setState(() {
      _isButtonEnabled = false;
      _isSending = true;
    });

    try {
      // 使用 SendMessage 用例发送消息
      final sendMessage = ref.read(sendMessageProvider);

      // 获取当前用户信息
      final currentUser = ref.read(currentUserProvider).value;

      // 执行发送消息
      final result = await sendMessage.execute(
        widget.chatRoomId,
        content,
        MessageType.text,
        currentUser?.id ?? '',
      );

      result.fold((failure) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('发送失败：${failure.message ?? "未知错误"}')));
      }, (message) {
        // 发送成功，清空输入框
        _controller.clear();

        // 刷新消息列表 (可选，因为实时消息流会自动更新UI)
        ref.invalidate(chatMessagesProvider(widget.chatRoomId));
      });
    } catch (e, stackTrace) {
      print('发送消息错误: $e');
      print('堆栈信息: $stackTrace');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('发送错误：${e.toString()}')));
    } finally {
      setState(() {
        _isSending = false;
        _isButtonEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听连接状态
    final connectionState = ref.watch(authConnectionStateProvider);
    final isConnected = connectionState.maybeWhen(
      data: (connected) => connected,
      orElse: () => false,
    );

    print('连接状态: $isConnected');

    return Column(
      children: [
        // 预览栏 - 可以放表情选择器、附件等
        if (_focusNode.hasFocus)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.withOpacity(0.6),
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.systemGrey4,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.photo),
                  onPressed: isConnected ? () {} : null,
                  color: CupertinoColors.systemBlue,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.camera),
                  onPressed: isConnected ? () {} : null,
                  color: CupertinoColors.systemBlue,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.mic),
                  onPressed: isConnected ? () {} : null,
                  color: CupertinoColors.systemBlue,
                ),
              ],
            ),
          ),

        // 主输入栏
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            border: Border(
              top: BorderSide(
                color: CupertinoColors.systemGrey4,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: 8.0,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 8.0, // 适配底部安全区域
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, // 底部对齐
            children: [
              // 附件按钮
              _buildCupertinoButton(
                icon: CupertinoIcons.paperclip,
                onPressed: isConnected
                    ? () {
                        // 实现附件选择逻辑
                      }
                    : null,
              ),

              // 文本输入框 - 使用 CupertinoTextField
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: CupertinoColors.systemGrey4,
                      width: 0.5,
                    ),
                  ),
                  child: CupertinoTextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: isConnected,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    placeholder: '输入消息...',
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // 发送按钮
              _isSending
                  ? const CupertinoActivityIndicator()
                  : _buildCupertinoButton(
                      icon: _isComposing
                          ? CupertinoIcons.arrow_up_circle_fill
                          : CupertinoIcons.mic_fill,
                      color: CupertinoColors.systemBlue,
                      onPressed:
                          _isComposing && isConnected ? _sendMessage : null,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCupertinoButton({
    required IconData icon,
    Color? color,
    VoidCallback? onPressed,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.all(4.0),
      onPressed: onPressed,
      child: Icon(
        icon,
        color: onPressed == null
            ? CupertinoColors.systemGrey
            : color ?? CupertinoColors.systemGrey,
        size: 24,
      ),
    );
  }
}
