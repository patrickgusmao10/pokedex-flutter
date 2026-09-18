import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

/// Centraliza todo o acesso à PokéAPI (https://pokeapi.co).
///
/// Estratégia de performance:
/// - O índice completo (todos os ~1300 nomes/IDs) é baixado UMA vez, é leve
///   (só nome + url) e permite buscar/paginar localmente sem golpear a API
///   a cada tecla digitada.
/// - Detalhes "básicos" (sprite, tipos, stats) são buscados em lotes
///   paralelos (Future.wait) em vez de sequencialmente, o que torna o
///   carregamento muito mais rápido que um loop de `await` um por um.
/// - Detalhes "extras" (descrição, evolução, habitat, fraquezas) só são
///   buscados quando o usuário abre a tela de detalhes de um Pokémon.
/// - Tudo é cacheado em memória para não repetir requisições.
class PokemonService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  final http.Client _client;
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  List<PokedexEntry>? _fullIndex;
  final Map<int, Pokemon> _detailCache = {};
  final Map<String, List<int>> _typeIdsCache = {};
  final Map<String, Map<String, dynamic>> _typeRelationsCache = {};

  int extractId(String url) {
    final parts = url.split('/').where((p) => p.isNotEmpty).toList();
    return int.parse(parts.last);
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw PokeApiException('Falha ao acessar a PokéAPI ($url): HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Baixa (uma única vez, com cache) o índice de todos os Pokémon
  /// existentes: apenas {id, name}. Usado para listar/paginar/buscar.
  Future<List<PokedexEntry>> fetchFullIndex() async {
    if (_fullIndex != null) return _fullIndex!;

    final json = await _getJson('$_baseUrl/pokemon?limit=100000&offset=0');
    final results = json['results'] as List;

    final entries = <PokedexEntry>[];
    for (final r in results) {
      final url = r['url'] as String;
      entries.add(PokedexEntry(id: extractId(url), name: r['name'] as String));
    }
    _fullIndex = entries;
    return entries;
  }

  /// Busca (em paralelo, com cache) os detalhes básicos de uma lista de IDs.
  /// Ignora silenciosamente formas especiais que eventualmente falhem, para
  /// não travar a listagem inteira por causa de uma entrada só.
  Future<List<Pokemon>> fetchBasicBatch(List<int> ids) async {
    final toFetch = ids.where((id) => !_detailCache.containsKey(id)).toList();

    if (toFetch.isNotEmpty) {
      final results = await Future.wait(
        toFetch.map((id) => _fetchBasicSafe(id)),
      );
      for (final p in results) {
        if (p != null) _detailCache[p.id] = p;
      }
    }

    return ids.map((id) => _detailCache[id]).whereType<Pokemon>().toList();
  }

  Future<Pokemon?> _fetchBasicSafe(int id) async {
    try {
      final json = await _getJson('$_baseUrl/pokemon/$id');
      return Pokemon.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Busca um único Pokémon por nome exato ou número (usado na busca).
  Future<Pokemon?> fetchByNameOrId(String query) async {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return null;
    try {
      final json = await _getJson('$_baseUrl/pokemon/$key');
      final p = Pokemon.fromJson(json);
      _detailCache[p.id] = p;
      return p;
    } catch (_) {
      return null;
    }
  }

  /// Todos os IDs de Pokémon que pertencem a um determinado tipo.
  Future<List<int>> fetchIdsForType(String type) async {
    if (_typeIdsCache.containsKey(type)) return _typeIdsCache[type]!;

    final json = await _getJson('$_baseUrl/type/$type');
    final pokemonList = json['pokemon'] as List;
    final ids = pokemonList
        .map((p) => extractId(p['pokemon']['url'] as String))
        .toList()
      ..sort();

    _typeIdsCache[type] = ids;
    return ids;
  }

  /// Carrega descrição, habitat, cor, nome em PT-BR, cadeia evolutiva e
  /// fraquezas/resistências — tudo que só é necessário na tela de detalhes.
  Future<Pokemon> fetchExtras(Pokemon base) async {
    final species = await _getJson('$_baseUrl/pokemon-species/${base.id}');

    final description = _pickLocalizedFlavorText(species['flavor_text_entries'] as List);
    final genus = _pickLocalized(species['genera'] as List, key: 'genus');
    final namePt = _pickLocalized(species['names'] as List, key: 'name');
    final habitat = (species['habitat'] as Map?)?['name'] as String?;
    final colorName = (species['color'] as Map?)?['name'] as String?;

    List<EvolutionNode>? chainFlat;
    final evoUrl = (species['evolution_chain'] as Map?)?['url'] as String?;
    if (evoUrl != null) {
      try {
        chainFlat = await _fetchEvolutionChainFlat(evoUrl);
      } catch (_) {
        chainFlat = null;
      }
    }

    Map<String, double>? effectiveness;
    try {
      effectiveness = await _computeTypeEffectiveness(base.types);
    } catch (_) {
      effectiveness = null;
    }

    return base.copyWithExtras(
      namePt: namePt,
      description: description,
      genus: genus,
      habitat: habitat,
      colorName: colorName,
      evolutionChain: chainFlat,
      typeEffectiveness: effectiveness,
    );
  }

  String? _pickLocalizedFlavorText(List entries) {
    Map<String, dynamic>? match(String langCode) {
      for (final e in entries) {
        final lang = (e['language']['name'] as String).toLowerCase();
        if (lang == langCode) return e as Map<String, dynamic>;
      }
      return null;
    }

    final entry = match('pt-br') ?? match('pt') ?? match('en');
    if (entry == null) return null;

    return (entry['flavor_text'] as String)
        .replaceAll('\n', ' ')
        .replaceAll('\f', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _pickLocalized(List entries, {required String key}) {
    Map<String, dynamic>? match(String langCode) {
      for (final e in entries) {
        final lang = (e['language']['name'] as String).toLowerCase();
        if (lang == langCode) return e as Map<String, dynamic>;
      }
      return null;
    }

    final entry = match('pt-br') ?? match('pt') ?? match('en');
    return entry?[key] as String?;
  }

  /// Converte a árvore de evolução (que pode ramificar, ex.: Eevee) em uma
  /// lista simples de estágios: cada posição da lista externa é um "nível"
  /// evolutivo, e a lista interna contém as opções nesse nível.
  Future<List<EvolutionNode>> _fetchEvolutionChainFlat(String url) async {
    final json = await _getJson(url);
    final chain = json['chain'] as Map<String, dynamic>;

    final flat = <EvolutionNode>[];

    void walk(Map<String, dynamic> node, int stage,
        {String? trigger, int? minLevel, String? item}) {
      final species = node['species'] as Map<String, dynamic>;
      final id = extractId(species['url'] as String);
      flat.add(EvolutionNode(
        id: id,
        name: species['name'] as String,
        spriteUrl:
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png',
        stage: stage,
        trigger: trigger,
        minLevel: minLevel,
        item: item,
      ));

      final evolvesTo = node['evolves_to'] as List;
      for (final child in evolvesTo) {
        final details = (child['evolution_details'] as List);
        String? childTrigger;
        int? childMinLevel;
        String? childItem;
        if (details.isNotEmpty) {
          final d = details.first as Map<String, dynamic>;
          childTrigger = (d['trigger'] as Map?)?['name'] as String?;
          childMinLevel = d['min_level'] as int?;
          childItem = (d['item'] as Map?)?['name'] as String?;
        }
        walk(child as Map<String, dynamic>, stage + 1,
            trigger: childTrigger, minLevel: childMinLevel, item: childItem);
      }
    }

    walk(chain, 0);
    return flat;
  }

  /// Calcula o multiplicador de dano recebido de cada tipo de ataque,
  /// combinando as relações de dano de todos os tipos do Pokémon
  /// (ex.: um Pokémon Fogo/Voador recebe o produto das duas tabelas).
  Future<Map<String, double>> _computeTypeEffectiveness(List<String> types) async {
    final multipliers = <String, double>{
      for (final t in const [
        'normal', 'fire', 'water', 'electric', 'grass', 'ice', 'fighting',
        'poison', 'ground', 'flying', 'psychic', 'bug', 'rock', 'ghost',
        'dragon', 'dark', 'steel', 'fairy',
      ])
        t: 1.0
    };

    for (final type in types) {
      final relations = await _fetchTypeRelations(type);

      for (final t in (relations['double_damage_from'] as List)) {
        final name = t['name'] as String;
        multipliers[name] = (multipliers[name] ?? 1.0) * 2.0;
      }
      for (final t in (relations['half_damage_from'] as List)) {
        final name = t['name'] as String;
        multipliers[name] = (multipliers[name] ?? 1.0) * 0.5;
      }
      for (final t in (relations['no_damage_from'] as List)) {
        final name = t['name'] as String;
        multipliers[name] = (multipliers[name] ?? 1.0) * 0.0;
      }
    }

    return multipliers;
  }

  Future<Map<String, dynamic>> _fetchTypeRelations(String type) async {
    if (_typeRelationsCache.containsKey(type)) return _typeRelationsCache[type]!;
    final json = await _getJson('$_baseUrl/type/$type');
    final relations = json['damage_relations'] as Map<String, dynamic>;
    _typeRelationsCache[type] = relations;
    return relations;
  }

  void dispose() {
    _client.close();
  }
}

class PokeApiException implements Exception {
  final String message;
  PokeApiException(this.message);
  @override
  String toString() => message;
}
