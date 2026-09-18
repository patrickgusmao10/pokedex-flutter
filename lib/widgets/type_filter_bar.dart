import 'package:flutter/material.dart';
import '../theme/pokemon_theme.dart';

class TypeFilterBar extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onSelect;

  const TypeFilterBar({super.key, required this.selectedType, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final types = PokemonTheme.typeColors.keys.toList();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = selectedType == type;
          final color = PokemonTheme.colorForType(type);

          return GestureDetector(
            onTap: () => onSelect(isSelected ? null : type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 1.4),
              ),
              child: Text(
                PokemonTheme.ptType(type),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
