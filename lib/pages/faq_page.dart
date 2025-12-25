import 'package:flutter/material.dart';
import 'dart:async';

class FaqChatModal {
  static void show(BuildContext context, List<dynamic> faqItems) {
    final Map<String, List<dynamic>> categorizedFaqs = {};
    for (var faq in faqItems) {
      final category = faq['category'] ?? 'General';
      categorizedFaqs.putIfAbsent(category, () => []).add(faq);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String? selectedCategory;
        dynamic selectedFaq;
        List<Map<String, String>> chatMessages = [];
        bool isTyping = false;
        final ScrollController scrollController = ScrollController();

        void scrollToBottom() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }

        void sendAnswer(Function setState, String answer) async {
          setState(() => isTyping = true);
          await Future.delayed(const Duration(milliseconds: 700));
          setState(() {
            chatMessages.add({'sender': 'bot', 'text': answer});
            isTyping = false;
          });
          scrollToBottom();
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, _) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFe3f2fd), Color(0xFFbbdefb)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 6,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const Text(
                          '💬 Frequently Asked Questions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0d47a1),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Step 1: Categories
                        if (selectedCategory == null)
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              children: categorizedFaqs.keys.map((category) {
                                return Card(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 3,
                                  child: ListTile(
                                    leading: const Icon(Icons.folder_open_rounded,
                                        color: Color(0xFF1565c0)),
                                    title: Text(
                                      category,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: Color(0xFF1565c0)),
                                    onTap: () {
                                      setState(() {
                                        selectedCategory = category;
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // Step 2: Questions
                        if (selectedCategory != null && selectedFaq == null)
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              children: categorizedFaqs[selectedCategory]!
                                  .map((faq) {
                                return Card(
                                  color: Colors.white.withOpacity(0.95),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: const Icon(Icons.help_outline_rounded,
                                        color: Color(0xFF0d47a1)),
                                    title: Text(
                                      faq['question'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedFaq = faq;
                                        chatMessages = [
                                          {'sender': 'user', 'text': faq['question']}
                                        ];
                                      });
                                      sendAnswer(setState, faq['answer']);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // Step 3: Chat
                        if (selectedFaq != null)
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: chatMessages.length + (isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (isTyping && index == chatMessages.length) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      margin:
                                          const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Typing... 💭'),
                                    ),
                                  );
                                }

                                final msg = chatMessages[index];
                                final isUser = msg['sender'] == 'user';
                                return Align(
                                  alignment: isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width *
                                            0.75),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? const Color(0xFF90caf9)
                                          : Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 3,
                                          offset: const Offset(1, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : Colors.grey.shade900,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Back / Close Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              if (selectedFaq != null) {
                                setState(() {
                                  selectedFaq = null;
                                  chatMessages = [];
                                });
                              } else if (selectedCategory != null) {
                                setState(() {
                                  selectedCategory = null;
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            
                            label: Text(
                              selectedFaq != null || selectedCategory != null
                                  ? 'Back'
                                  : 'Close',
                              style: const TextStyle(
                                  fontSize: 16, color: Color(0xFF0d47a1)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
