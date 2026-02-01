import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/live_format_service.dart';

final liveFormatServiceProvider = Provider<LiveFormatService>(
  (ref) => LiveFormatService(),
);
