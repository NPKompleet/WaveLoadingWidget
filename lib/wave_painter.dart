import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' hide TextStyle;

import 'package:flutter/material.dart' hide Image;

class WavePainter extends CustomPainter {
  var amplitudeRatio = 0.1;
  Color waveColor;
  Color waveBGColor;
  final double fluidHeight;

  var waterLevelRatio;
  var mWaterLevelRatio = 1.0;
  double waveShiftRatio;
  var progressValue = 20;
  var wavelengthRatio = 1.0;
  Size size;

  ImageShader waveImgShader;
  Matrix4 shdMatrix;
  Float64List shdMatrixArray;

  Image image;

  Paint waveBGPaint;
  Paint wavePaint;
  Paint borderPaint;

  Animation<double> animation;

  TextPainter textPainter;
  TextStyle textStyle;

  WavePainter(
      {this.animation,
      this.waveColor,
      this.waveBGColor,
      this.waveShiftRatio,
      this.fluidHeight})
      : super(repaint: animation) {
    wavePaint = Paint()..isAntiAlias = true;
    waveBGPaint = Paint()
      ..color = waveBGColor
      ..style = PaintingStyle.fill;
    borderPaint = Paint()
      ..color = waveColor
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    shdMatrix = Matrix4.identity();
    shdMatrixArray = Float64List(16);
    textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
    textStyle = const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w500,
      fontFamily: 'Times New Roman',
      fontSize: 25.0,
    );
    assert(fluidHeight <= 1.0, 'fluid height must be between 0 and 1');
    assert(fluidHeight >= 0.0, 'fluid height must be between 0 and 1');
    waterLevelRatio = 1.0 - fluidHeight;
  }

  @override
  void paint(Canvas canvas, Size size) {
    this.size = size;
    final radius = size.width / 2;

    shdMatrix.scale(1.0, 0.5);
    shdMatrix.translate(waveShiftRatio * size.width,
        (waterLevelRatio - mWaterLevelRatio) * size.height);

    shdMatrix.copyIntoArray(shdMatrixArray);

    drawWaveShader();

    wavePaint.shader = waveImgShader;

    canvas.save();
    canvas.translate(radius, radius);
    canvas.drawCircle(Offset.zero, radius, waveBGPaint);
    canvas.drawCircle(Offset.zero, radius, wavePaint);
    canvas.drawCircle(Offset.zero, radius, borderPaint);

    textPainter.text = TextSpan(
      text: '${(fluidHeight*100).floor()}%',
      style: textStyle,
    );

    textPainter.layout();

    textPainter.paint(
        canvas, Offset(-(textPainter.width / 2), -(textPainter.height / 2)));

    canvas.restore();
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }

  /// Draws the [ImageShader] that will be used to paint the wave
  void drawWaveShader() {
    double width = size.width;
    double height = size.height;

    if (width > 0 && height > 0) {
      // ω=2π/T, where T= period
      var angularFrequency = 2 * pi / (wavelengthRatio * width);
      var amplitude = amplitudeRatio * height;
      var waterLevel = waterLevelRatio * height;

      Paint shaderWavePaint = new Paint()
        ..strokeWidth = 2.0
        ..isAntiAlias = true;

      PictureRecorder recorder = new PictureRecorder();
      Canvas canvas = new Canvas(recorder, Offset.zero & size);

      // Draw wave
      final double endX = width + 1;
      final double endY = height + 1;

      Float64List waveY = new Float64List(endX.floor());
      shaderWavePaint.color = waveColor.withOpacity(0.3);

      for (int beginX = 0; beginX < endX; beginX++) {
        double beginXPoint = beginX.toDouble();
        double wx = beginX * angularFrequency;

        // y=Asin(ωx+φ)+h
        double beginY = (amplitude * sin(wx)) + waterLevel;

        canvas.drawLine(Offset(beginXPoint, beginY), Offset(beginXPoint, endY),
            shaderWavePaint);
        waveY[beginX] = beginY;
      }

      shaderWavePaint.color = waveColor;

      // Draw another wave shifted by a quarter of the width
      final int wave2Shift = width ~/ 6;
      for (int beginX = 0; beginX < endX; beginX++) {
        double beginXPoint = beginX.toDouble();
        canvas.drawLine(
            Offset(beginXPoint, waveY[(beginX + wave2Shift) % endX.floor()]),
            Offset(beginXPoint, endY),
            shaderWavePaint);
      }

      Picture picture = recorder.endRecording();

      image = picture.toImage(width.floor(), height.floor());

      // Draw shader with image;
      waveImgShader =
          ImageShader(image, TileMode.repeated, TileMode.clamp, shdMatrixArray);

      image.dispose();
    }
  }
}
