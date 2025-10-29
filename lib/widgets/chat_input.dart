import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () {
                        _showAttachmentOptions(context);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Сообщение',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {
                        _showEmojiPicker(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Прикрепить файл',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'Фото',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Pick photo
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam,
                    label: 'Видео',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Pick video
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.audiotrack,
                    label: 'Аудио',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Record audio
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'Файл',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Pick file
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final emojis = [
      '😀','😁','😂','🤣','😊','😍','😘','😎','🤩','🤔','🤗','🤝','👍','👎','👏','🙏','🔥','💯','✨','🎉','🥳','❤️','💙','💚','💛','💜','🖤','🤍','🤎','😇','😅','😌','🙃','😉','😏','😴','😪','🤤','😷','🤒','🤕','🤧','🤠','😈','👻','💀','👀','🙈','🙉','🙊','🐶','🐱','🐼','🐨','🐧','🐸'
    ];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 260,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                final emoji = emojis[index];
                return InkWell(
                  onTap: () {
                    _insertEmoji(emoji);
                  },
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _insertEmoji(String emoji) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
