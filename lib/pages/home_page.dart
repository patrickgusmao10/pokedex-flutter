import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_grid_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/type_filter_bar.dart';
import '../widgets/loading_card.dart';
import '../widgets/error_view.dart';
import 'details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = PokemonService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  static const _pageSize = 24;

  List<PokedexEntry> _index = [];
  List<PokedexEntry> _filteredSource = [];
  final List<Pokemon> _loaded = [];
  int _loadedCount = 0;

  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';

  String? _selectedType;
  Set<int>? _typeIdSet;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _initialLoading = true;
      _hasError = false;
    });
    try {
      _index = await _service.fetchFullIndex();
      _applyFilters();
      await _loadMore();
    } catch (_) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Não foi possível carregar a Pokédex.\nVerifique sua conexão com a internet.';
      });
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  void _applyFilters() {
    List<PokedexEntry> src = _index;

    if (_selectedType != null && _typeIdSet != null) {
      src = src.where((e) => _typeIdSet!.contains(e.id)).toList();
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      src = src
          .where((e) => e.name.contains(q) || e.id.toString() == q)
          .toList();
    }

    _filteredSource = src;
    _loaded.clear();
    _loadedCount = 0;
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // atualiza ícone de limpar
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(_applyFilters);
      _resetScroll();
      await _loadMore();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(_applyFilters);
    _resetScroll();
    _loadMore();
  }

  Future<void> _onSelectType(String? type) async {
    setState(() {
      _selectedType = type;
      _initialLoading = true;
      _hasError = false;
    });

    if (type != null) {
      try {
        final ids = await _service.fetchIdsForType(type);
        _typeIdSet = ids.toSet();
      } catch (_) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Não foi possível filtrar por tipo.';
          _initialLoading = false;
        });
        return;
      }
    } else {
      _typeIdSet = null;
    }

    _applyFilters();
    _resetScroll();
    await _loadMore();
    if (mounted) setState(() => _initialLoading = false);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    if (_loadedCount >= _filteredSource.length) return;

    setState(() => _loadingMore = true);

    final nextIds = _filteredSource
        .skip(_loadedCount)
        .take(_pageSize)
        .map((e) => e.id)
        .toList();

    try {
      final details = await _service.fetchBasicBatch(nextIds);
      final byId = {for (final p in details) p.id: p};
      final ordered =
          nextIds.map((id) => byId[id]).whereType<Pokemon>().toList();

      setState(() {
        _loaded.addAll(ordered);
        _loadedCount += nextIds.length;
      });

      // Em telas largas/baixas, 24 itens podem caber inteiros na tela sem
      // gerar overflow — e nesse caso o listener de scroll nunca dispara.
      // Então, depois do layout, checamos: se ainda não há nada pra rolar
      // e existem mais Pokémon, carregamos automaticamente a próxima leva.
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoLoadIfNoOverflow());
    } catch (_) {
      if (_loaded.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Erro ao carregar os Pokémon.';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _autoLoadIfNoOverflow() {
    if (!mounted || _loadingMore) return;
    if (_loadedCount >= _filteredSource.length) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(_applyFilters);
    await _loadMore();
  }

  void _openDetails(Pokemon pokemon) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailsPage(pokemon: pokemon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16181D),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3350D),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pokédex',
                    style: GoogleFonts.baloo2(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (_index.isNotEmpty)
                    Text(
                      '${_index.length} Pokémon',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBarWidget(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TypeFilterBar(
                selectedType: _selectedType,
                onSelect: _onSelectType,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError && _loaded.isEmpty) {
      return ErrorView(message: _errorMessage, onRetry: _bootstrap);
    }

    if (_initialLoading && _loaded.isEmpty) {
      return _buildGrid(
        itemCount: 12,
        itemBuilder: (_, _) => const LoadingCard(),
      );
    }

    if (!_initialLoading && _filteredSource.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum Pokémon encontrado.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _buildGrid(
        itemCount: _loaded.length + (_loadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= _loaded.length) return const LoadingCard();
          final pokemon = _loaded[index];
          return PokemonGridCard(
            pokemon: pokemon,
            onTap: () => _openDetails(pokemon),
          );
        },
      ),
    );
  }

  Widget _buildGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      radius: const Radius.circular(8),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 20, 24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 175,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
