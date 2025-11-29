import 'fsrs_executor_stub.dart';
import 'fsrs_executor_native.dart' if (dart.library.html) 'fsrs_executor_web.dart';

export 'fsrs_executor_stub.dart';

// Factory global
FsrsExecutor getFsrsExecutor() {
  return getExecutor();
}

