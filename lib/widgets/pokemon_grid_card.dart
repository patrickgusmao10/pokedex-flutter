import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../theme/pokemon_theme.dart';
import 'type_badge.dart';

class PokemonGridCard extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;

  const PokemonGridCard({super.key, required this.pokemon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = PokemonTheme.gradientForTypes(pokemon.types);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Número de fundo, estilo cartão colecionável.
              Positioned(
                right: 4,
                top: -6,
                child: Text(
                  pokemon.idLabel,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        height: 84,
                        alignment: Alignment.center,
                        child: pokemon.spriteUrl.isEmpty
                            ? const Icon(Icons.image_not_supported,
                                color: Colors.white70, size: 40)
                            : Image.network(
                                pokemon.spriteUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    height: 84,
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white70,
                                ),
                              ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      pokemon.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: pokemon.types
                          .map((t) => TypeBadge(type: t, small: true))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
