import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/discrepancy.dart';
import '../../../models/enums.dart';
import '../../ai_assistant/widgets/manager_ai_sheet.dart';
import '../../stock_take/bloc/stock_take_bloc.dart';

class ReconciliationScreen extends StatelessWidget {
  const ReconciliationScreen({super.key});

  void _showApprovalDialog(BuildContext context, String stockTakeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF333B4A)),
        ),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppTheme.statusMatch, size: 22),
            SizedBox(width: 10),
            Text(
              'Commit to ERP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will commit stock adjustments to SQLite system inventory.',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusMatch,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<StockTakeBloc>().add(ApproveStockTake(stockTakeId));
            },
            child: const Text(
              'Confirm & Commit',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StockTakeBloc, StockTakeState>(
      listener: (context, state) {
        if (state.status == StockTakeStatusState.completed) {
          final txId = state.erpTransactionId ?? 'ERP-SYNC-2026-9042';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.statusMatch,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Take Approved & Committed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mock ERP Transaction ID: $txId',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          context.go('/');
        }
      },
      builder: (context, state) {
        final activeTake = state.activeStockTake;
        final discrepancies = state.discrepancies;
        final isApproving = state.status == StockTakeStatusState.loading;
        final sessionId = activeTake?.id ?? 'ST-001';
        final isManager = state.currentRole == AppRole.manager;


        final totalItems = discrepancies.length;
        final matchCount =
            discrepancies.where((d) => d.type == DiscrepancyType.match).length;
        final shortageCount = discrepancies
            .where((d) => d.type == DiscrepancyType.shortage)
            .length;
        final surplusCount =
            discrepancies.where((d) => d.type == DiscrepancyType.surplus).length;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Reconciliation Review',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '👔 Manager Approval Mode',
                        style: TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Session: $sessionId • 10-SKU Master Catalog',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue),
                tooltip: 'Ask AI Assistant',
                onPressed: () {
                  ManagerAiSheet.show(context, stockTakeId: sessionId);
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          floatingActionButton: discrepancies.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    ManagerAiSheet.show(context, stockTakeId: sessionId);
                  },
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text(
                    'Ask AI Assistant',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
          body: discrepancies.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                )
              : Column(
                  children: [
                    // Top Summary Banner: Total (10), Matched, Shortages, Surpluses
                    _buildTopSummaryBanner(
                      total: totalItems > 0 ? totalItems : 10,
                      matched: matchCount,
                      shortage: shortageCount,
                      surplus: surplusCount,
                    ),

                    // Copilot Quick Access Strip
                    GestureDetector(
                      onTap: () {
                        ManagerAiSheet.show(context, stockTakeId: sessionId);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                AppTheme.primaryBlue.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppTheme.primaryBlue,
                              size: 16,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'StockPulse Copilot is ready to analyze discrepancies',
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Color(0xFF93C5FD),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'DETERMINISTIC VARIANCE BREAKDOWN',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),

                    // Detailed Discrepancy List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 85),
                        itemCount: discrepancies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = discrepancies[index];
                          final count = state.counts[item.sku];
                          return _buildDiscrepancyCard(item, count?.method);
                        },
                      ),
                    ),

                  ],
                ),
          bottomNavigationBar: discrepancies.isEmpty
              ? null
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceCard,
                    border: Border(
                      top: BorderSide(color: Color(0xFF2C3240), width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: (isApproving || activeTake == null || !isManager)
                                ? null
                                : () =>
                                    _showApprovalDialog(context, activeTake.id),
                            icon: isApproving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_outlined,
                                    size: 22),
                            label: Text(
                              isApproving
                                  ? 'Synchronizing ERP Inventory...'
                                  : isManager
                                      ? 'Approve & Commit to ERP'
                                      : 'Approve & Commit to ERP (Manager Only)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isManager
                                  ? AppTheme.statusMatch
                                  : const Color(0xFF242A36),
                              foregroundColor: isManager
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              disabledBackgroundColor: const Color(0xFF242A36),
                              disabledForegroundColor: const Color(0xFF64748B),
                              elevation: isManager ? 2 : 0,
                            ),
                          ),
                        ),
                        if (!isManager) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline,
                                  size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              const Text(
                                'Manager Approval Required. ',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 11.5),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.read<StockTakeBloc>().add(
                                        const SwitchRole(AppRole.manager),
                                      );
                                },
                                child: const Text(
                                  'Switch to Manager',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTopSummaryBanner({
    required int total,
    required int matched,
    required int shortage,
    required int surplus,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C3240)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBannerTile(
              label: 'Total Items',
              value: '$total',
              color: Colors.white,
              icon: Icons.inventory_2_outlined,
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFF2C3240)),
          Expanded(
            child: _buildBannerTile(
              label: 'Matched',
              value: '$matched',
              color: AppTheme.statusMatch,
              icon: Icons.check_circle_outline,
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFF2C3240)),
          Expanded(
            child: _buildBannerTile(
              label: 'Shortages',
              value: '$shortage',
              color: AppTheme.statusShortage,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFF2C3240)),
          Expanded(
            child: _buildBannerTile(
              label: 'Surpluses',
              value: '$surplus',
              color: AppTheme.statusSurplus,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscrepancyCard(
    Discrepancy item,
    IdentificationMethod? method,
  ) {
    Color cardBorderColor;
    if (item.type == DiscrepancyType.match) {
      cardBorderColor = const Color(0xFF2C3240);
    } else if (item.type == DiscrepancyType.shortage) {
      cardBorderColor = AppTheme.statusShortage.withValues(alpha: 0.45);
    } else {
      cardBorderColor = AppTheme.statusSurplus.withValues(alpha: 0.45);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name and SKU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121418),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF333B4A)),
                          ),
                          child: Text(
                            item.sku,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildMethodBadge(method),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Clear Delta Tag: +2 SURPLUS (Amber), -4 SHORTAGE (Red), or MATCH (Green)
              _buildDeltaTag(item),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF262C38)),
          const SizedBox(height: 8),

          // Quantities Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'System Qty: ',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${item.systemQty}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Physical Qty: ',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${item.physicalQty}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                item.variance == 0
                    ? 'Variance: 0'
                    : item.variance > 0
                        ? 'Variance: +${item.variance}'
                        : 'Variance: ${item.variance}',
                style: TextStyle(
                  color: item.variance == 0
                      ? AppTheme.statusMatch
                      : item.variance < 0
                          ? AppTheme.statusShortage
                          : AppTheme.statusSurplus,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge(IdentificationMethod? method) {
    IconData icon;
    String label;
    Color color;

    switch (method) {
      case IdentificationMethod.barcode:
        icon = Icons.qr_code_scanner;
        label = 'Barcode';
        color = const Color(0xFF38BDF8);
        break;
      case IdentificationMethod.ai:
        icon = Icons.auto_awesome;
        label = 'AI Vision';
        color = const Color(0xFFA855F7);
        break;
      case IdentificationMethod.voice:
        icon = Icons.mic;
        label = 'Voice';
        color = const Color(0xFFF97316);
        break;
      case IdentificationMethod.manual:
        icon = Icons.edit_note;
        label = 'Manual';
        color = const Color(0xFF94A3B8);
        break;
      case null:
        icon = Icons.help_outline;
        label = 'Manual';
        color = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaTag(Discrepancy item) {
    Color color;
    String text;
    IconData icon;

    switch (item.type) {
      case DiscrepancyType.match:
        color = AppTheme.statusMatch;
        text = 'MATCH';
        icon = Icons.check_circle_rounded;
        break;
      case DiscrepancyType.shortage:
        color = AppTheme.statusShortage;
        text = '${item.variance} SHORTAGE';
        icon = Icons.arrow_downward_rounded;
        break;
      case DiscrepancyType.surplus:
        color = AppTheme.statusSurplus;
        text = '+${item.variance} SURPLUS';
        icon = Icons.arrow_upward_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
