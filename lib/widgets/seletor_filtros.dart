// ============================================================
// Cobre TODOS os filtros do Worker: plataforma, era, modo de jogo, e o
// catálogo completo (básicos + avançados, com "Avançados"
// expansível ao final da lista de básicos).
//
// Widget "controlado": recebe o ParametrosBusca (mutável) e
// chama onChanged() sempre que algo muda, pro pai (a tela)
// conseguir atualizar a badge de filtros ativos.
// ============================================================
import 'package:flutter/material.dart';
import '../models/filtro.dart';
import '../models/parametros_busca.dart';
import '../theme/cores_app.dart';

// SeletorFiltros é um StatefulWidget porque precisa manter estado
// interno (ex: se a seção de avançados está expandida ou não).
class SeletorFiltros extends StatefulWidget {
  // Objeto que guarda todos os parâmetros de busca (mutável).
  // O mesmo objeto é compartilhado com a tela pai.
  final ParametrosBusca parametros;
  // Callback: função que o pai passa para ser avisado quando algo muda.
  // Ex: para atualizar a badge de filtros ativos.
  final VoidCallback onChanged;
  // Callback: função chamada quando o usuário toca em "Limpar filtros".
  final VoidCallback onLimparFiltros;

  const SeletorFiltros({
    super.key,
    required this.parametros,
    required this.onChanged,
    required this.onLimparFiltros,
  });

  @override
  State<SeletorFiltros> createState() => _SeletorFiltrosState();
}

class _SeletorFiltrosState extends State<SeletorFiltros> {
  // Estado puramente visual (não faz parte da busca em si) —
  // por isso mora aqui local, não dentro do ParametrosBusca.
  bool _mostrarAvancados = false;

  // Alterna o estado de um filtro do catálogo (neutro ↔ positivo ↔ negativo)
  void _alternarPreferencia(String chave) {
    // Obtém o estado atual do filtro; se não existir, assume neutro.
    final atual = widget.parametros.preferenciasFiltros[chave] ?? PreferenciaFiltro.neutro;
    // Usa o getter .proximo (definido na extension) para avançar no ciclo.
    widget.parametros.preferenciasFiltros[chave] = atual.proximo;
    // Avisa o framework Flutter que o estado interno mudou e a UI deve ser redesenhada.
    setState(() {});
    // Avisa o widget pai (a tela) que algo mudou (ex: para atualizar contador de filtros).
    widget.onChanged();
  }

  // Adiciona ou remove uma era da seleção.
  // Garante que nunca fique com zero eras selecionadas (mínimo 1).
  void _alternarEra(String chave) {
    final eras = widget.parametros.eras;
    if (eras.contains(chave)) {
      // Se já está selecionada e é a única, não permite remover.
      if (eras.length <= 1) return;
      eras.remove(chave);
    } else {
      eras.add(chave);
    }
    setState(() {});
    widget.onChanged();
  }

  // Alterna o modo de jogo entre single, multi ou null (desmarcado).
  void _alternarModoJogo(String valor) {
    // Se já estava selecionado, desmarca (volta para null).
    widget.parametros.modoJogo = widget.parametros.modoJogo == valor ? null : valor;
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    // ListView permite rolagem quando os filtros não cabem na tela.
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Cada _buildSecao cria um título de seção (Plataforma, Época, etc.)
        _buildSecao('Plataforma'),
        _buildPlataforma(),
        const SizedBox(height: 8),

        _buildSecao('Época'),
        _buildEras(),
        const SizedBox(height: 8),

        _buildSecao('Jogadores'),
        _buildModoJogo(),

        // Divisor visual (linha tênue)
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 32),

        // Botão "Limpar filtros"
        _buildLimparFiltros(),
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

        // Itera sobre a lista de filtros básicos e cria uma linha para cada um.
        // O operador ... (spread) "desempacota" os widgets gerados pelo map
        // dentro da lista children.
        ...filtrosBasicos.map(_buildLinhaFiltro),

        // Botão "Avançados" / "Ocultar avançados"
        _buildBotaoAvancados(),

        // Se o estado _mostrarAvancados for true, mostra também os filtros avançados.
        if (_mostrarAvancados) ...filtrosAvancados.map(_buildLinhaFiltro),

