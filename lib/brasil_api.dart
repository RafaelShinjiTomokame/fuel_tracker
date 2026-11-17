import 'dart:convert';

import 'package:http/http.dart' as http;

class FipeItem {
  final String code;
  final String name;
  const FipeItem(this.code, this.name);
}

/// Cliente da BrasilAPI (tabela FIPE).
/// Docs: https://brasilapi.com.br/docs#tag/FIPE
class BrasilApi {
  static const _base = 'https://brasilapi.com.br/api/fipe';
  static const _vehicleType = 'carros';

  final http.Client _client;
  BrasilApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<dynamic>> _getList(String path) async {
    final res = await _client
        .get(Uri.parse('$_base$path'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Erro ${res.statusCode} ao consultar a BrasilAPI.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  /// GET /fipe/marcas/v1/carros -> [{"nome": "...", "valor": "21"}]
  Future<List<FipeItem>> getBrands() async {
    final data = await _getList('/marcas/v1/$_vehicleType');
    final items = data
        .map((e) => FipeItem('${e['valor']}', '${e['nome']}'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  /// GET /fipe/veiculos/v1/carros/{codigoMarca} -> [{"modelo": "...", "valor": ...}]
  /// A lista de modelos depende da marca escolhida.
  Future<List<String>> getModels(String brandCode) async {
    final data = await _getList('/veiculos/v1/$_vehicleType/$brandCode');
    final names = data.map((e) => '${e['modelo']}').toSet().toList()..sort();
    return names;
  }
}
