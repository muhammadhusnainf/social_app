
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'models.dart';

final userProfileProvider =
    FutureProvider.autoDispose.family<AppUser, int>((ref, userId) {
  return api.getUser(userId);
});

final userPostsProvider =
    FutureProvider.autoDispose.family<List<Post>, int>((ref, userId) {
  return api.getUserPosts(userId);
});