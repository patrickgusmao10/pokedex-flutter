import 'package:flutter/material.dart';
import '../theme/pokemon_theme.dart';

class TypeBadge extends StatelessWidget {
  final String type;
  final bool small;

  const TypeBadge({super.key, required this.type, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = PokemonTheme.colorForType(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        PokemonTheme.ptType(type).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: small ? 10 : 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
