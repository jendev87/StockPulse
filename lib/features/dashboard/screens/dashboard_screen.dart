import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/discrepancy.dart';
import '../../../models/enums.dart';
import '../../ai_assistant/widgets/manager_ai_sheet.dart';
import '../../stock_take/bloc/stock_take_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showSubmitToManagerDialog(BuildContext context, String stockTakeId) {
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
            Icon(Icons.assignment_turned_in_rounded,
                color: AppTheme.primaryBlue, size: 22),
            SizedBox(width: 10),
            Text(
              'Submit for Manager Audit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Lock count progress for Session #$stockTakeId and submit to Store Manager for discrepancy audit and ERP sync?',
          style: const TextStyle(
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
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<StockTakeBloc>()
                  .add(SubmitStockTakeForApproval(stockTakeId));
              _showSwitchToManagerPrompt(context);
            },
            child: const Text(
              'Submit & Notify Manager',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSwitchToManagerPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E222B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        duration: const Duration(seconds: 6),
        content: const Row(
          children: [
            Text('👔', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Count submitted! Toggle to Store Manager to audit discrepancies.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Switch to Manager',
          textColor: const Color(0xFF3B82F6),
          onPressed: () {
            context
                .read<StockTakeBloc>()
                .add(const SwitchRole(AppRole.manager));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'StockPulse',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Warehouse Store #104',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            tooltip: 'Refresh Status',
            onPressed: () {
              context.read<StockTakeBloc>().add(const LoadActiveStockTake());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<StockTakeBloc, StockTakeState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.statusMatch,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.successMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.statusShortage,
                behavior: SnackBarBehavior.floating,
                content: Text(state.errorMessage!),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == StockTakeStatusState.loading &&
              state.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          final activeTake = state.activeStockTake;
          final hasActiveTake = activeTake != null;
          final currentRole = state.currentRole;

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            backgroundColor: AppTheme.surfaceCard,
            onRefresh: () async {
              context.read<StockTakeBloc>().add(const LoadActiveStockTake());
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              children: [
                // 1. Dual-Persona Role Switcher
                _buildRoleSwitcher(context, currentRole),
                const SizedBox(height: 16),

                // 2. Role Specific Content
                if (currentRole == AppRole.associate) ...[
                  // Quick Summary Header
                  _buildSystemMetricsRow(state),
                  const SizedBox(height: 24),

                  // Main Floor Associate Workflow Card
                  Text(
                    'STOCK-TAKE WORKFLOW',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAssociateSessionCard(context, state, hasActiveTake),
                ] else ...[
                  // Manager Audit & Reconciliation Hub
                  _buildManagerHub(context, state, hasActiveTake),
                ],

                const SizedBox(height: 28),
                Text(
                  currentRole == AppRole.associate
                      ? 'QUICK ACTIONS & INVENTORY'
                      : 'MASTER CATALOG INVENTORY',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInventoryOverviewCard(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ROLE SWITCHER WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildRoleSwitcher(BuildContext context, AppRole activeRole) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242A36)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'ACTIVE WORKSPACE PERSONA',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF333B4A)),
                  ),
                  child: const Text(
                    'FRICTIONLESS SWITCH',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  context: context,
                  role: AppRole.associate,
                  title: 'Floor Associate',
                  emoji: '👷',
                  subtext: 'Counting & Multi-Modal Capture',
                  isActive: activeRole == AppRole.associate,
                  badge: 'FLOOR',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRoleCard(
                  context: context,
                  role: AppRole.manager,
                  title: 'Store Manager',
                  emoji: '👔',
                  subtext: 'Discrepancy Audit & ERP Commit',
                  isActive: activeRole == AppRole.manager,
                  badge: 'AUDIT',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required AppRole role,
    required String title,
    required String emoji,
    required String subtext,
    required bool isActive,
    required String badge,
  }) {
    const electricBlue = Color(0xFF3B82F6);

    return InkWell(
      onTap: () {
        context.read<StockTakeBloc>().add(SwitchRole(role));
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? electricBlue.withValues(alpha: 0.14)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? electricBlue : const Color(0xFF2C3240),
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: electricBlue.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isActive
                        ? electricBlue.withValues(alpha: 0.22)
                        : const Color(0xFF141820),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? electricBlue.withValues(alpha: 0.25)
                        : const Color(0xFF2C3240),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : badge,
                    style: TextStyle(
                      color: isActive ? electricBlue : const Color(0xFF94A3B8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtext,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF64748B),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ASSOCIATE VIEW (Requirement 3A)
  // ---------------------------------------------------------------------------
  Widget _buildAssociateSessionCard(
    BuildContext context,
    StockTakeState state,
    bool hasActiveTake,
  ) {
    if (hasActiveTake) {
      final active = state.activeStockTake!;
      final counted = state.countedItemsCount;
      final total = state.totalItemsCount;
      final progress = state.progress;
      final isPending = active.status == StockTakeStatus.pendingApproval;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPending
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                : AppTheme.primaryBlue.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPending
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.08)
                  : AppTheme.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFFA78BFA)
                              : AppTheme.statusSurplus,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isPending
                              ? 'Session #${active.id} (Pending Audit)'
                              : 'Session #${active.id} in progress: $counted/$total items counted',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                        : AppTheme.statusSurplus.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPending ? 'AUDIT READY' : 'IN PROGRESS',
                    style: TextStyle(
                      color: isPending
                          ? const Color(0xFFA78BFA)
                          : AppTheme.statusSurplus,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Physical Count Progress',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$counted / $total counted',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF121418),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPending ? const Color(0xFF8B5CF6) : AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Primary Action: "Continue Stock Take"
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/stock-take');
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text(
                  'Continue Stock Take',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Tool Row: [Scan Barcode] and [AI Vision Capture]
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/scanner'),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text(
                        'Scan Barcode',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF242A36),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF333B4A)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/ai-vision'),
                      icon: const Icon(Icons.auto_awesome,
                          size: 18, color: Color(0xFFA78BFA)),
                      label: const Text(
                        'AI Vision Capture',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF242A36),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF333B4A)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Secondary Action once counting underway: "Submit to Manager for Audit"
            if (counted > 0) ...[
              const SizedBox(height: 14),
              if (isPending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFFA78BFA), size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Submitted for Manager Audit',
                          style: TextStyle(
                            color: Color(0xFFDDD6FE),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context
                              .read<StockTakeBloc>()
                              .add(const SwitchRole(AppRole.manager));
                        },
                        child: const Text(
                          'Switch to Manager',
                          style: TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showSubmitToManagerDialog(context, active.id),
                    icon: const Icon(Icons.send_rounded,
                        size: 18, color: Color(0xFF60A5FA)),
                    label: const Text(
                      'Submit to Manager for Audit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF3B82F6), width: 1.2),
                      backgroundColor:
                          const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    }

    if (state.lastApprovedSessionId != null) {
      return _buildApprovedSessionCard(context, state);
    }

    return _buildEmptyStartStockTakeCard(context);
  }

  // ---------------------------------------------------------------------------
  // MANAGER VIEW (Requirement 3B)
  // ---------------------------------------------------------------------------
  Widget _buildManagerHub(
    BuildContext context,
    StockTakeState state,
    bool hasActiveTake,
  ) {
    final activeTake = state.activeStockTake;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'MANAGER AUDIT & RECONCILIATION HUB',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA78BFA),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'AUDIT MODE',
                style: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (hasActiveTake) ...[
          _buildManagerActiveSessionCard(context, state, activeTake!)
        ] else if (state.lastApprovedSessionId != null) ...[
          _buildApprovedSessionCard(context, state),
        ] else ...[
          _buildNoSessionsPendingCard(context, state),
        ],
      ],
    );
  }


  Widget _buildManagerActiveSessionCard(
    BuildContext context,
    StockTakeState state,
    dynamic activeTake,
  ) {
    // Calculate deterministic discrepancies for the manager audit metrics
    final discrepancies = state.products.map((p) {
      final physicalQty = state.counts[p.sku]?.physicalQty ?? 0;
      return Discrepancy.calculate(product: p, physicalQty: physicalQty);
    }).toList();

    final totalItems = state.products.isNotEmpty ? state.products.length : 10;
    final shortages =
        discrepancies.where((d) => d.type == DiscrepancyType.shortage).length;
    final surpluses =
        discrepancies.where((d) => d.type == DiscrepancyType.surplus).length;
    final matches =
        discrepancies.where((d) => d.type == DiscrepancyType.match).length;
    final isPending = activeTake.status == StockTakeStatus.pendingApproval;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
              : const Color(0xFF3B82F6).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isPending
                            ? const Color(0xFFA78BFA)
                            : AppTheme.statusSurplus,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Session #${activeTake.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.22)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPending ? 'PENDING AUDIT' : 'FLOOR COUNTING',
                  style: TextStyle(
                    color: isPending
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFF59E0B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${state.countedItemsCount} of ${state.totalItemsCount} items counted on floor • Discrepancy analysis ready',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),

          // Summary Metrics Cards: Total Items, Shortages, Surpluses, Matches
          Row(
            children: [
              Expanded(
                child: _buildManagerMetricCard(
                  label: 'Total Items',
                  value: '$totalItems',
                  color: Colors.white,
                  icon: Icons.inventory_2_outlined,
                  bgColor: const Color(0xFF242A36),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildManagerMetricCard(
                  label: 'Shortages',
                  value: '$shortages',
                  color: AppTheme.statusShortage,
                  icon: Icons.trending_down_rounded,
                  bgColor: AppTheme.statusShortage.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildManagerMetricCard(
                  label: 'Surpluses',
                  value: '$surpluses',
                  color: AppTheme.statusSurplus,
                  icon: Icons.trending_up_rounded,
                  bgColor: AppTheme.statusSurplus.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildManagerMetricCard(
                  label: 'Matches',
                  value: '$matches',
                  color: AppTheme.statusMatch,
                  icon: Icons.check_circle_outline_rounded,
                  bgColor: AppTheme.statusMatch.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Primary Action: "Review Discrepancies & Approve"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                context
                    .read<StockTakeBloc>()
                    .add(LoadReconciliation(activeTake.id));
                context.push('/reconciliation');
              },
              icon: const Icon(Icons.analytics_outlined, size: 20),
              label: const Text(
                'Review Discrepancies & Approve',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Action: "✨ Ask AI Copilot"
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                ManagerAiSheet.show(context, stockTakeId: activeTake.id);
              },
              icon: const Icon(Icons.auto_awesome,
                  size: 18, color: Color(0xFFA78BFA)),
              label: const Text(
                '✨ Ask AI Copilot',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF242A36),
                side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerMetricCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionsPendingCard(
    BuildContext context,
    StockTakeState state,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2C3240)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF333B4A).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF94A3B8),
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No sessions pending review',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Floor associates have not submitted any active stock takes for discrepancy review yet. Switch to Floor Associate to begin physical counting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  context
                      .read<StockTakeBloc>()
                      .add(const SwitchRole(AppRole.associate));
                },
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Switch to Floor Associate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStartStockTakeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C3240)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.playlist_add_check_rounded,
                  color: AppTheme.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready for Daily Audit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'No active count session right now.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<StockTakeBloc>().add(const StartNewStockTake());
                context.push('/stock-take');
              },
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                "Start Today's Stock Take",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedSessionCard(BuildContext context, StockTakeState state) {
    final sessionId = state.lastApprovedSessionId!;
    final erpTx = state.erpTransactionId ?? 'ERP-SYNC-2026-9042';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.statusMatch.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.statusMatch.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusMatch,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Session $sessionId',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.statusMatch.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.statusMatch.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'SYNCED',
                      style: TextStyle(
                        color: AppTheme.statusMatch,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusMatch.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Approved & Synced',
                      style: TextStyle(
                        color: AppTheme.statusMatch,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.verified,
                color: AppTheme.statusMatch,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Mock ERP ID: $erpTx',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 1.0,
              minHeight: 8,
              backgroundColor: Color(0xFF121418),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.statusMatch),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '10 / 10 SKUs verified and synchronized to system inventory.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<StockTakeBloc>().add(const StartNewStockTake());
                context.push('/stock-take');
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Start New Stock Take',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMetricsRow(StockTakeState state) {
    final totalSkus = state.products.length;
    final totalSystemUnits = state.products.fold<int>(
      0,
      (sum, item) => sum + item.systemQty,
    );

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Catalog SKUs',
            value: totalSkus > 0 ? '$totalSkus' : '10',
            icon: Icons.inventory_2_outlined,
            accentColor: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'System Units',
            value: totalSystemUnits > 0 ? '$totalSystemUnits' : '—',
            icon: Icons.layers_outlined,
            accentColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C3240)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryOverviewCard(
    BuildContext context,
    StockTakeState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C3240)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frozen 10-SKU Catalog',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3240),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LOCKED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C3240)),
          ...state.products.take(4).map((p) => ListTile(
                dense: true,
                title: Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  p.sku,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.lastApprovedSessionId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.statusMatch.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.statusMatch.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'SYNCED',
                          style: TextStyle(
                            color: AppTheme.statusMatch,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${p.systemQty} in sys',
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),
          if (state.products.length > 4) ...[
            const Divider(height: 1, color: Color(0xFF2C3240)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '+ ${state.products.length - 4} more items in warehouse catalog',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
