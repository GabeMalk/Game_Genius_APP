// ============================================================
// ARQUIVO: lib/data/jogos_mock.dart
// Lista "fake" de jogos, usada enquanto não há API.
// Quando a API chegar, esse arquivo vira só um fallback/dado
// de teste — o resto do app não vai precisar mudar nada, já
// que tudo já trabalha em termos de List<Jogo>.
//
// 👉 SUBSTITUA imagemUrl e linkLoja pelos links reais que achar.
// ============================================================
import '../models/jogo.dart';
import '../models/genero.dart';

final List<Jogo> jogosMock = [
  Jogo(
    nome: 'Hades',
    generos: [Genero.roguelike, Genero.acao],
    sinopse:
        'Você é Zagreus, príncipe do Submundo, tentando escapar do reino '
        'de seu pai através de combates rápidos e viciantes. Cada morte '
        'revela mais da história e novos poderes.',
    imagemUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&q=80',
    linkLoja: 'https://store.steampowered.com/app/1145360/Hades/',
  ),
  Jogo(
    nome: 'Outer Wilds',
    generos: [Genero.misterio, Genero.aventura],
    sinopse:
        'Explore um sistema solar preso em um loop temporal de 22 minutos. '
        'Cada descoberta é permanente, mesmo que o tempo reinicie. Um dos '
        'jogos de exploração mais originais já feitos.',
    imagemUrl: 'https://images.unsplash.com/photo-1446776653964-20c1d3a81b06?w=800&q=80',
    linkLoja: 'https://store.steampowered.com/app/753640/Outer_Wilds/',
  ),
  Jogo(
    nome: 'Stardew Valley',
    generos: [Genero.fazendinha, Genero.rpg, Genero.simulacao],
    sinopse:
        'Herde uma fazenda abandonada e construa a vida que sempre quis: '
        'plante, pesque, explore minas e faça amizade (ou mais) com os '
        'moradores da cidade.',
    imagemUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&q=80',
    linkLoja: 'https://store.steampowered.com/app/413150/Stardew_Valley/',
  ),
  Jogo(
    nome: 'Hollow Knight',
    generos: [Genero.metroidvania, Genero.indie],
    sinopse:
        'Desvende os segredos de Hallownest, um reino subterrâneo em '
        'ruínas, em uma jornada desafiadora repleta de combate refinado '
        'e atmosfera melancólica.',
    imagemUrl: 'https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=800&q=80',
    linkLoja: 'https://store.steampowered.com/app/367520/Hollow_Knight/',
  ),
  Jogo(
    nome: 'The Witcher 3',
    generos: [Genero.rpg, Genero.mundoAberto, Genero.aventura],
    sinopse:
        'Geralt de Rívia parte numa jornada épica para encontrar sua '
        'filha adotiva em um mundo aberto vasto e repleto de escolhas '
        'morais complexas.',
    imagemUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800&q=80',
    linkLoja: 'https://store.steampowered.com/app/292030/The_Witcher_3_Wild_Hunt/',
  ),
];