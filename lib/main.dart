import 'dart:convert';
import 'package:flutter/material.dart';
import 'converter.dart';
import 'history_service.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const NumberConverterApp());
}

class NumberConverterApp extends StatelessWidget {
  const NumberConverterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Converter',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});
  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController _inputController = TextEditingController();
  int _fromBase = 10;
  int _precision = 12;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await HistoryService.load();
    setState(() => _history = h);
  }

  void _convert() {
    final s = _inputController.text.trim();
    try {
      final outDec = Converter.convert(s, _fromBase, 10, precision: _precision);
      final outBin = Converter.convert(s, _fromBase, 2, precision: _precision);
      final outOct = Converter.convert(s, _fromBase, 8, precision: _precision);
      final outHex = Converter.convert(s, _fromBase, 16, precision: _precision);
      final map = {
        'input': s,
        'fromBase': _fromBase,
        'outputs': {'2': outBin, '8': outOct, '10': outDec, '16': outHex},
        'ts': DateTime.now().toIso8601String()
      };
      HistoryService.add(map);
      setState(() {
        _history.insert(0, map);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Widget _outputCard(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outputs = _history.isNotEmpty ? _history.first['outputs'] as Map<String, dynamic> : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Number Converter')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(labelText: 'Input number (e.g. 1A.F or -101.01)'),
            ),
            Row(
              children: [
                const Text('From base:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _fromBase,
                  items: [for (var b = 2; b <= 36; b++) DropdownMenuItem(value: b, child: Text(b.toString()))],
                  onChanged: (v) => setState(() => _fromBase = v ?? 10),
                ),
                const Spacer(),
                const Text('Precision:'),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: _precision.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _precision = int.tryParse(v) ?? 12),
                  ),
                ),
              ],
            ),
            ElevatedButton(onPressed: _convert, child: const Text('Convert')),
            const SizedBox(height: 8),
            if (outputs != null) ...[
              _outputCard('Binary (base 2)', outputs['2'] ?? ''),
              _outputCard('Octal (base 8)', outputs['8'] ?? ''),
              _outputCard('Decimal (base 10)', outputs['10'] ?? ''),
              _outputCard('Hex (base 16)', outputs['16'] ?? ''),
            ],
            const SizedBox(height: 12),
            const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (ctx, i) {
                  final item = _history[i];
                  return ListTile(
                    title: Text('${item['input']} (b${item['fromBase']})'),
                    subtitle: Text((item['outputs'] as Map<String, dynamic>)['10'] ?? ''),
                    trailing: Text(item['ts'].toString().split('T').first),
                    onTap: () {
                      setState(() {
                        _inputController.text = item['input'];
                        _fromBase = item['fromBase'];
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
