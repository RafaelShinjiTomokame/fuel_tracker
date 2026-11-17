import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';

class FuelingsScreen extends StatelessWidget {
  final List<Fueling> fuelings;
  final Future<void> Function(Fueling) onDelete;
  const FuelingsScreen({super.key, required this.fuelings, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (fuelings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum abastecimento registrado.\nToque em "Abastecer" para começar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final stats = computeStats(fuelings).reversed.toList(); // mais recente primeiro
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final num2 = NumberFormat('#,##0.00', 'pt_BR');
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: stats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = stats[i];
        final f = s.fueling;
        return Dismissible(
          key: ValueKey(f.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async =>
              await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Excluir abastecimento?'),
                  content: Text('Registro de ${fmt.format(f.dateTime)}.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Excluir')),
                  ],
                ),
              ) ??
              false,
          onDismissed: (_) => onDelete(f),
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(child: Text(f.fuelType.label[0])),
              title: Text('${f.fuelType.label} • ${money.format(f.total)}'),
              subtitle: Text(
                '${fmt.format(f.dateTime)}\n'
                '${num2.format(f.liters)} L × ${money.format(f.pricePerLiter)} • '
                '${num2.format(f.odometer)} km'
                '${s.kmPerLiter != null ? '\n${num2.format(s.kmPerLiter)} km/L • ${money.format(s.costPerKm)}/km' : ''}',
              ),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }
}
