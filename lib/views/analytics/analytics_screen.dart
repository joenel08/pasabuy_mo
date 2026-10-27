import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/transaction_service.dart';
import '../common/empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _topItems = [];
  bool _loading = false;
  String _range = '30d';

  static const _ranges = ['7d', '30d', '90d', '12m'];
  static const _rangeLabels = {
    '7d': '7D',
    '30d': '30D',
    '90d': '90D',
    '12m': '12M',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final svc = context.read<TransactionService>();
      final d = await svc.myTrend(range: _range);
      final items = await svc.myItemsBreakdown(range: _range);
      if (!mounted) return;
      setState(() {
        _data = d;
        _topItems = items;
      });
    } catch (e) {
      debugPrint('[ANALYTICS] $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading && _data == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _data == null
                ? const EmptyState(
                    icon: Icons.insights_outlined,
                    title: 'No data yet',
                    subtitle: 'Complete a few deals to see your trend.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _RangePicker(
                        ranges: _ranges,
                        labels: _rangeLabels,
                        selected: _range,
                        onChanged: (r) {
                          setState(() => _range = r);
                          _load();
                        },
                      ),
                      const SizedBox(height: 12),
                      _SummaryGrid(summary: _data!['summary'] ?? {}),
                      const SizedBox(height: 12),
                      _ChartCard(data: _data!, title: _data!['label'] ?? ''),
                      const SizedBox(height: 12),
                      _ValueChartCard(data: _data!),
                      if (_topItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _TopItemsCard(items: _topItems),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }
}

// ===================================================================
// Top Items card — NEW
// ===================================================================
class _TopItemsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _TopItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxGmv = items
        .map((i) => (i['gmv'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top items by GMV',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Completed deals, ranked by gross value',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          ...items.take(10).toList().asMap().entries.map((e) {
            final i = e.key;
            final it = e.value;
            final gmv = (it['gmv'] as num?)?.toDouble() ?? 0;
            final ratio = maxGmv > 0 ? gmv / maxGmv : 0.0;
            final deals = (it['deal_count'] as num?)?.toInt() ?? 0;

            return Padding(
              padding: EdgeInsets.only(bottom: i == items.take(10).length - 1 ? 0 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: i < 3
                              ? AppColors.primary
                              : AppColors.borderSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: i < 3
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (it['item_name'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _shortMoney(gmv),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const SizedBox(width: 28),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 4,
                            backgroundColor: AppColors.borderSoft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              i < 3
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$deals deal${deals == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _shortMoney(double v) {
    if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}K';
    return '₱${v.toStringAsFixed(0)}';
  }
}

// ===================================================================
// Existing helpers — unchanged below
// ===================================================================

class _RangePicker extends StatelessWidget {
  final List<String> ranges;
  final Map<String, String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  const _RangePicker({
    required this.ranges,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: ranges.map((r) {
          final active = r == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  labels[r] ?? r,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary['total'] ?? 0;
    final completed = summary['completed'] ?? 0;
    final cancelled = summary['cancelled'] ?? 0;
    final disputed = summary['disputed'] ?? 0;
    final active = summary['active'] ?? 0;
    final value = (summary['value'] ?? 0).toDouble();
    final successRate = (summary['success_rate'] ?? 0).toDouble();
    final avgH = (summary['avg_completion_h'] ?? 0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Total deals',
                value: '$total',
                sub: '$active active',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                label: 'Success rate',
                value: '$successRate%',
                sub: '$completed completed',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Total value',
                value: _shortMoney(value),
                sub: 'completed deals',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                label: 'Avg completion',
                value: _duration(avgH),
                sub: 'on completed deals',
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Cancelled',
                value: '$cancelled',
                sub: 'by either side',
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                label: 'Disputed',
                value: '$disputed',
                sub: 'under review',
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Admin fees paid',
                value: _shortMoney((summary['fees_paid'] ?? 0).toDouble()),
                sub: 'on completed deals',
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatBox(
                label: 'Net earned',
                value: _shortMoney((summary['net_earned'] ?? 0).toDouble()),
                sub: 'after 2% fee',
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _shortMoney(double v) {
    if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}K';
    return '₱${v.toStringAsFixed(0)}';
  }

  String _duration(double hours) {
    if (hours <= 0) return '—';
    if (hours < 24) return '${hours.toStringAsFixed(0)}h';
    final d = hours / 24;
    return '${d.toStringAsFixed(1)}d';
  }
}

class _StatBox extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _StatBox({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String title;
  const _ChartCard({required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    final points = (data['points'] as List? ?? [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    if (points.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < points.length; i++) {
      final y = (points[i]['completed'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) maxY = y;
    }

    final labelStep = (points.length / 6).ceil();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 4),
          const Text('Completed deals over time',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY == 0 ? 4 : maxY + 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.borderSoft, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        if (i % labelStep != 0 && i != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[i]['label']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: points.length <= 14,
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.20),
                          AppColors.primary.withOpacity(0.00),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueChartCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ValueChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final points = (data['points'] as List? ?? [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    if (points.isEmpty) return const SizedBox.shrink();

    final bars = <BarChartGroupData>[];
    double maxY = 0;
    for (var i = 0; i < points.length; i++) {
      final y = (points[i]['value'] as num?)?.toDouble() ?? 0;
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: y,
            color: AppColors.primary,
            width: points.length > 30 ? 3 : (points.length > 14 ? 6 : 12),
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ));
      if (y > maxY) maxY = y;
    }

    final labelStep = (points.length / 6).ceil();
    final money = NumberFormat.compactCurrency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transacted value',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 4),
          const Text('Value of completed deals',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY == 0 ? 100 : maxY * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxY == 0 ? 100 : (maxY / 3).ceilToDouble(),
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.borderSoft, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maxY == 0 ? 100 : (maxY / 3).ceilToDouble(),
                      getTitlesWidget: (v, _) => Text(
                        money.format(v),
                        style: const TextStyle(
                            fontSize: 9.5, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        if (i % labelStep != 0 && i != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[i]['label']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: bars,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                      money.format(rod.toY),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}