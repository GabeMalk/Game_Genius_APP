// ============================================================
// Guarda os últimos ids sorteados e persiste
// ============================================================

// Importa a biblioteca dart:convert para usar jsonDecode e jsonEncode.
import 'dart:convert';
// Importa o pacote shared_preferences (adicionado no pubspec.yaml).
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoService {
  // Chave usada para salvar/ler o histórico no armazenamento local.
  static const _chave = 'historico_ids_sorteados';
  // Limite máximo de IDs que serão guardados.
  static const _maximo = 50;

  // Carrega a lista de IDs salva no dispositivo.
  // Retorna uma Future (promessa) porque a leitura é assíncrona.
  Future<List<int>> carregar() async {
    // Obtém a instância do SharedPreferences (armazenamento chave-valor).
    final prefs = await SharedPreferences.getInstance();
    // Lê o valor associado à chave; se nunca foi salvo, retorna null.
    final salvo = prefs.getString(_chave);
    // Se não há nada salvo, retorna lista vazia.
    if (salvo == null) return [];

    // Decodifica a string JSON para uma List (dynamic).
    final lista = jsonDecode(salvo) as List;
    // Converte cada elemento da lista para int; .cast<int>() faz isso.
    return lista.cast<int>();
  }

  // Adiciona um novo ID ao histórico e retorna a lista atualizada.
  // O novo ID vai para o início (é o mais recente).
  Future<List<int>> adicionar(int novoId) async {
    // Carrega a lista atual (já existente).
    final atual = await carregar();

    // Monta a nova lista:
    // [novoId, ...atual.where((id) => id != novoId)]
    // 1. Coloca o novo ID na primeira posição.
    // 2. Espalha (spread ...) o restante da lista, removendo qualquer
    //    ocorrência antiga do mesmo ID (evita duplicatas).
    // .take(_maximo) limita a lista aos primeiros 50 itens.
    // .toList() converte o iterável em uma lista concreta.
    final atualizada = [novoId, ...atual.where((id) => id != novoId)]
        .take(_maximo)
        .toList();

    // Obtém o SharedPreferences novamente para salvar.
    final prefs = await SharedPreferences.getInstance();
    // Converte a lista para string JSON e salva com a chave.
    await prefs.setString(_chave, jsonEncode(atualizada));
    // Retorna a lista atualizada.
    return atualizada;
  }
}