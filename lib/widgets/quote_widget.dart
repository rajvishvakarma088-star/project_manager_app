import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/quote_model.dart';
import '../services/quote_service.dart';
import '../theme.dart';
import 'glass_card.dart';

class QuoteWidget extends StatefulWidget {
  const QuoteWidget({super.key});

  @override
  State<QuoteWidget> createState() => _QuoteWidgetState();
}

class _QuoteWidgetState extends State<QuoteWidget> {
  late Future<QuoteModel> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<QuoteService>().fetchQuote();
  }

  void _refresh() {
    final nextQuote = context.read<QuoteService>().fetchQuote();
    setState(() {
      _future = nextQuote;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuoteModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GlassCard(
            padding: const EdgeInsets.all(18),
            child: Shimmer.fromColors(
              baseColor: context.isDarkMode
                  ? const Color(0xFF2D2822)
                  : const Color(0xFFE9DED0),
              highlightColor: context.isDarkMode
                  ? const Color(0xFF3B342D)
                  : const Color(0xFFF8F1E7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Container(height: 18, width: 170, color: Colors.white),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return GlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Could not load quote',
                    style: TextStyle(
                      color: context.appTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final quote = snapshot.data!;
        return GlassCard(
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Positioned(
                left: -3,
                top: -18,
                child: Text(
                  '“',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.15),
                    fontSize: 82,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  onPressed: _refresh,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${quote.content}"',
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '- ${quote.author}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (quote.isFallback
                                    ? AppColors.warning
                                    : AppColors.success)
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        quote.source,
                        style: TextStyle(
                          color: quote.isFallback
                              ? AppColors.warning
                              : AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
