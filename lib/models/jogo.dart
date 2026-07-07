// ============================================================
// Representa um jogo que o Worker devolve na resposta JSON.
// ============================================================

class Jogo {
  // ---- PROPRIEDADES (CAMPOS) ----

  final int id;                 // ID único do jogo na IGDB
  final String nome;            // nome do jogo
  final String? sinopse;        // sinopse (pode ser null)
  final String? imagemUrl;      // URL da capa (pode ser null)
  final List<String> generos;   // lista de nomes de gêneros
  final List<String> temas;     // lista de nomes de temas
  final String? linkLoja;       // link para comprar/jogar (pode ser null)
  final double? rating;         // nota (0-100), pode ser null

  // ---- CONSTRUTOR ----

  // Construtor constante (otimiza memória quando possível).
  // Parâmetros com "required" são obrigatórios; os outros são opcionais.
  const Jogo({
    required this.id,
    required this.nome,
    this.sinopse,
    this.imagemUrl,
    this.generos = const [],   // valor padrão: lista vazia
    this.temas = const [],     // valor padrão: lista vazia
    this.linkLoja,
    this.rating,
  });

  // ---- GETTER (PROPRIEDADE CALCULADA) ----

  // Concatena gêneros e temas em uma única string separada por " • ".
  // Eu matei essa função mas deixei aqui a possibilidade de reintegrar, simplesmente não gosto de como estava
  String get generosLabel => [...generos, ...temas].join(' • ');
  // [...] spread operator: junta as duas listas em uma só.
  // .join(' • ') junta os elementos da lista em uma string, usando " • " entre eles.

  // ---- CONSTRUTOR FACTORY (CRIA UM Jogo A PARTIR DE JSON) ----

  // "factory" indica que este construtor não cria uma nova instância
  // com "new" tradicional, mas sim retorna uma instância de Jogo.
  // É comum usar factory para lógica de parsing (JSON → objeto).
  factory Jogo.fromJson(Map<String, dynamic> json) {
    return Jogo(
      id: json['id'] as int,                              // "as int" = garantimos que é inteiro
      nome: json['name'] as String? ?? 'Sem nome',        // se for null, usa 'Sem nome'
      sinopse: json['summary'] as String?,                // mantém null se não existir
      imagemUrl: (json['cover'] as Map<String, dynamic>?)?['url'] as String?, // acessa objeto aninhado
      generos: _extrairNomes(json['genres']),             // função auxiliar para extrair nomes
      temas: _extrairNomes(json['themes']),               // idem para temas
      linkLoja: _extrairLinkLoja(json['websites']),       // função para escolher link de loja
      rating: (json['rating'] as num?)?.toDouble(),       // converte para double, se existir
    );
  }

  // ---- FUNÇÕES AUXILIARES PRIVADAS (underscore inicial) ----

  // Extrai os nomes de uma lista de objetos {id, name} da IGDB.
  // Exemplo de entrada: [{"id": 12, "name": "RPG"}, {"id": 5, "name": "Tiro"}]
  // Saída: ["RPG", "Tiro"]
  static List<String> _extrairNomes(dynamic lista) {
    if (lista is! List) return [];   // se não for uma lista, retorna lista vazia

    return lista
        .map((item) => (item as Map<String, dynamic>)['name'] as String?) // tenta pegar o 'name'
        .whereType<String>()   // remove todos os null e mantém apenas Strings
        .toList();             // converte de volta para lista
  }

  // Extrai o link da loja a partir do array "websites" da IGDB.
  // A IGDB manda vários links (Steam, Twitter, site oficial, etc.) sem
  // uma ordem definida. Esta função tenta achar primeiro lojas conhecidas;
  // se não encontrar, retorna o primeiro link qualquer.
  static String? _extrairLinkLoja(dynamic lista) {
    if (lista is! List || lista.isEmpty) return null;

    // Extrai as URLs de cada objeto {id, url}
    final urls = lista
        .map((item) => (item as Map<String, dynamic>)['url'] as String?)
        .whereType<String>()   // remove nulls
        .toList();

    // Lista de domínios de lojas conhecidas (em ordem de preferência)
    const lojasConhecidas = [
      'store.steampowered.com',
      'epicgames.com',
      'gog.com',
      'nintendo.com',
      'playstation.com',
      'xbox.com',
    ];

    // Para cada domínio conhecido, verifica se alguma URL contém esse domínio.
    // Se encontrar, retorna a primeira URL que corresponder.
    for (final dominio in lojasConhecidas) {
      final encontrado = urls.where((u) => u.contains(dominio));
      if (encontrado.isNotEmpty) return encontrado.first;
    }

    // Se nenhuma loja conhecida foi encontrada, retorna a primeira URL da lista.
    return urls.isNotEmpty ? urls.first : null;
  }
}