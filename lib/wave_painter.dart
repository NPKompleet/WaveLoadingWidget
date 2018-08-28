import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' hide TextStyle;

import 'package:flutter/material.dart' hide Image;

class WavePainter extends CustomPainter {
  var amplitudeRatio = 0.1;
  Color waveColor;
  Color waveBackgroundColor;
  final double fluidHeight;

  var emptyLevelRatio;
  double waveShiftRatio;
  var wavelengthRatio = 1.0;
  Size size;

  ImageShader waveImgShader;
  Matrix4 shdMatrix;
  Float64List shdMatrixArray;

  Paint waveBackgroundPaint;
  Paint wavePaint;
  Paint borderPaint;

  Animation<double> animation;

  TextPainter textPainter;
  TextStyle textStyle;

  WavePainter(
      {this.animation,
      this.waveColor,
      this.waveBackgroundColor,
      this.waveShiftRatio,
      this.fluidHeight})
      : super(repaint: animation) {
    wavePaint = Paint()..isAntiAlias = true;
    waveBackgroundPaint = Paint()
      ..color = waveBackgroundColor
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
    emptyLevelRatio = 1.0 - fluidHeight;
  }

  @override
  void paint(Canvas canvas, Size size) {
    this.size = size;
    final radius = size.width / 2;

    shdMatrix.scale(1.0, 0.5);
    shdMatrix.translate(
        waveShiftRatio * size.width, -fluidHeight * size.height);

    shdMatrix.copyIntoArray(shdMatrixArray);

    drawWaveShader();

    wavePaint.shader = waveImgShader;

    canvas.save();
    canvas.translate(radius, radius);
    canvas.drawCircle(Offset.zero, radius, waveBackgroundPaint);
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

    Path path = Path();

    if (width > 0 && height > 0) {
      // ω=2π/T, where T is period,  ω is the angular frequency
      var angularFrequency = 2 * pi / (wavelengthRatio * width);
      var amplitude = amplitudeRatio * height;
      var emptyLevel = emptyLevelRatio * height;

      Paint shaderWavePaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      PictureRecorder recorder = PictureRecorder();
      Canvas canvas = Canvas(recorder, Offset.zero & size);

      // Draw wave
      final double xEndPoint = width + 1;
      final double yEndPoint = height + 1;

      Float64List waveY = Float64List(xEndPoint.floor());
      shaderWavePaint.color = waveColor.withOpacity(0.5);

      path.moveTo(xEndPoint, yEndPoint);
      path.lineTo(0.0, yEndPoint);

      for (int xPoint = 0; xPoint < xEndPoint; xPoint++) {
        double xAxisPoint = xPoint.toDouble();
        double wx = xPoint * angularFrequency;

        // y=A*sinωx+h, where the A is amplitude of the wave
        double yAxisPoint = (amplitude * sin(wx)) + emptyLevel;
        waveY[xPoint] = yAxisPoint;
        path.lineTo(xAxisPoint, yAxisPoint);
      }

      path.close();
      canvas.drawPath(path, shaderWavePaint);

      shaderWavePaint.color = waveColor;

      // Draw another wave shifted by a sixth of the width
      // y=A*sin(ωx+φ)+h, φ is the phase shift of the wave
      final int waveShift = width ~/ 6;

      path = Path();
      path.moveTo(xEndPoint, yEndPoint);
      path.lineTo(0.0, yEndPoint);

      for (int xPoint = 0; xPoint < xEndPoint; xPoint++) {
        double xAxisPoint = xPoint.toDouble();
        path.lineTo(
            xAxisPoint, waveY[(xPoint + waveShift) % xEndPoint.floor()]);
      }

      path.close();
      canvas.drawPath(path, shaderWavePaint);

      Picture picture = recorder.endRecording();

      Image image = picture.toImage(width.floor(), height.floor());

      // Draw shader with image;
      waveImgShader =
          ImageShader(image, TileMode.repeated, TileMode.clamp, shdMatrixArray);

      image.dispose();
    }
  }
}

enum WaveWidgetShape { rectangle, circle }