        const SizedBox(height: 8),
      ],
    );
  }

  // Widget auxiliar que exibe o título de uma seção (ex: "Plataforma").
  Widget _buildSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: CoresApp.primaria.shade100,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Widget auxiliar que cria um chip de seleção.
  // Parâmetros:
  // - label: texto exibido no chip
  // - selecionada: se true, chip aparece com cor de destaque
  // - onTap: função chamada quando o chip é tocado
  // - icone: parâmetro opcional — mostra um ícone antes do texto
  Widget _buildChip({
    required String label,
    required bool selecionada,
    required VoidCallback onTap,
    IconData? icone, // 🆕 NOVO
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // Fundo sólido (cor primária) quando selecionado, ou um
          // cinza bem sutil quando não — nunca branco/claro.
          color: selecionada ? CoresApp.primaria : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionada ? CoresApp.primaria : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🆕 NOVO: só desenha o ícone se ele foi passado.
            if (icone != null) ...[
              Icon(icone, size: 16, color: selecionada ? Colors.white : Colors.grey.shade300),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selecionada ? Colors.white : Colors.grey.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Constrói a seção de plataformas (atualmente só PC).
  Widget _buildPlataforma() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(  // Wrap organiza os chips em linha e quebra para a próxima se necessário.
        spacing: 8,  // espaço horizontal entre chips
        children: catalogoDePlataformas.map((p) {
          return _buildChip(
            label: p.label,
            icone: Icons.computer, // Ícone de telinha pro PC
            // Verifica se esta plataforma é a que está selecionada.
            selecionada: widget.parametros.plataforma == p.id,
            onTap: () {
              // Atualiza a plataforma no objeto de parâmetros.
              setState(() => widget.parametros.plataforma = p.id);
              widget.onChanged();
            },
          );
        }).toList(),
      ),
    );
  }

  // Constrói a seção de eras (lançamentos, atualidade, etc.).
  Widget _buildEras() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8, // espaço vertical entre linhas
        children: catalogoDeEras.map((e) {
          return _buildChip(
            label: e.label,
            // Verifica se a chave da era está contida no Set de eras selecionadas.
            selecionada: widget.parametros.eras.contains(e.chave),
            onTap: () => _alternarEra(e.chave),
          );
        }).toList(),
      ),
    );
  }

  // Constrói a seção de modo de jogo (Single player / Multiplayer).
  Widget _buildModoJogo() {
    // Mapa local: chave 'single'/'multi' -> label exibido.
    const opcoes = {'single': 'Single player', 'multi': 'Multiplayer'};
    // Mapa de ícones — pessoinha pro single, galerinha pro multi.
    const icones = {'single': Icons.person, 'multi': Icons.groups};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        // entries retorna um conjunto de MapEntry (chave, valor).
        children: opcoes.entries.map((entry) {
          return _buildChip(
            label: entry.value,
            icone: icones[entry.key],
            // Selecionado se o modoJogo atual for igual à chave.
            selecionada: widget.parametros.modoJogo == entry.key,
            onTap: () => _alternarModoJogo(entry.key),
          );
        }).toList(),
      ),
    );
  }

  // Botão "Limpar filtros" com ícone de refresh.
  Widget _buildLimparFiltros() {
    return InkWell(
      onTap: widget.onLimparFiltros, // chama o callback do pai
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.refresh, size: 18, color: CoresApp.primaria.shade200), 
            const SizedBox(width: 10),
            Text(
              'Limpar filtros',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CoresApp.primaria.shade100), 
            ),
          ],
        ),
      ),
    );
  }

  // Constrói uma linha para um filtro do catálogo (ex: "RPG").
  Widget _buildLinhaFiltro(FiltroInfo info) {
    // Obtém o estado atual deste filtro (neutro/positivo/negativo).
    final preferencia = widget.parametros.preferenciasFiltros[info.chave] ?? PreferenciaFiltro.neutro;
    return InkWell(
      onTap: () => _alternarPreferencia(info.chave),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // O nome do filtro ocupa o espaço disponível.
            Expanded(
              child: Text(
                info.label,
                style: TextStyle(
                  fontSize: 16,
                  // Se neutro, cor normal; caso contrário, um pouco mais opaco.
                  color: preferencia == PreferenciaFiltro.neutro ? Colors.white : Colors.white.withValues(alpha: 0.95),
                  fontWeight: preferencia == PreferenciaFiltro.neutro ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            // Ícone animado que muda conforme o estado do filtro.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: _buildIcone(preferencia),
            ),
          ],
        ),
      ),
    );
  }

  // Retorna o ícone correspondente ao estado do filtro.
  Widget _buildIcone(PreferenciaFiltro preferencia) {
    switch (preferencia) {
      case PreferenciaFiltro.positivo:
        return Container(
          key: const ValueKey('positivo'), // chave para o AnimatedSwitcher diferenciar os widgets
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.thumb_up, color: Colors.green, size: 20),
        );
      case PreferenciaFiltro.negativo:
        return Container(
          key: const ValueKey('negativo'),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.thumb_down, color: Colors.redAccent, size: 20),
        );
      case PreferenciaFiltro.neutro:
        return Container(
          key: const ValueKey('neutro'),
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.radio_button_unchecked, color: Colors.white.withValues(alpha: 0.25), size: 20),
        );
    }
  }

  // Botão para expandir/recolher a lista de filtros avançados.
  Widget _buildBotaoAvancados() {
    return InkWell(
      onTap: () => setState(() => _mostrarAvancados = !_mostrarAvancados),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              _mostrarAvancados ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: CoresApp.primaria.shade200,
            ),
            const SizedBox(width: 10),
            Text(
              _mostrarAvancados ? 'Ocultar avançados' : 'Avançados',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CoresApp.primaria.shade100), // 🔧 ALTERADO
            ),
          ],
        ),
      ),
    );
  }
}