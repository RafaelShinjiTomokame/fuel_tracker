# Controle de Gastos com Combustível

Aplicativo Flutter para registrar abastecimentos de um veículo e acompanhar gastos com combustível e consumo ao longo do tempo.
Atividade Substitutiva da Prova 1 — Programação para Dispositivos Móveis II (Fatec) — Prof. Arley.

## Descrição

- **Cadastro de veículo (apenas um por vez):** marca, modelo, ano e cilindrada. Marcas e modelos são consultados na BrasilAPI (tabela FIPE) e a lista de modelos depende da marca escolhida. Para cadastrar outro veículo é preciso excluir o atual; a exclusão pede confirmação e remove também todos os abastecimentos associados.
- **Registro de abastecimentos:** tipo de combustível (etanol, gasolina, diesel), preço por litro, quilometragem, litros e data/horário. O valor total (preço × litros) é calculado automaticamente.
- **Persistência local:** veículo e abastecimentos ficam salvos em SQLite no dispositivo e permanecem após fechar e reabrir o app.
- **Dashboard:** valor de cada abastecimento, consumo (km/L) e custo por quilômetro (R$/km), com gráficos de evolução.

### Regras dos indicadores

Todos os registros são considerados abastecimentos que completam o tanque. A partir do segundo abastecimento:

- Distância percorrida = km atual − km do abastecimento anterior
- Consumo (km/L) = distância ÷ litros do abastecimento atual
- Custo (R$/km) = valor total do abastecimento atual ÷ distância

O primeiro abastecimento é só a referência inicial e não exibe km/L nem R$/km. A quilometragem informada precisa ser coerente com os registros vizinhos (maior que a do anterior e menor que a do seguinte, pela data).

## Como executar

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.19+ (Dart 3.3+), um emulador ou dispositivo Android/iOS e conexão com a internet (para consultar marcas e modelos no cadastro).

```bash
flutter pub get
flutter run
```

Testes dos cálculos:

```bash
flutter test
```

> Se a pasta `android/` / `ios/` não existir no clone, gere as plataformas com `flutter create .` na raiz do projeto (não sobrescreve `lib/` nem `pubspec.yaml`).
> No Android é necessária a permissão de internet; o `flutter create` já a inclui no manifesto.

## API utilizada

- [BrasilAPI — FIPE](https://brasilapi.com.br/docs#tag/FIPE)
  - `GET /api/fipe/marcas/v1/carros` — lista de marcas
  - `GET /api/fipe/veiculos/v1/carros/{codigoMarca}` — modelos da marca selecionada

## Bibliotecas adotadas

| Biblioteca | Uso |
|---|---|
| [`http`](https://pub.dev/packages/http) | Consumo da BrasilAPI |
| [`sqflite`](https://pub.dev/packages/sqflite) + [`path`](https://pub.dev/packages/path) | Persistência local (SQLite) |
| [`fl_chart`](https://pub.dev/packages/fl_chart) | Gráficos do dashboard |
| [`intl`](https://pub.dev/packages/intl) + `flutter_localizations` | Formatação de datas e moeda (pt-BR) |

## Estrutura

```
lib/
├── main.dart                     # App, navegação e controle de telas
├── models.dart                   # Vehicle, Fueling e cálculo dos indicadores
├── database.dart                 # SQLite (veículo + abastecimentos)
├── brasil_api.dart               # Cliente da BrasilAPI
└── screens/
    ├── vehicle_form_screen.dart  # Cadastro do veículo
    ├── fueling_form_screen.dart  # Novo abastecimento
    ├── fuelings_screen.dart      # Lista de abastecimentos
    └── dashboard_screen.dart     # Indicadores e gráficos
test/stats_test.dart              # Testes dos cálculos
```