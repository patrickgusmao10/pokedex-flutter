/// Entrada leve do índice geral (todos os Pokémon existentes).
/// Usada para listar/paginar/buscar sem precisar baixar detalhes de todos.
class PokedexEntry {
  final int id;
  final String name;

  const PokedexEntry({required this.id, required this.name});
}

/// Um valor de status (HP, Ataque, etc.)
class StatEntry {
  final String key; // ex.: "hp", "attack"
  final int value;
  final int max; // usado para desenhar a barra (normalmente 255)

  const StatEntry({required this.key, required this.value, this.max = 255});
}

/// Um estágio dentro da cadeia de evolução.
class EvolutionNode {
  final int id;
  final String name;
  final String spriteUrl;
  final int stage; // 0 = forma base, 1 = primeira evolução, etc.
  final String? trigger; // ex.: "level-up", "use-item", "trade"
  final int? minLevel;
  final String? item;

  const EvolutionNode({
    required this.id,
    required this.name,
    required this.spriteUrl,
    required this.stage,
    this.trigger,
    this.minLevel,
    this.item,
  });

  /// Descrição curta de como esse Pokémon evolui para o próximo estágio.
  String get evolutionHint {
    if (trigger == null) return '';
    switch (trigger) {
      case 'level-up':
        if (minLevel != null) return 'Nível $minLevel';
        return 'Level up';
      case 'use-item':
        return item != null ? 'Usar ${item!}' : 'Usar item';
      case 'trade':
        return 'Troca';
      default:
        return trigger!;
    }
  }
}

/// Modelo completo de um Pokémon.
///
/// Os campos "básicos" (id, name, sprite, types, stats, height, weight,
/// abilities) vêm do endpoint /pokemon/{id} e são suficientes para a grade
/// da Pokédex. Os campos "extras" (description, genus, habitat, colorName,
/// namePt, evolutionChain, weaknesses/resistances/immunities) vêm do
/// endpoint /pokemon-species/{id} + /evolution-chain + /type e só são
/// carregados quando o usuário abre a tela de detalhes — para manter a
/// listagem principal rápida.
class Pokemon {
  final int id;
  final String name;
  final String spriteUrl;
  final String? shinySpriteUrl;
  final List<String> types;
  final int heightDm; // decímetros (unidade nativa da API)
  final int weightHg; // hectogramas (unidade nativa da API)
  final List<StatEntry> stats;
  final List<String> abilities;
  final int baseExperience;

  // Extras (carregados sob demanda)
  final String? namePt;
  final String? description;
  final String? genus;
  final String? habitat;
  final String? colorName;
  final List<EvolutionNode>? evolutionChain;
  final Map<String, double>? typeEffectiveness; // multiplicador por tipo atacante

  const Pokemon({
    required this.id,
    required this.name,
    required this.spriteUrl,
    this.shinySpriteUrl,
    required this.types,
    required this.heightDm,
    required this.weightHg,
    required this.stats,
    required this.abilities,
    required this.baseExperience,
    this.namePt,
    this.description,
    this.genus,
    this.habitat,
    this.colorName,
    this.evolutionChain,
    this.typeEffectiveness,
  });

  double get heightMeters => heightDm / 10;
  double get weightKg => weightHg / 10;

  String get displayName =>
      name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join('-');

  String get idLabel => '#${id.toString().padLeft(3, '0')}';

  int get totalStats => stats.fold(0, (sum, s) => sum + s.value);

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final spritesJson = json['sprites'] as Map<String, dynamic>? ?? {};
    final other = spritesJson['other'] as Map<String, dynamic>? ?? {};
    final officialArtwork =
        other['official-artwork'] as Map<String, dynamic>? ?? {};

    final String? artwork = officialArtwork['front_default'] as String?;
    final String? fallbackSprite = spritesJson['front_default'] as String?;
    final String? shiny = officialArtwork['front_shiny'] as String? ??
        spritesJson['front_shiny'] as String?;

    final types = <String>[];
    for (final t in (json['types'] as List? ?? [])) {
      types.add(t['type']['name'] as String);
    }
    // Garante ordem correta (slot 1, slot 2) mesmo se a API retornar fora de ordem.
    final rawTypes = (json['types'] as List? ?? []);
    rawTypes.sort((a, b) => (a['slot'] as int).compareTo(b['slot'] as int));
    final orderedTypes = rawTypes.map((t) => t['type']['name'] as String).toList();

    final stats = <StatEntry>[];
    for (final s in (json['stats'] as List? ?? [])) {
      stats.add(StatEntry(
        key: s['stat']['name'] as String,
        value: s['base_stat'] as int,
      ));
    }

    final abilities = <String>[];
    for (final a in (json['abilities'] as List? ?? [])) {
      abilities.add(a['ability']['name'] as String);
    }

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      spriteUrl: artwork ?? fallbackSprite ?? '',
      shinySpriteUrl: shiny,
      types: orderedTypes.isNotEmpty ? orderedTypes : types,
      heightDm: json['height'] as int? ?? 0,
      weightHg: json['weight'] as int? ?? 0,
      stats: stats,
      abilities: abilities,
      baseExperience: json['base_experience'] as int? ?? 0,
    );
  }

  Pokemon copyWithExtras({
    String? namePt,
    String? description,
    String? genus,
    String? habitat,
    String? colorName,
    List<EvolutionNode>? evolutionChain,
    Map<String, double>? typeEffectiveness,
  }) {
    return Pokemon(
      id: id,
      name: name,
      spriteUrl: spriteUrl,
      shinySpriteUrl: shinySpriteUrl,
      types: types,
      heightDm: heightDm,
      weightHg: weightHg,
      stats: stats,
      abilities: abilities,
      baseExperience: baseExperience,
      namePt: namePt ?? this.namePt,
      description: description ?? this.description,
      genus: genus ?? this.genus,
      habitat: habitat ?? this.habitat,
      colorName: colorName ?? this.colorName,
      evolutionChain: evolutionChain ?? this.evolutionChain,
      typeEffectiveness: typeEffectiveness ?? this.typeEffectiveness,
    );
  }
}
