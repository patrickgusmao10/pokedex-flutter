import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../theme/pokemon_theme.dart';

class StatBar extends StatelessWidget {
  final StatEntry stat;
  final Color color;

  const StatBar({super.key, required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = (stat.value / stat.max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              PokemonTheme.ptStat(stat.key),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '${stat.value}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
