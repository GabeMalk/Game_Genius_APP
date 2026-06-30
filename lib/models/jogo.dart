// ============================================================
// ARQUIVO: lib/models/jogo.dart
// Modelo de dados de um jogo. Note que "generos" agora é uma
// List<Genero> — um jogo pode ter quantos quiser.
// ============================================================
import 'genero.dart';

class Jogo {
  final String nome;
  final List<Genero> generos;
  final String sinopse;
  final String imagemUrl;
  final String linkLoja;

  const Jogo({
    required this.nome,
    required this.generos,
    required this.sinopse,
    required this.imagemUrl,
    required this.linkLoja,
  });

  // Texto pronto pra exibir os gêneros juntos, ex: "RPG • Mundo Aberto"
  String get generosLabel => generos.map((g) => g.label).join(' • ');
}