// ============================================================
// ARQUIVO: lib/main.dart
// Ponto de entrada do app. Fica fino de propósito — toda a
// lógica da tela está em screens/tela_recomendacao.dart
// ============================================================
import 'package:flutter/material.dart';
import 'screens/tela_recomendacao.dart';

void main() {
  runApp(const MaterialApp(
    home: TelaRecomendacao(),
    debugShowCheckedModeBanner: false,
  ));
}