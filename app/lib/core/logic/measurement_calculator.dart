import 'dart:math';

import '../models/scope_models.dart';

/// Resultado de las mediciones de un canal (ver REFERENCIA_FUNCIONALIDAD.md §4).
class Measurements {
  Measurements({
    this.vmin = 0,
    this.vmax = 0,
    this.vpp = 0,
    this.mean = 0,
    this.dcRms = 0,
    this.acRms = 0,
    this.periodUs = 0,
    this.frequency = 0,
    this.duty = 0,
  });

  double vmin;
  double vmax;
  double vpp;
  double mean;
  double dcRms;
  double acRms;
  double periodUs;
  double frequency;
  double duty;

  bool get hasFrequency => frequency > 0;
}

/// Calcula las mediciones de osciloscopio sobre muestras ADC.
///
/// Conversión ADC -> voltios: V = sample * voltsPerDiv / 4095 * scale.
class MeasurementCalculator {
  /// Calcula todas las mediciones sobre [samples] (valores ADC 0-4095).
  ///
  /// [fullScaleVolts] es el rango de voltaje de pico (max - min) del canal;
  /// se asume 3.3V si no se conoce. [fullSamples] permite restringir el
  /// cálculo al intervalo visible.
  static Measurements calculate(
    List<int> samples, {
    int? fullSamples,
    double fullScaleVolts = 3.3,
  }) {
    final n = fullSamples ?? samples.length;
    if (n <= 0 || samples.isEmpty) return Measurements();
    final count = min(n, samples.length);

    var vmin = samples[0].toDouble();
    var vmax = samples[0].toDouble();
    var sum = 0.0;
    var sumSq = 0.0;

    for (var i = 0; i < count; i++) {
      final v = samples[i].toDouble();
      if (v < vmin) vmin = v;
      if (v > vmax) vmax = v;
      sum += v;
      sumSq += v * v;
    }

    final meanA = sum / count;
    final meanSq = sumSq / count;
    final dcRms = sqrt(meanSq);
    final variance = meanSq - (meanA * meanA);
    final acRms = variance > 0 ? sqrt(variance) : 0.0;

    // Convertir a voltios escalando por el rango del ADC.
    const adcRange = 4095.0;
    final scale = fullScaleVolts / adcRange;
    final volMin = vmin * scale;
    final volMax = vmax * scale;
    final volMean = meanA * scale;
    final volDcRms = dcRms * scale;
    final volAcRms = acRms * scale;

    // Periodo / frecuencia por cruce de cero del punto medio.
    final mid = (vmin + vmax) / 2.0;
    var risingCrosses = <int>[];
    var highCount = 0;
    for (var i = 1; i < count; i++) {
      if (samples[i - 1] < mid && samples[i] >= mid) {
        risingCrosses.add(i);
      }
      if (samples[i] > mid) highCount++;
    }

    var periodUs = 0.0;
    if (risingCrosses.length >= 2) {
      periodUs = (risingCrosses.last - risingCrosses.first) *
          1000.0 * // (ver nota muestreo us)
          1.0;
      // Periodo en us depende del sample rate; aquí se calcula por índice.
    }

    final duty = count > 0 ? (highCount / count) * 100.0 : 0.0;

    return Measurements(
      vmin: volMin,
      vmax: volMax,
      vpp: (volMax - volMin).abs(),
      mean: volMean,
      dcRms: volDcRms,
      acRms: volAcRms,
      periodUs: periodUs,
      frequency: periodUs > 0 ? 1000000.0 / periodUs : 0,
      duty: duty,
    );
  }

  /// Escala de voltaje por canal (volts/div * nº de divisiones verticales).
  static double verticalScaleVolts(ScopeChannel ch) {
    return ch.voltsPerDiv * 8; // grid 10x8
  }
}
