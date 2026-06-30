// ============================================================
// ARQUIVO: lib/models/preferencia_genero.dart
// Representa o que o usuário sente sobre um gênero específico.
// Isso é o dado "de verdade" que vai alimentar o filtro real
// no futuro — não é só estado visual.
// ============================================================
enum PreferenciaGenero {
  neutro,   // usuário não opinou (estado inicial)
  gosta,    // 1º toque: usuário busca esse gênero
  naoGosta, // 2º toque: usuário evita esse gênero
}

// Dado um estado atual, devolve o próximo no ciclo:
// neutro -> gosta -> naoGosta -> neutro -> ...
extension CicloPreferencia on PreferenciaGenero {
  PreferenciaGenero get proximo {
    switch (this) {
      case PreferenciaGenero.neutro:
        return PreferenciaGenero.gosta;
      case PreferenciaGenero.gosta:
        return PreferenciaGenero.naoGosta;
      case PreferenciaGenero.naoGosta:
        return PreferenciaGenero.neutro;
    }
  }
}