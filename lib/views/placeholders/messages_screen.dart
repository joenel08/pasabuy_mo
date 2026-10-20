import 'package:flutter/material.dart';

import '../../core/translations.dart';
import '../common/empty_state.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(T.of(context, 'messages'))),
      body: EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: T.of(context, 'no_messages_yet'),
        subtitle: T.of(context, 'no_messages_sub'),
      ),
    );
  }
}