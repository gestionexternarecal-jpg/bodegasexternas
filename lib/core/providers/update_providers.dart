import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/update_check_service.dart';

final updateCheckServiceProvider = Provider<UpdateCheckService>((ref) {
  return UpdateCheckService();
});

final appVersionLabelProvider = FutureProvider<String>((ref) async {
  return ref.watch(updateCheckServiceProvider).formatVersionLabel();
});
