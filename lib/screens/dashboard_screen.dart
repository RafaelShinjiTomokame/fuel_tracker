import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';

/// Dashboard: valor de cada abastecimento, km/L e R$/km (gráficos com fl_chart).
class DashboardScreen extends StatelessWidget {
  final Vehicle vehicle;
  final List<Fueling> fuelings;
  const DashboardScreen({super.key, required this.vehicle, required this.fuelings});

  @override
  Widget build(BuildContext context) {
    final stats = computeStats(fuelings);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final num2 = NumberFormat('#,##0.00', 'pt_BR');

    final withMetrics = stats.where((s) => s.kmPerLiter != null).toList();
    final totalSpent = fuelings.fold<double>(0, (a, f) => a + f.total);
    final avgKmL = withMetrics.isEmpty
        ? null
        : withMetrics.map((s) => s.kmPerLiter!).reduce((a, b) => a + b) /
            withMetrics.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text('${vehicle.brand} ${vehicle.model}'),
            subtitle: Text('${vehicle.year} • Motor ${vehicle.engineDisplacement}'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Kpi(
                  label: 'Total gasto',
                  value: money.format(totalSpent),
                  icon: Icons.payments_outlined),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Kpi(
                  label: 'Consumo médio',
                  value: avgKmL == null ? '—' : '${num2.format(avgKmL)} km/L',
                  icon: Icons.speed),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (fuelings.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Registre abastecimentos para ver os indicadores.',
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          _ChartCard(
            title: 'Valor de cada abastecimento (R\$)',
            child: _ValueBarChart(stats: stats),
          ),
          _ChartCard(
            title: 'Consumo entre abastecimentos (km/L)',
            child: withMetrics.isEmpty
                ? const _NeedMore()
                : _MetricLineChart(
                    points: withMetrics,
                    valueOf: (s) => s.kmPerLiter!,
                    format: (v) => num2.format(v),
                  ),
          ),
          _ChartCard(
            title: 'Custo por quilômetro (R\$/km)',
            child: withMetrics.isEmpty
                ? const _NeedMore()
                : _MetricLineChart(
                    points: withMetrics,
                    valueOf: (s) => s.costPerKm!,
                    format: (v) => num2.format(v),
                    color: Colors.deepOrange,
                  ),
          ),
        ],
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Kpi({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
              SizedBox(height: 200, child: child),
            ],
          ),
        ),
      );
}

class _NeedMore extends StatelessWidget {
  const _NeedMore();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text(
          'São necessários ao menos 2 abastecimentos.\n'
          'O primeiro serve apenas como referência.',
          textAlign: TextAlign.center,
        ),
      );
}

final _dayFmt = DateFormat('dd/MM');

class _ValueBarChart extends StatelessWidget {
  final List<FuelingStats> stats;
  const _ValueBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(stats, (v) => v.toStringAsFixed(0)),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              'R\$ ${rod.toY.toStringAsFixed(2)}',
              const TextStyle(color: Colors.white),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < stats.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: stats[i].fueling.total,
                color: color,
                width: 14,
                borderRadius: BorderRadius.circular(3),
              ),
            ]),
        ],
      ),
    );
  }
}

class _MetricLineChart extends StatelessWidget {
  final List<FuelingStats> points;
  final double Function(FuelingStats) valueOf;
  final String Function(double) format;
  final Color? color;
  const _MetricLineChart({
    required this.points,
    required this.valueOf,
    required this.format,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final values = points.map(valueOf).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxV - minV).abs() < 0.0001 ? maxV * 0.2 + 0.1 : (maxV - minV) * 0.2;

    return LineChart(
      LineChartData(
        minY: (minV - pad).clamp(0, double.infinity),
        maxY: maxV + pad,
        minX: -0.3,
        maxX: points.length - 1 + 0.3,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(points, (v) => v.toStringAsFixed(2)),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      format(s.y),
                      const TextStyle(color: Colors.white),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: points.length > 2,
            color: c,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: c.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }
}

FlTitlesData _titles(List<FuelingStats> items, String Function(double) left) {
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (v, meta) => Text(left(v), style: const TextStyle(fontSize: 10)),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        reservedSize: 24,
        getTitlesWidget: (v, meta) {
          final i = v.toInt();
          if (v != i.toDouble() || i < 0 || i >= items.length) {
            return const SizedBox.shrink();
          }
          // Evita sobreposição quando há muitos pontos.
          final step = (items.length / 6).ceil();
          if (i % step != 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_dayFmt.format(items[i].fueling.dateTime),
                style: const TextStyle(fontSize: 10)),
          );
        },
      ),
    ),
  );
}
