import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiz_app/app.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  await Firebase.initializeApp();
  runApp(MyApp());
}
