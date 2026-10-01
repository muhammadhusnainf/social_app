import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../search_provider.dart';
import '../widgets/post_card.dart';
import 'profile_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(text));
  }

  void _run(String text) {
    _debounce?.cancel();
    final term = text.trim();
    if (term != _query) setState(() => _query = term);
  }

  void _clear() {
    _controller.clear();
    _run('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _run,
            decoration: InputDecoration(
              hintText: 'Search people and posts',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close), onPressed: _clear),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(child: _results()),
      ],
    );
  }

  Widget _results() {
    if (_query.isEmpty) {
      return const Center(child: Text('Type something to search.'));
    }

    final results = ref.watch(searchProvider(_query));
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Search failed: $err')),
      data: (data) {
        if (data.isEmpty) {
          return Center(child: Text('No results for "$_query".'));
        }
        return ListView(
          children: [
            if (data.users.isNotEmpty) ...[
              const _SectionHeader('People'),
              for (final u in data.users) _UserTile(user: u),
            ],
            if (data.posts.isNotEmpty) ...[
              const _SectionHeader('Posts'),
              for (final p in data.posts) ...[
                PostCard(post: p, interactive: true),
                const SizedBox(height: 16),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final hasPic = user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: hasPic ? NetworkImage(user.profilePicUrl!) : null,
        child: hasPic ? null : const Icon(Icons.person),
      ),
      title: Text(user.fullName.isNotEmpty ? user.fullName : user.username),
      subtitle: Text('@${user.username}'),
      onTap: () => openProfile(context, user.id),
    );
  }
}