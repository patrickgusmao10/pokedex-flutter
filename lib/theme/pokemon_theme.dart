import 'package:flutter/material.dart';

/// Cores oficiais (aprox.) de cada tipo de Pokémon.
/// Usadas para colorir badges, cards e o fundo da tela de detalhes —
/// a "paleta de cores" do Pokémon é derivada do(s) seu(s) tipo(s),
/// exatamente como na Pokédex oficial.
class PokemonTheme {
  PokemonTheme._();

  static const Map<String, Color> typeColors = {
    'normal': Color(0xFFA8A77A),
    'fire': Color(0xFFEE8130),
    'water': Color(0xFF6390F0),
    'electric': Color(0xFFF7D02C),
    'grass': Color(0xFF7AC74C),
    'ice': Color(0xFF96D9D6),
    'fighting': Color(0xFFC22E28),
    'poison': Color(0xFFA33EA1),
    'ground': Color(0xFFE2BF65),
    'flying': Color(0xFFA98FF3),
    'psychic': Color(0xFFF95587),
    'bug': Color(0xFFA6B91A),
    'rock': Color(0xFFB6A136),
    'ghost': Color(0xFF735797),
    'dragon': Color(0xFF6F35FC),
    'dark': Color(0xFF705746),
    'steel': Color(0xFFB7B7CE),
    'fairy': Color(0xFFD685AD),
  };

  static const Map<String, String> typeNamesPt = {
    'normal': 'Normal',
    'fire': 'Fogo',
    'water': 'Água',
    'electric': 'Elétrico',
    'grass': 'Planta',
    'ice': 'Gelo',
    'fighting': 'Lutador',
    'poison': 'Veneno',
    'ground': 'Terra',
    'flying': 'Voador',
    'psychic': 'Psíquico',
    'bug': 'Inseto',
    'rock': 'Pedra',
    'ghost': 'Fantasma',
    'dragon': 'Dragão',
    'dark': 'Sombrio',
    'steel': 'Aço',
    'fairy': 'Fada',
  };

  static const Map<String, String> habitatNamesPt = {
    'cave': 'Caverna',
    'forest': 'Floresta',
    'grassland': 'Campina',
    'mountain': 'Montanha',
    'rare': 'Raro',
    'rough-terrain': 'Terreno acidentado',
    'sea': 'Mar',
    'urban': 'Urbano',
    'waters-edge': 'Beira d\'água',
  };

  static const Map<String, String> statNamesPt = {
    'hp': 'HP',
    'attack': 'Ataque',
    'defense': 'Defesa',
    'special-attack': 'Atq. Especial',
    'special-defense': 'Def. Especial',
    'speed': 'Velocidade',
  };

  static Color colorForType(String type) =>
      typeColors[type] ?? const Color(0xFF9AA1A9);

  static String ptType(String type) => typeNamesPt[type] ?? _capitalize(type);

  static String ptHabitat(String? habitat) {
    if (habitat == null) return 'Desconhecido';
    return habitatNamesPt[habitat] ?? _capitalize(habitat);
  }

  static String ptStat(String stat) => statNamesPt[stat] ?? _capitalize(stat);

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split('-')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Nome de exibição bonito a partir do nome técnico da API (ex.: "ho-oh" -> "Ho-Oh").
  static String prettyName(String rawName) {
    return rawName
        .split('-')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join('-');
  }

  /// Gradiente de fundo baseado no(s) tipo(s) do Pokémon.
  static LinearGradient gradientForTypes(List<String> types) {
    final c1 = colorForType(types.isNotEmpty ? types[0] : 'normal');
    final c2 = types.length > 1 ? colorForType(types[1]) : c1.withValues(alpha: 0.65);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c1, c2],
    );
  }
}
