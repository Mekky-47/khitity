import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GiyasAIApp(),
    ),
  );
}
