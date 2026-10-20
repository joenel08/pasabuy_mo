import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/post_service.dart';

class FeedController extends ChangeNotifier {
  final PostService _service;
  FeedController(this._service);

  List<Post> posts = [];
  bool loading = false;
  String? error;

  String search = '';
  String? type;
  String? status;
  DateTime? dateFrom;
  DateTime? dateTo;
  String? location;
  bool mine = false;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _service.fetch(
        search: search,
        type: type,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
        location: location,
        mine: mine,
      );
      posts = result;
      debugPrint('[FEED] loaded ${result.length} (mine=$mine status=$status)');
    } catch (e) {
      error = e.toString();
      debugPrint('[FEED] error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void resetFilters() {
    search = '';
    type = null;
    status = null;
    dateFrom = null;
    dateTo = null;
    location = null;
    mine = false;
  }

  void applyFilters({
    String? search,
    String? type,
    String? status,
    DateTime? from,
    DateTime? to,
    String? location,
    bool? mine,
  }) {
    if (search != null) this.search = search;
    if (type != null) this.type = type;
    if (status != null) this.status = status;
    if (location != null) this.location = location;
    if (mine != null) this.mine = mine;
    if (from != null) dateFrom = from;
    if (to != null) dateTo = to;
    load();
  }

  void clearFilters() {
    resetFilters();
    load();
  }
}