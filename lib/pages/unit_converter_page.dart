import 'package:flutter/material.dart';

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  static const _units = <String, List<String>>{
    'Length': ['Meters', 'Kilometers', 'Feet', 'Miles'],
    'Weight': ['Kilograms', 'Grams', 'Pounds', 'Ounces'],
    'Temperature': ['Celsius', 'Fahrenheit', 'Kelvin'],
  };

  final TextEditingController _inputController = TextEditingController(
    text: '1',
  );
  String _category = 'Length';
  String _from = 'Meters';
  String _to = 'Kilometers';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  double? get _result {
    final value = double.tryParse(_inputController.text.trim());
    if (value == null) return null;
    if (_category == 'Temperature') return _convertTemperature(value);

    final meters = switch (_from) {
      'Meters' => value,
      'Kilometers' => value * 1000,
      'Feet' => value * 0.3048,
      'Miles' => value * 1609.344,
      _ => value,
    };
    final grams = switch (_from) {
      'Kilograms' => value * 1000,
      'Grams' => value,
      'Pounds' => value * 453.59237,
      'Ounces' => value * 28.349523125,
      _ => value,
    };

    if (_category == 'Length') {
      return switch (_to) {
        'Meters' => meters,
        'Kilometers' => meters / 1000,
        'Feet' => meters / 0.3048,
        'Miles' => meters / 1609.344,
        _ => meters,
      };
    }
    return switch (_to) {
      'Kilograms' => grams / 1000,
      'Grams' => grams,
      'Pounds' => grams / 453.59237,
      'Ounces' => grams / 28.349523125,
      _ => grams,
    };
  }

  double _convertTemperature(double value) {
    final celsius = switch (_from) {
      'Celsius' => value,
      'Fahrenheit' => (value - 32) * 5 / 9,
      'Kelvin' => value - 273.15,
      _ => value,
    };
    return switch (_to) {
      'Celsius' => celsius,
      'Fahrenheit' => celsius * 9 / 5 + 32,
      'Kelvin' => celsius + 273.15,
      _ => celsius,
    };
  }

  void _setCategory(String category) {
    final options = _units[category]!;
    setState(() {
      _category = category;
      _from = options.first;
      _to = options[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = _units[_category]!;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Unit Converter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _units.keys
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (value) {
              if (value != null) _setCategory(value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inputController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Value',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _from,
            decoration: const InputDecoration(labelText: 'From'),
            items: options
                .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _from = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _to,
            decoration: const InputDecoration(labelText: 'To'),
            items: options
                .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _to = value);
            },
          ),
          const SizedBox(height: 24),
          Text(
            result == null
                ? 'Enter a valid number'
                : '${result.toStringAsPrecision(8)} $_to',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
