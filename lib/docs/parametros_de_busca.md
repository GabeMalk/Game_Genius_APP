Parametros de busca

Não existe aleatório. Quando o jogador não selecionar nenhum filtro positivo, o app deve selecionar em segredo um aleatório entre os filtros básicos. Isso reseta a cada busca.

A busca funciona da seguinte maneira: 

Plataforma é exclusiva, há de se escolher um entre as opções (PC apenas a principio) -> No caso de jogos de PC, a seguinte lógica de busca toma efeito em cima do IGDB -> A data de lançamento filtra pelos jogos dentro do escopo  -> Os gêneros negativos agem para não incluir jogos com esses marcadores - > Aqui começa a ter um branch a partir dos filtros positivos, sempre com sort por rating_count:
Branch 1:
1 a 3 filtros positivos estão selecionados >
Pedimos 500 jogos do IGDB que tenham estritamente todos os marcadores selecionados e padrão mínimo de qualidade (5 avaliações e score de 40 ou mais) >
Branch 1.1: IGDB retorna 500 jogos > Pedimos uma segunda pagina com os mesmos parâmetros e os 500 próximos jogos da lista > Retornamos 1 jogo aleatório da lista final
Branch 1.2: O IGDB retorna entre 1 a 499 jogos > Retornamos 1 jogo aleatório da lista final
Branch 1.3: O IGDB retorna 0 jogos > Pedimos uma nova lista com os mesmos parâmetros porém SEM os filtros mínimos de qualidade > Retornamos 1 jogo aleatório da lista final
Branch 1.3.1 (fail): O IGDB retorna 0 jogos mesmo após o branch 1.3 > Tentamos o Branch 2
Branch 2: 
Mais de 3 filtros positivos estão selecionados OU o Branch 1 falhou (1.4) >
Pedimos 500 jogos que tenham pelo menos um dos marcadores positivos selecionados e padrão mínimo de qualidade >
Branch 2.1: O IGDB retorna 500 jogos  IGDB retorna 500 jogos > Pedimos uma segunda página com os mesmos parâmetros e os 500 próximos jogos da lista > O worker filtra localmente no JavaScript para buscar os que têm pelo menos 2 matches e retorna 1 jogo aleatório da lista > Se não houver um jogo com 2 matchs, retorna um aleatório simples
Branch 2.2: O IGDB retorna entre 1 a 499 jogos > O worker filtra localmente no JavaScript para buscar os que têm pelo menos 2 matches e retorna 1 jogo aleatório da lista > Se não houver um jogo com 2 matchs, retorna um aleatório simples
Branch 2.3: O IGDB retorna 0 jogos > Pedimos uma nova lista com os mesmos parâmetros porém SEM os filtros mínimos de qualidade > O worker filtra localmente no JavaScript para buscar os que têm pelo menos 2 matches e retorna 1 jogo aleatório da lista > Se não houver um jogo com 2 matchs, retorna um aleatório simples
Branch 2.3.1 (fail): O IGDB retorna 0 jogos mesmo após o branch 2.3 > Mensagem de erro


Filtros sempre ativos:
// Queremos apenas jogos main, não DLCs e afins, portanto:
game_type = 0 (Main Game - id: 0)

Plataformas:
// Só pode escolher um

PC - platforms id: 6

// Por enquanto só PC é valido, depois adicionamos o resto aos poucos

Era:
// Pode escolher múltiplos, mas sempre deve haver pelo menos um selecionado

Lançamentos (Do mês retrasado até a data de hoje)
Atualidade (De 2020 até a data de hoje) // Único selecionado por padrão
Modernos (2014 a 2020)
Old School (De 2002 até 2014)
Clássicos (Pré 2002)

Quantidade de Jogadores:
// Por padrão todas desativadas, ou seja, nem aplica esses filtros. Pode selecionar um ou pode deselecionar.

Single player - game_modes id: 1
Multiplayer - game_modes id: 2, 3, 5, 6

Filtros:

// Filtros basicos (aparece por padrão):

RPG - genres = (12)
Aventura - genres = (31)
Ação - (genres = (25) | themes = (1))
Plataforma - genres = (8)
Estrategia - (genres = (15, 24, 16), themes = (41))
Tiro - genres = (5)
Luta - genres = (4)
Simulação e trabalho - (genres = (13) | themes = (28))
Visual Novel - genres = (34)
Esportes e corrida - genres = (10, 14, 30)
Quebra - Cabeça - genres = (9)
Cartas e tabuleiro - genres = (35)
Terror e suspense - themes = (19, 20)

// Filtros avançados (tem que clicar em "avançado" para liberar)

Roguelike - keywords = (17292, 416, 27419, 41781)
Primeira Pessoa - player_perspective = (1)
Indie - genres = (32)
Point 'n' Click - genres = (2)
Mundo aberto - themes = (38)
Drama e mistério - themes = (31, 43)
Sandbox - themes = (33)
Sobrevivência - themes = (21)
Furtividade - themes = (23)
Fantasia e medieval - (themes = (17) | keywords = (151))
Ficção Ciêntifica - themes = (18)
Música - genres = (7)
RTS - genres = (11)
Jogo de festa - themes = (40)
Engraçado - themes = (27)
Romance - themes = (44)
Anime - keywords = (78)
Erotic - themes = (42)// Por padrão marcado como "não"