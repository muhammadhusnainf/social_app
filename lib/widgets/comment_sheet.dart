import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../auth_provider.dart';
import '../comments_provider.dart';
import '../profile_provider.dart';
import 'comment_input_bar.dart';

Future<void> showCommentSheet(BuildContext context, int postId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CommentSheet(postId: postId),
  );
}

class _CommentSheet extends ConsumerStatefulWidget {
  const _CommentSheet({required this.postId});
  final int postId;

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final userId = ref.read(authProvider).user?.id;
    if (text.isEmpty || userId == null || _sending) return;

    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await api.addComment(userId, widget.postId, text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Could not post comment: $e';
        });
      }
      return;
    }

    container.invalidate(commentsProvider(widget.postId));
    if (mounted) navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Comment posted'),
        duration: Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).user;
    if (me == null) return const SizedBox.shrink();

    final avatarUrl = ref.watch(userProfileProvider(me.id)).maybeWhen(
          data: (u) => u.profilePicUrl,
          orElse: () => me.profilePicUrl,
        );

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          CommentInputBar(
            controller: _controller,
            sending: _sending,
            avatarUrl: avatarUrl,
            onSend: _send,
            autofocus: true,
          ),
        ],
      ),
    );
  }
}