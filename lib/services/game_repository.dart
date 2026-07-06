// ============================================================
// Faz a chamada POST pro Worker, tudo fora da tela
// ============================================================

// Importa dart:convert para jsonEncode e jsonDecode
import 'dart:convert';
// Importa o pacote http com alias 'http' (usaremos http.post, etc.)
import 'package:http/http.dart' as http;
// Importa os modelos Jogo e ParametrosBusca
import '../models/jogo.dart';
import '../models/parametros_busca.dart';

// URL do worker e literalmente a senha de acesso... Não é lá muito seguro, mas por hora fodase
const String _workerUrl = 'https://proxy-igdb.gabriel-music67.workers.dev/jogos';
const String _appSecret = 'yK*2jo5%GU!-UpT?+HpF';

// Erro específico pra "nenhum jogo encontrado" — é um resultado
// válido de busca (404 esperado), não uma falha de verdade.
class NenhumJogoEncontradoException implements Exception {
  final String mensagem;
  NenhumJogoEncontradoException(this.mensagem);
}

class GameRepository {
  // Método assíncrono que retorna um Jogo.
  // Recebe os parâmetros da busca e a lista de histórico.
  Future<Jogo> buscarRecomendacao({
    required ParametrosBusca parametros, // parâmetros selecionados na UI
    required List<int> historicoIds,     // IDs já mostrados (carregados do histórico)
  }) async {
    // Faz a requisição POST para o Worker.
    final resposta = await http.post(
      Uri.parse(_workerUrl), // converte a string URL para objeto Uri
      headers: {
        'Content-Type': 'application/json', // indica que o corpo é JSON
        'X-App-Secret': _appSecret,         // segredo de autenticação definido no Worker
      },
      // Converte o objeto ParametrosBusca em JSON (via toJson) e depois em string.
      body: jsonEncode(parametros.toJson(historicoIds)),
    );

    // Decodifica o corpo da resposta (string JSON) em um mapa Dart.
    final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;

    // Se o Worker retornou 404, significa que a busca não encontrou jogos.
    if (resposta.statusCode == 404) {
      throw NenhumJogoEncontradoException(
        // Tenta usar a mensagem do campo 'erro', senão usa uma padrão.
        corpo['erro'] as String? ?? 'Nenhum jogo encontrado.',
      );
    }

    // Se o status não for 200 (OK), lança uma exceção genérica com a mensagem de erro.
    if (resposta.statusCode != 200) {
      throw Exception(corpo['erro'] as String? ?? 'Erro ao buscar recomendação.');
    }

    // Sucesso: converte o corpo JSON em um objeto Jogo usando o factory fromJson.
    return Jogo.fromJson(corpo);
  }
}