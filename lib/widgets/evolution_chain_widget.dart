import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/pokemon.dart';

class EvolutionChainWidget extends StatelessWidget {
  final List<EvolutionNode> nodes;
  final Color accentColor;
  final void Function(int pokemonId) onTapNode;

  const EvolutionChainWidget({
    super.key,
    required this.nodes,
    required this.accentColor,
    required this.onTapNode,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.length <= 1) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Este Pokémon não evolui.'),
      );
    }

    // Agrupa por estágio (0, 1, 2...) para lidar com ramificações (ex.: Eevee).
    final Map<int, List<EvolutionNode>> byStage = {};
    for (final n in nodes) {
      byStage.putIfAbsent(n.stage, () => []).add(n);
    }
    final stages = byStage.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < stages.length; i++) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: byStage[stages[i]]!
                  .map((node) => _EvolutionCard(
                        node: node,
                        onTap: () => onTapNode(node.id),
                      ))
                  .toList(),
            ),
            if (i != stages.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_rounded, color: accentColor, size: 26),
                    if (byStage[stages[i + 1]]!.first.evolutionHint.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          byStage[stages[i + 1]]!.first.evolutionHint,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  final EvolutionNode node;
  final VoidCallback onTap;

  const _EvolutionCard({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: CachedNetworkImage(
                imageUrl: node.spriteUrl,
                fit: BoxFit.contain,
                placeholder: (_, _) =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (_, _, _) => const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              node.name[0].toUpperCase() + node.name.substring(1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
