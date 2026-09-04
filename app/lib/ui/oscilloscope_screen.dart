import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/scope_models.dart';
import '../../scope_viewmodel.dart';
import 'scope_painter.dart';

/// Pantalla principal del osciloscopio.
class OscilloscopeScreen extends StatelessWidget {
  const OscilloscopeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScopeViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoppy'),
        actions: [
          _ConnectionButton(vm: vm),
        ],
      ),
      body: Column(
        children: [
          _StatusBar(vm: vm),
          Expanded(child: _ScopeCanvas(vm: vm)),
          _MeasurementBar(vm: vm),
          _ControlsBar(vm: vm),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.vm});
  final ScopeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            'SR: ${(vm.config.effectiveSampleRate / 1000).toStringAsFixed(1)} kS/s',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 12),
          Text(
            'Time/Div: ${vm.config.timebaseMs} ms',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 12),
          Text(
            'Trig: CH${vm.config.triggerChannel + 1} '
            '${vm.config.triggerEdge.name}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ScopeCanvas extends StatelessWidget {
  const _ScopeCanvas({required this.vm});
  final ScopeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onTapDown: (d) {},
        child: CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: ScopeGridPainter(
            channels: vm.config.channels,
            samplesByChannel: vm.client.latestWaveforms,
            horizontalDivs: vm.config.horizontalDivs,
            triggerChannel: vm.config.triggerChannel,
          ),
        ),
      ),
    );
  }
}

class _MeasurementBar extends StatelessWidget {
  const _MeasurementBar({required this.vm});
  final ScopeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final meas = vm.measurements;
    if (meas.isEmpty) {
      return const SizedBox(height: 40);
    }
    final m = meas.values.first;
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _item('Vpp', _fmt(m.vpp)),
            _item('Vmax', _fmt(m.vmax)),
            _item('Vmin', _fmt(m.vmin)),
            _item('Mean', _fmt(m.mean)),
            _item('Freq', m.hasFrequency ? '${_fmt(m.frequency)} Hz' : '--'),
            _item('Duty', '${_fmt(m.duty)} %'),
          ],
        ),
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(2)}k';
    return v.toStringAsFixed(3);
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({required this.vm});
  final ScopeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFF1B5E20),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Btn('RUN', () => vm.run(), color: Colors.green),
          _Btn('STOP', () => vm.stop(), color: Colors.red),
          _Btn('SINGLE', () => vm.single(), color: Colors.amber),
          const SizedBox(width: 4),
          _TimebaseControl(vm: vm),
          _TriggerControls(vm: vm),
          _ChannelsControl(vm: vm),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, this.onTap, {this.color = Colors.white});
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: Colors.black26,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

class _TimebaseControl extends StatelessWidget {
  const _TimebaseControl({required this.vm});
  final ScopeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<double>(
      value: vm.config.timebaseMs,
      dropdownColor: const Color(0xFF1B5E20),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      items: [0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500]
          .map((t) =>
              DropdownMenuItem<double>(value: t, child: Text('${t} ms/div')))
          .toList(),
      onChanged: (v) {
        if (v != null) vm.setTimebase(v);
      },
    );
  }
}

class _TriggerControls extends StatelessWidget {
  const _TriggerControls({required this.vm});
  final ScopeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<TriggerMode>(
      value: vm.config.triggerMode,
      dropdownColor: const Color(0xFF1B5E20),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      items: TriggerMode.values
          .map((m) =>
              DropdownMenuItem(value: m, child: Text('Trig: ${m.name}')))
          .toList(),
      onChanged: (v) {
        if (v != null) vm.setTriggerMode(v);
      },
    );
  }
}

class _ChannelsControl extends StatelessWidget {
  const _ChannelsControl({required this.vm});
  final ScopeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in vm.config.channels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FilterChip(
              label: Text('CH${ch.index + 1}',
                  style: const TextStyle(fontSize: 11)),
              selected: ch.on,
              onSelected: (v) => vm.setChannelOn(ch.index, v),
              selectedColor: Colors.cyan.shade700,
              backgroundColor: Colors.black26,
              labelStyle: const TextStyle(color: Colors.white),
              checkmarkColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({required this.vm});
  final ScopeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final connected = vm.connectionState.index >=
        ConnectionState.connected.index;
    return TextButton.icon(
      onPressed: () => _showConnectionDialog(context, vm),
      icon: Icon(
        connected ? Icons.link : Icons.link_off,
        color: connected ? Colors.greenAccent : Colors.redAccent,
      ),
      label: Text(
        connected ? 'Conectado' : 'Conectar',
        style: TextStyle(
            color: connected ? Colors.greenAccent : Colors.redAccent),
      ),
    );
  }
}

Future<void> _showConnectionDialog(BuildContext context, ScopeViewModel vm) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Conexión a Pico W (WiFi)'),
      content: vm.connectionState.index >= ConnectionState.connected.index
          ? const Text('Ya conectado al frontend. Pulsa Desconectar para cerrar la sesión.')
          : const Text(
              'Se conectará por TCP al puerto 22483 (control) y 22484 (datos).\n'
              'IP por defecto (modo Access Point): 192.168.4.1\n'
              'La Pico envía el mensaje SYNC al conectar.',
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        if (vm.connectionState.index >= ConnectionState.connected.index)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.disconnect();
            },
            child: const Text('Desconectar'),
          )
        else
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await vm.connect();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo conectar con la Pico')),
                  );
                }
              }
            },
            child: const Text('Conectar'),
          ),
      ],
    ),
  );
}
