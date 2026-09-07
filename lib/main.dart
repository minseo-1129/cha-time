import 'package:flutter/material.dart';

import 'cha_time_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ChaTimeFonts.loadVoice();
  runApp(const ChaTimeApp());
}
