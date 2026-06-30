// ============================================================
// ARQUIVO: lib/models/genero.dart
// Enum dos gêneros possíveis. Centralizar aqui significa que,
// se um dia você adicionar/remover um gênero, só precisa
// editar este arquivo — o resto do app (filtros, cards, etc.)
// já se ajusta automaticamente.
// ============================================================
enum Genero {
  acao,
  aventura,
  rpg,
  roguelike,
  metroidvania,
  mundoAberto,
  estrategia,
  simulacao,
  terror,
  misterio,
  fazendinha,
  plataforma,
  indie,
}

// Extensão pra dar um "label" bonito em português pra cada valor.
// Assim a gente nunca mistura "lógica" (o enum) com "exibição" (o texto).
extension GeneroLabel on Genero {
  String get label {
    switch (this) {
      case Genero.acao:
        return 'Ação';
      case Genero.aventura:
        return 'Aventura';
      case Genero.rpg:
        return 'RPG';
      case Genero.roguelike:
        return 'Roguelike';
      case Genero.metroidvania:
        return 'Metroidvania';
      case Genero.mundoAberto:
        return 'Mundo Aberto';
      case Genero.estrategia:
        return 'Estratégia';
      case Genero.simulacao:
        return 'Simulação';
      case Genero.terror:
        return 'Terror';
      case Genero.misterio:
        return 'Mistério';
      case Genero.fazendinha:
        return 'Fazendinha';
      case Genero.plataforma:
        return 'Plataforma';
      case Genero.indie:
        return 'Indie';
    }
  }
}