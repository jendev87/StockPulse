import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/ai_api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ManagerAiSheet extends StatefulWidget {
  final String stockTakeId;
  final AiApiService? aiService;

  const ManagerAiSheet({
    super.key,
    required this.stockTakeId,
    this.aiService,
  });

  static Future<void> show(
    BuildContext context, {
    required String stockTakeId,
    AiApiService? aiService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManagerAiSheet(
        stockTakeId: stockTakeId,
        aiService: aiService,
      ),
    );
  }

  @override
  State<ManagerAiSheet> createState() => _ManagerAiSheetState();
}

class _ManagerAiSheetState extends State<ManagerAiSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AiApiService _aiService;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  static const List<String> _quickPrompts = [
    'Which items are short?',
    'Show me all surpluses',
    'Summarize inventory accuracy',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiApiService.instance;

    // Welcome message
    _messages.add(
      ChatMessage(
        text:
            'Hello Manager! I am your StockPulse Copilot.\n\nI can analyze physical variances, shortages, surpluses, and overall audit accuracy for session #${widget.stockTakeId} in real time. Ask me a question or tap a quick prompt below!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: trimmed,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final answer = await _aiService.askManagerAssistant(
        question: trimmed,
        stockTakeId: widget.stockTakeId,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: answer,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Error querying assistant: $e',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: const Color(0xFF333B4A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✨ StockPulse Copilot',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.statusMatch,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Auditing Session #${widget.stockTakeId}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  tooltip: 'Close Copilot',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF2C3240)),

          // Quick Prompt Recommendation Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF161A22),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      elevation: 0,
                      pressElevation: 1,
                      backgroundColor: AppTheme.surfaceCard,
                      side: BorderSide(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      avatar: const Icon(
                        Icons.bolt,
                        size: 15,
                        color: AppTheme.statusSurplus,
                      ),
                      label: Text(
                        prompt,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _isLoading ? null : () => _sendMessage(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Loading indicator indicator row
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Copilot is querying audit discrepancies...',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 10,
              bottom: media.viewInsets.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(
                top: BorderSide(color: Color(0xFF2C3240), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121418),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF333B4A)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        decoration: const InputDecoration(
                          hintText: 'Ask Copilot anything about this audit...',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppTheme.primaryBlue,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isLoading
                          ? null
                          : () => _sendMessage(_textController.text),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
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

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFF2C3240)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryBlue,
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  'StockPulse Copilot',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(msg.timestamp),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              msg.text,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
