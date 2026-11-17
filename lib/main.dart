import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database.dart';
import 'models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/fueling_form_screen.dart';
import 'screens/fuelings_screen.dart';
import 'screens/vehicle_form_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // sqflite só funciona direto em Android/iOS; no desktop usa FFI.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const FuelTrackerApp());
}

class FuelTrackerApp extends StatelessWidget {
  const FuelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Combustível',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}

/// Controla qual tela exibir: cadastro (sem veículo) ou app principal.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = AppDatabase.instance;
  Vehicle? _vehicle;
  List<Fueling> _fuelings = [];
  bool _loading = true;
  String? _loadError;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await _db.getVehicle().timeout(const Duration(seconds: 10));
      final f = v == null ? <Fueling>[] : await _db.getFuelings(v.id!);
      if (!mounted) return;
      setState(() {
        _vehicle = v;
        _fuelings = f;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _confirmDeleteVehicle() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: Text(
          'O veículo ${_vehicle!.brand} ${_vehicle!.model} e TODOS os seus '
          'abastecimentos serão removidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteVehicle(_vehicle!.id!);
      _tab = 0;
      await _load();
    }
  }

  Future<void> _addFueling() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FuelingFormScreen(
          vehicle: _vehicle!,
          existing: _fuelings,
        ),
      ),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Erro ao abrir o banco de dados local.\n'
                    '(Execute em Android, iOS ou desktop; web não é suportado.)',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    child: const Text('Tentar novamente')),
              ],
            ),
          ),
        ),
      );
    }
    if (_vehicle == null) {
      return VehicleFormScreen(onSaved: _load);
    }

    final pages = [
      DashboardScreen(vehicle: _vehicle!, fuelings: _fuelings),
      FuelingsScreen(
        fuelings: _fuelings,
        onDelete: (f) async {
          await _db.deleteFueling(f.id!);
          await _load();
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_vehicle!.brand} ${_vehicle!.model}'),
        actions: [
          IconButton(
            tooltip: 'Excluir veículo',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDeleteVehicle,
          ),
        ],
      ),
      body: pages[_tab],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFueling,
        icon: const Icon(Icons.local_gas_station),
        label: const Text('Abastecer'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Abastecimentos'),
        ],
      ),
    );
  }
}
