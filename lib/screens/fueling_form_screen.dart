import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database.dart';
import '../models.dart';

/// Registro de um abastecimento. O total (preço × litros) é exibido em tempo real.
class FuelingFormScreen extends StatefulWidget {
  final Vehicle vehicle;
  final List<Fueling> existing;
  const FuelingFormScreen({super.key, required this.vehicle, required this.existing});

  @override
  State<FuelingFormScreen> createState() => _FuelingFormScreenState();
}

class _FuelingFormScreenState extends State<FuelingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();

  FuelType _fuel = FuelType.gasolina;
  DateTime _dateTime = DateTime.now();
  bool _saving = false;

  final _fmt = DateFormat('dd/MM/yyyy HH:mm');
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void dispose() {
    _priceCtrl.dispose();
    _kmCtrl.dispose();
    _litersCtrl.dispose();
    super.dispose();
  }

  /// Aceita "5,89" ou "5.89"; para milhares usa a regra: se tem vírgula, ponto = milhar.
  double? _num(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    if (s.contains(',')) return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.'));
    return double.tryParse(s);
  }

  double get _total => (_num(_priceCtrl.text) ?? 0) * (_num(_litersCtrl.text) ?? 0);

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() => _dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String? _validateKm(String? v) {
    final km = _num(v);
    if (km == null || km < 0) return 'Informe a quilometragem';
    // O odômetro deve ser coerente com os registros vizinhos (por data).
    Fueling? before, after;
    for (final f in widget.existing) {
      if (f.dateTime.isBefore(_dateTime) &&
          (before == null || f.dateTime.isAfter(before.dateTime))) {
        before = f;
      }
      if (!f.dateTime.isBefore(_dateTime) &&
          (after == null || f.dateTime.isBefore(after.dateTime))) {
        after = f;
      }
    }
    if (before != null && km <= before.odometer) {
      return 'Deve ser maior que ${before.odometer.toStringAsFixed(0)} km '
          '(abastecimento anterior)';
    }
    if (after != null && km >= after.odometer) {
      return 'Deve ser menor que ${after.odometer.toStringAsFixed(0)} km '
          '(abastecimento seguinte)';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await AppDatabase.instance.insertFueling(Fueling(
      vehicleId: widget.vehicle.id!,
      fuelType: _fuel,
      pricePerLiter: _num(_priceCtrl.text)!,
      odometer: _num(_kmCtrl.text)!,
      liters: _num(_litersCtrl.text)!,
      dateTime: _dateTime,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo abastecimento')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<FuelType>(
                value: _fuel,
                decoration: const InputDecoration(
                    labelText: 'Tipo de combustível', border: OutlineInputBorder()),
                items: FuelType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _fuel = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Preço por litro',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = _num(v);
                  return (n == null || n <= 0) ? 'Informe um preço válido' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Quilometragem atual',
                    suffixText: 'km',
                    border: OutlineInputBorder()),
                validator: _validateKm,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _litersCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Litros abastecidos',
                    suffixText: 'L',
                    border: OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = _num(v);
                  return (n == null || n <= 0) ? 'Informe a quantidade de litros' : null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data e horário',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(_fmt.format(_dateTime)),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Valor total'),
                  trailing: Text(
                    _money.format(_total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: const Text('Salvar abastecimento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
