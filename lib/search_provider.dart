
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'models.dart';

final searchProvider =
    FutureProvider.autoDispose.family<SearchResults, String>((ref, term) {
  return api.search(term);
});