
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'models.dart';

final commentsProvider =
    FutureProvider.autoDispose.family<List<Comment>, int>((ref, postId) async {
  final raw = await api.getComments(postId);
  return raw
      .whereType<Map>()
      .map((e) => Comment.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});