import 'package:flutter/material.dart';

/// Placeholder animado (pulso de opacidade) usado enquanto os cards da
/// grade ainda não carregaram — evita depender de um pacote extra de
/// shimmer só para isso.
class LoadingCard extends StatefulWidget {
  const LoadingCard({super.key});

  @override
  State<LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<LoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;

    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 0.9).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
