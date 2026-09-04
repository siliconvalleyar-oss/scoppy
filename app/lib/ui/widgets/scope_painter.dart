import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/scope_models.dart';

/// Dibuja la rejilla de osciloscopio (10x8) y las formas de onda.
class ScopeGridPainter extends CustomPainter {
  ScopeGridPainter({
    required this.channels,
    required this.samplesByChannel,
    required this.horizontalDivs,
    required this.triggerChannel,
  });

  final List<ScopeChannel> channels;
  final Map<int, List<int>> samplesByChannel;
  final double horizontalDivs;
  final int triggerChannel;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final border = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final gridLine = Paint()
      ..color = const Color(0x332E7D32)
      ..strokeWidth = 0.5;

    // Rejilla 10 columnas x 8 filas.
    for (var i = 1; i < 10; i++) {
      final x = i * w / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridLine);
    }
    for (var i = 1; i < 8; i++) {
      final y = i * h / 8;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridLine);
    }
    canvas.drawRect(Offset.zero & size, border);

    // Líneas de nivel de tierra (0V) por canal encendido.
    for (final ch in channels) {
      if (!ch.on) continue;
      final groundY = _groundY(ch, h);
      final gp = Paint()
        ..color = _channelColor(ch.index)
        ..strokeWidth = 0.8;
      for (var x = 0.0; x < w; x += 8) {
        canvas.drawLine(Offset(x, groundY), Offset(x + 4, groundY), gp);
      }
    }

    // Formas de onda.
    for (final ch in channels) {
      if (!ch.on) continue;
      final samples = samplesByChannel[ch.index];
      if (samples == null || samples.isEmpty) continue;
      _drawWaveform(canvas, size, ch, samples);
    }
  }

  void _drawWaveform(
      Canvas canvas, Size size, ScopeChannel ch, List<int> samples) {
    final paint = Paint()
      ..color = _channelColor(ch.index)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final n = samples.length;
    if (n < 2) return;

    final step = w / (n - 1);
    for (var i = 0; i < n; i++) {
      final x = i * step;
      final y = _sampleY(samples[i], ch, h);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  /// Posición Y de los voltios de un valor de muestra.
  double _sampleY(int sample, ScopeChannel ch, double h) {
    // Escala horizontal en divisiones.
    final divH = h / 8;
    // Valor en voltios relativo al 0V = centro vertical del canal.
    final volts = (sample / 4095.0) * (ch.voltsPerDiv * 8) - ch.voltsPerDiv * 4;
    final center = _groundY(ch, h);
    return center - (volts / (ch.voltsPerDiv * 8)) * h;
  }

  /// Y del 0V del canal (offset de posición en divisiones).
  double _groundY(ScopeChannel ch, double h) {
    final divH = h / 8;
    return h / 2 + ch.offsetDivs * divH;
  }

  static Color _channelColor(int index) {
    const colors = [
      Color(0xFF00E5FF),
      Color(0xFFFFD600),
      Color(0xFFFF5252),
      Color(0xFF69F0AE),
      Color(0xFFB388FF),
      Color(0xFFFF8A65),
      Color(0xFFFFF59D),
      Color(0xFF80D8FF),
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant ScopeGridPainter old) =>
      old.channels != channels ||
      old.samplesByChannel != samplesByChannel ||
      old.horizontalDivs != horizontalDivs;
}
