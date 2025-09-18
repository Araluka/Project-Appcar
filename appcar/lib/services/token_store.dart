// lib/services/token_store.dart
// เลือกไฟล์ให้เหมาะกับแพลตฟอร์มอัตโนมัติ
export 'token_store_io.dart' if (dart.library.html) 'token_store_web.dart';
