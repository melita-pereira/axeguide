import 'package:hive/hive.dart';

// Don't open boxes at import time. Use getters so boxes are accessed after
// `Hive.openBox(...)` is completed (for example in `main()` before runApp()).
Box<dynamic> get locationCache => Hive.box('locationCache');
Box<dynamic> get userBox => Hive.box('userBox');