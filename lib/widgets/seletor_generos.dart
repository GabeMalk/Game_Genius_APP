// ============================================================
// ARQUIVO: lib/widgets/seletor_generos.dart
// Lista de gêneros que o usuário pode tocar para ciclar entre
// neutro -> gosta (👍) -> não gosta (👎) -> neutro -> ...
//
// Esse widget é "controlado": ele recebe o mapa de preferências
// atual e avisa o pai quando algo muda via callback, em vez de
// guardar o próprio estado. Isso facilita reaproveitar o mapa
// na tela principal pra filtrar de verdade no futuro.
// ============================================================
import 'package:flutter/material.dart';
import '../models/genero.dart';
import '../models/preferencia_genero.dart';

class SeletorGeneros extends StatelessWidget {
  final Map<Genero, PreferenciaGenero> preferencias;
  final void Function(Genero) onToqueGenero;
  final VoidCallback onLimparFiltros;

  const SeletorGeneros({
    super.key,
    required this.preferencias,
    required this.onToqueGenero,
    required this.onLimparFiltros,
  });

  bool get _temFiltroAtivo =>
      preferencias.values.any((p) => p != PreferenciaGenero.neutro);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      // +1 item no topo para o botão "Limpar filtros"
      itemCount: Genero.values.length + 1,
      separatorBuilder: (_, index) => Divider(
        color: Colors.white.withValues(alpha: 0.08),
        height: 1,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildLimparFiltros();
        }
        final genero = Genero.values[index - 1];
        final preferencia = preferencias[genero] ?? PreferenciaGenero.neutro;
        return _buildLinhaGenero(genero, preferencia);
      },
    );
  }

  Widget _buildLimparFiltros() {
    final ativo = _temFiltroAtivo;
    return InkWell(
      onTap: ativo ? onLimparFiltros : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.refresh,
              size: 18,
              color: ativo
                  ? Colors.deepPurple.shade200
                  : Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 10),
            Text(
              'Limpar filtros',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ativo
                    ? Colors.deepPurple.shade100
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaGenero(Genero genero, PreferenciaGenero preferencia) {
    return InkWell(
      onTap: () => onToqueGenero(genero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                genero.label,
                style: TextStyle(
                  fontSize: 16,
                  color: preferencia == PreferenciaGenero.neutro
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.95),
                  fontWeight: preferencia == PreferenciaGenero.neutro
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: _buildIcone(preferencia),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcone(PreferenciaGenero preferencia) {
    switch (preferencia) {
      case PreferenciaGenero.gosta:
        return Container(
          key: const ValueKey('gosta'),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.thumb_up, color: Colors.green, size: 20),
        );
      case PreferenciaGenero.naoGosta:
        return Container(
          key: const ValueKey('naoGosta'),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.thumb_down, color: Colors.redAccent, size: 20),
        );
      case PreferenciaGenero.neutro:
        return Container(
          key: const ValueKey('neutro'),
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.radio_button_unchecked,
            color: Colors.white.withValues(alpha: 0.25),
            size: 20,
          ),
        );
    }
  }
}