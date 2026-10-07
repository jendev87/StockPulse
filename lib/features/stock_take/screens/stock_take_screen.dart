import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../bloc/stock_take_bloc.dart';
import '../widgets/voice_count_bottom_sheet.dart';

class StockTakeScreen extends StatelessWidget {
  const StockTakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockTakeBloc, StockTakeState>(
      builder: (context, state) {
        final activeTake = state.activeStockTake;
        final products = state.products;
        final counts = state.counts;
        final countedCount = state.countedItemsCount;
        final totalCount = state.totalItemsCount;
        final progress = state.progress;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Physical Stock Count',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  activeTake != null
                      ? 'Session: ${activeTake.id} • $countedCount of $totalCount items'
                      : 'Stock Take Session',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.mic_rounded, color: AppTheme.primaryBlue),
                tooltip: 'Voice Count',
                onPressed: () => VoiceCountBottomSheet.show(context),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  tooltip: 'Scan Barcode',
                  onPressed: () => context.push('/scanner'),
                ),
              ),
            ],
          ),
          floatingActionButton: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'ai_vision_fab',
                onPressed: () => context.push('/ai-vision'),
                icon: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'AI Visual Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.extended(
                heroTag: 'barcode_scanner_fab',
                onPressed: () => context.push('/scanner'),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                label: const Text(
                  'Scan Barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: AppTheme.primaryBlue,
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                color: const Color(0xFF141820),
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '👷 Associate Floor Mode',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Multi-Modal Floor Capture',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final stockCount = counts[product.sku];
                          final isCounted = stockCount != null;

                          return _buildProductCard(
                            context: context,
                            product: product,
                            isCounted: isCounted,
                            physicalQty: stockCount?.physicalQty,
                          );
                        },
                      ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: AppTheme.surfaceCard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Audit Progress: $countedCount / $totalCount items',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF121418),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: activeTake == null
                          ? null
                          : () {
                              context.read<StockTakeBloc>().add(
                                    LoadReconciliation(activeTake.id),
                                  );
                              context.push('/reconciliation');
                            },
                      icon: const Icon(Icons.analytics_outlined, size: 20),
                      label: const Text(
                        'Review Reconciliation',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        disabledBackgroundColor:
                            const Color(0xFF2C3240),
                        disabledForegroundColor:
                            const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required Product product,
    required bool isCounted,
    int? physicalQty,
  }) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/count/${product.sku}');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCounted
                  ? AppTheme.statusMatch.withValues(alpha: 0.3)
                  : const Color(0xFF2C3240),
              width: isCounted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Left icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCounted
                      ? AppTheme.statusMatch.withValues(alpha: 0.12)
                      : const Color(0xFF121418),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCounted
                      ? Icons.inventory_rounded
                      : Icons.inventory_2_outlined,
                  color: isCounted
                      ? AppTheme.statusMatch
                      : const Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Middle: Name & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // SKU badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121418),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF333B4A),
                            ),
                          ),
                          child: Text(
                            product.sku,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Barcode badge
                        if (product.hasBarcode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BARCODE',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3240),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NO BARCODE',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          'Sys: ${product.systemQty}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing: Count status or Count button
              if (isCounted) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.statusMatch,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$physicalQty',
                          style: const TextStyle(
                            color: AppTheme.statusMatch,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Counted',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF475569),
                  size: 20,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Count',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.primaryBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
