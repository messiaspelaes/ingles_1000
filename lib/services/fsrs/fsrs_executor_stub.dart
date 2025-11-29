abstract class FsrsExecutor {
  Future<void> initialize();
  Future<Map<String, dynamic>?> evaluate(Map<String, dynamic> params);
  void dispose();
}

