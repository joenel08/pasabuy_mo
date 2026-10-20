import '../core/api_client.dart';
import '../models/post.dart';

class FavoriteService {
  final ApiClient _api;
  FavoriteService(this._api);

  Future<List<Post>> list() async {
    final res = await _api.dio.get('/me/favorites');
    final inner = res.data['data'];
    final list = inner is Map ? inner['data'] : null;
    if (list is! List) return const [];
    return list.whereType<Map>()
        .map((m) => Post.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  Future<bool> toggle(int postId) async {
    final res = await _api.dio.post('/me/favorites/toggle', data: {'post_id': postId});
    return res.data['data']['saved'] == true;
  }
}