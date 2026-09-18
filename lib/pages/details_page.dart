import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../theme/pokemon_theme.dart';
import '../widgets/type_badge.dart';
import '../widgets/stat_bar.dart';
import '../widgets/evolution_chain_widget.dart';

class DetailsPage extends StatefulWidget {
  final Pokemon pokemon;

  const DetailsPage({super.key, required this.pokemon});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage>
    with SingleTickerProviderStateMixin {
  final _service = PokemonService();
  late final TabController _tabController;

  late Pokemon _pokemon;
  bool _loadingExtras = true;
  bool _extrasError = false;
  bool _loadingEvolutionTarget = false;

  @override
  void initState() {
    super.initState();
    _pokemon = widget.pokemon;
    _tabController = TabController(length: 3, vsync: this);
    _loadExtras();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadExtras() async {
    try {
      final full = await _service.fetchExtras(_pokemon);
      if (!mounted) return;
      setState(() {
        _pokemon = full;
        _loadingExtras = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingExtras = false;
        _extrasError = true;
      });
    }
  }

  Future<void> _openEvolution(int id) async {
    if (id == _pokemon.id) return;
    setState(() => _loadingEvolutionTarget = true);
    try {
      final list = await _service.fetchBasicBatch([id]);
      if (list.isEmpty) return;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DetailsPage(pokemon: list.first)),
      );
    } finally {
      if (mounted) setState(() => _loadingEvolutionTarget = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = PokemonTheme.gradientForTypes(_pokemon.types);
    final accent = gradient.colors.first;

    return Scaffold(
      backgroundColor: const Color(0xFF16181D),
      body: Column(
        children: [
          _buildHeader(gradient, accent),
          Material(
            color: const Color(0xFF16181D),
            child: TabBar(
              controller: _tabController,
              indicatorColor: accent,
              labelColor: accent,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Sobre'),
                Tab(text: 'Stats'),
                Tab(text: 'Evolução'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(accent),
                _buildStatsTab(accent),
                _buildEvolutionTab(accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LinearGradient gradient, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  _pokemon.idLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(
                height: 170,
                child: _pokemon.spriteUrl.isEmpty
                    ? const Icon(Icons.image_not_supported,
                        color: Colors.white70, size: 80)
                    : CachedNetworkImage(
                        imageUrl: _pokemon.spriteUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(color: Colors.white70),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.white70,
                          size: 80,
                        ),
                      ),
              ),
            const SizedBox(height: 8),
            Text(
              (_pokemon.namePt ?? _pokemon.displayName),
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (_pokemon.genus != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _pokemon.genus!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: _pokemon.types.map((t) => TypeBadge(type: t)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(Color accent) {
    final weaknesses = <MapEntry<String, double>>[];
    if (_pokemon.typeEffectiveness != null) {
      weaknesses.addAll(
        _pokemon.typeEffectiveness!.entries.where((e) => e.value > 1.0),
      );
      weaknesses.sort((a, b) => b.value.compareTo(a.value));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingExtras)
            const Center(child: Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CircularProgressIndicator(),
            ))
          else if (_extrasError)
            const Text(
              'Não foi possível carregar todos os detalhes agora.',
              style: TextStyle(color: Colors.white54),
            )
          else if (_pokemon.description != null)
            Text(
              _pokemon.description!,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
            ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _infoTile(
                  icon: Icons.straighten,
                  label: 'Altura',
                  value: '${_pokemon.heightMeters.toStringAsFixed(1)} m',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Peso',
                  value: '${_pokemon.weightKg.toStringAsFixed(1)} kg',
                  accent: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoTile(
            icon: Icons.terrain,
            label: 'Habitat',
            value: PokemonTheme.ptHabitat(_pokemon.habitat),
            accent: accent,
            fullWidth: true,
          ),

          const SizedBox(height: 20),
          const Text('Habilidades',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pokemon.abilities
                .map((a) => Chip(
                      label: Text(PokemonTheme.prettyName(a)),
                      backgroundColor: accent.withValues(alpha: 0.18),
                      labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
                      side: BorderSide(color: accent.withValues(alpha: 0.4)),
                    ))
                .toList(),
          ),

          if (weaknesses.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Fraquezas',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weaknesses.map((e) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TypeBadge(type: e.key),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x${e.value % 1 == 0 ? e.value.toInt() : e.value}',
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._pokemon.stats.map((s) => StatBar(stat: s, color: accent)),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              Text('${_pokemon.totalStats}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionTab(Color accent) {
    if (_loadingExtras || _loadingEvolutionTarget) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pokemon.evolutionChain == null) {
      return const Center(
        child: Text(
          'Não foi possível carregar a cadeia evolutiva.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: EvolutionChainWidget(
          nodes: _pokemon.evolutionChain!,
          accentColor: accent,
          onTapNode: _openEvolution,
        ),
      ),
    );
  }
}
