import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../auth_provider.dart';
import '../comments_provider.dart';
import '../models.dart';
import '../profile_provider.dart';
import '../screens/profile_screen.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.post});
  final Post post;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    setState(() => _sending = true);
    try {
      await api.addComment(userId, widget.post.id, text);
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post comment: $e')),
        );
      }
      return;
    }

    _controller.clear();
    ref.invalidate(commentsProvider(widget.post.id));
    try {
      await ref.read(commentsProvider(widget.post.id).future);
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.post.id));
    final user = ref.watch(authProvider).user;
    final myAvatar = user == null
        ? null
        : ref.watch(userProfileProvider(user.id)).maybeWhen(
              data: (u) => u.profilePicUrl,
              orElse: () => user.profilePicUrl,
            );

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                PostCard(post: widget.post),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Comments',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                comments.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load comments: $err'),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text('No comments yet.'),
                      );
                    }
                    return Column(
                      children: [
                        for (final c in list) _CommentTile(comment: c),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (user != null)
            _CommentInputBar(
              controller: _controller,
              sending: _sending,
              avatarUrl: myAvatar,
              onSend: _send,
            ),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.sending,
    required this.avatarUrl,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final String? avatarUrl;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPic = avatarUrl != null && avatarUrl!.isNotEmpty;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: color, width: width),
        );

    return Material(
      color: scheme.surface,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: hasPic ? NetworkImage(avatarUrl!) : null,
                  child: hasPic ? null : const Icon(Icons.person, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: sending,
                  minLines: 1,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 16),
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(
                        fontSize: 16, color: scheme.onSurfaceVariant),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    border: border(scheme.outlineVariant),
                    enabledBorder: border(scheme.outlineVariant),
                    focusedBorder: border(scheme.primary, 2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend = value.text.trim().isNotEmpty && !sending;
                  return SizedBox(
                    width: 52,
                    height: 52,
                    child: sending
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : IconButton.filled(
                            iconSize: 26,
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              fixedSize: const Size(52, 52),
                              minimumSize: const Size(52, 52),
                            ),
                            onPressed: canSend ? onSend : null,
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final hasPic =
        comment.profilePicUrl != null && comment.profilePicUrl!.isNotEmpty;
    return ListTile(
      dense: true,
      onTap: comment.userId == 0
          ? null
          : () => openProfile(context, comment.userId),
      leading: CircleAvatar(
        radius: 16,
        backgroundImage: hasPic ? NetworkImage(comment.profilePicUrl!) : null,
        child: hasPic ? null : const Icon(Icons.person, size: 18),
      ),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: comment.fullName.isNotEmpty
                  ? comment.fullName
                  : comment.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '  '),
            TextSpan(text: comment.comment),
          ],
        ),
      ),
    );
  }
}