import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brasil_api.dart';
import '../database.dart';
import '../models.dart';

/// Cadastro do veículo. Marca e modelo vêm da BrasilAPI (FIPE);
/// os modelos dependem da marca selecionada.
class VehicleFormScreen extends StatefulWidget {
  final Future<void> Function() onSaved;
  const VehicleFormScreen({super.key, required this.onSaved});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _api = BrasilApi();
  final _formKey = GlobalKey<FormState>();
  final _yearCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();

  List<FipeItem> _brands = [];
  List<String> _models = [];
  FipeItem? _brand;
  String? _model;

  bool _loadingBrands = true;
  bool _loadingModels = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _engineCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loadingBrands = true;
      _error = null;
    });
    try {
      final b = await _api.getBrands();
      if (!mounted) return;
      setState(() => _brands = b);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível carregar as marcas. '
          'Verifique sua conexão e tente novamente.');
    } finally {
      if (mounted) setState(() => _loadingBrands = false);
    }
  }

  Future<void> _onBrandChanged(FipeItem? brand) async {
    setState(() {
      _brand = brand;
      _model = null;
      _models = [];
      _error = null;
      _loadingModels = brand != null;
    });
    if (brand == null) return;
    try {
      final m = await _api.getModels(brand.code);
      if (!mounted || _brand?.code != brand.code) return;
      setState(() => _models = m);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível carregar os modelos desta marca.');
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AppDatabase.instance.insertVehicle(Vehicle(
        brand: _brand!.name,
        model: _model!,
        year: int.parse(_yearCtrl.text),
        engineDisplacement: _engineCtrl.text.trim(),
      ));
      await widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Erro ao salvar o veículo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxYear = DateTime.now().year + 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Cadastre o veículo para começar a registrar abastecimentos.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(_error!),
                  trailing: _brands.isEmpty
                      ? TextButton(
                          onPressed: _loadBrands, child: const Text('Tentar'))
                      : null,
                ),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<FipeItem>(
                    isExpanded: true,
                    value: _brand,
                    decoration: InputDecoration(
                      labelText: 'Marca',
                      border: const OutlineInputBorder(),
                      suffixIcon: _loadingBrands
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                    ),
                    items: _brands
                        .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                        .toList(),
                    onChanged: _loadingBrands ? null : _onBrandChanged,
                    validator: (v) => v == null ? 'Selecione a marca' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _model,
                    decoration: InputDecoration(
                      labelText: 'Modelo',
                      border: const OutlineInputBorder(),
                      helperText: _brand == null ? 'Escolha a marca primeiro' : null,
                      suffixIcon: _loadingModels
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                    ),
                    items: _models
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (_brand == null || _loadingModels)
                        ? null
                        : (v) => setState(() => _model = v),
                    validator: (v) => v == null ? 'Selecione o modelo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                        labelText: 'Ano', border: OutlineInputBorder()),
                    validator: (v) {
                      final y = int.tryParse(v ?? '');
                      if (y == null || y < 1900 || y > maxYear) {
                        return 'Informe um ano entre 1900 e $maxYear';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _engineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cilindrada do motor',
                      hintText: 'Ex.: 1.0, 1.6, 2.0 Turbo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe a cilindrada'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: const Text('Salvar veículo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
