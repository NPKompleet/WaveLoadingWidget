import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Image;

class WavePainter extends CustomPainter {
  var amplitudeRatio = 0.1;
  Color waveColor;
  Color waveBGColor;
  //var bgg= 0.6;
  final double bgg;
  var waterLevelRatio;
  var mWaterLevelRatio = 1.0;
  //var waveShiftRatio= 0.8;
  double waveShiftRatio;
  var progressValue = 20;
  var wavelengthRatio = 1.0;
  Size size;

  //drawing
  ImageShader waveImgShader;
  static ImageShader waveImgShader2;
  Matrix4 shdMatrix;
  Float64List shdMatrixArray;

  Image image;

  Paint waveBGPaint;
  Paint wavePaint;
  Paint borderPaint;

  Animation<double> animation;

  final TextPainter textPainter;
  final TextStyle textStyle;

  WavePainter(
      {this.animation,
      this.waveColor,
      this.waveBGColor,
      this.waveShiftRatio,
      this.bgg})
      : wavePaint = new Paint(),
        waveBGPaint = new Paint(),
        borderPaint = new Paint(),
        shdMatrix = new Matrix4.identity(),
        shdMatrixArray = new Float64List(16),
        textPainter = new TextPainter(
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        textStyle = const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontFamily: 'Times New Roman',
          fontSize: 25.0,
        ),
        super(repaint: animation) {
    wavePaint.isAntiAlias = true;

    waveBGPaint.color = waveBGColor;
    waveBGPaint.style = PaintingStyle.fill;

    borderPaint.color = waveColor;
    borderPaint.isAntiAlias = true;
    borderPaint.style = PaintingStyle.stroke;
    borderPaint.strokeWidth = 1.5;

    waterLevelRatio = 1.0 - bgg;
  }

  @override
  void paint(Canvas canvas, Size size) {
    this.size = size;
    final radius = size.width / 2;


    shdMatrix.scale(1.0, 0.5);
    shdMatrix.translate(waveShiftRatio * size.width,
        (waterLevelRatio - mWaterLevelRatio) * size.height);

    shdMatrix.copyIntoArray(shdMatrixArray);
    //print(waveImgShader);
    if (waveImgShader == null) {
      updateWaveShader();
    }

    //new
    //print(waveShiftRatio);
    wavePaint.shader = waveImgShader;


    canvas.save();
    canvas.translate(radius, radius);
    canvas.drawCircle(Offset.zero, radius, waveBGPaint);
    canvas.drawCircle(Offset.zero, radius, wavePaint);
    canvas.drawCircle(Offset.zero, radius, borderPaint);

    textPainter.text = new TextSpan(
      text: '${(bgg*100).floor()}%',
      style: textStyle,
    );

    textPainter.layout();

    textPainter.paint(canvas,
        new Offset(-(textPainter.width / 2), -(textPainter.height / 2)));

    canvas.restore();
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }

  void updateWaveShader() {
    double width = size.width;
    double height = size.height;

    if (width > 0 && height > 0) {
      // ω=2π/T, where T= period
      var angularFrequency = 2 * PI / (wavelengthRatio * width);
      var amplitude = amplitudeRatio * height;
      var waterLevel = waterLevelRatio * height;

      Paint shaderWavePaint = new Paint()
        ..strokeWidth = 2.0
        ..isAntiAlias = true;

      //print(shaderWavePaint.strokeWidth);

      PictureRecorder recorder = new PictureRecorder();
      Canvas canvas = new Canvas(recorder, Offset.zero & size);

      //draw wave
      final double endX = width + 1;
      final double endY = height + 1;

      Float64List waveY = new Float64List(endX.floor());
      shaderWavePaint.color = waveColor.withOpacity(0.3);
      //shaderWavePaint.color = waveColor;

      for (int beginX = 0; beginX < endX; beginX++) {
        double beginXPoint = beginX.toDouble();
        double wx = beginX * angularFrequency;

        // y=Asin(ωx+φ)+h
        double beginY = (amplitude * sin(wx)) + waterLevel;

        canvas.drawLine(new Offset(beginXPoint, beginY),
            new Offset(beginXPoint, endY), shaderWavePaint);
        waveY[beginX] = beginY;
      }

      shaderWavePaint.color = waveColor;
      //shift the wave by a quarter of the width
      final int wave2Shift = width ~/ 6;
      for (int beginX = 0; beginX < endX; beginX++) {
        double beginXPoint = beginX.toDouble();
        canvas.drawLine(
            new Offset(
                beginXPoint, waveY[(beginX + wave2Shift) % endX.floor()]),
            new Offset(beginXPoint, endY),
            shaderWavePaint);
      }

      Picture picture = recorder.endRecording();

      image = picture.toImage(width.floor(), height.floor());
      /*print('size is $size');
      print('image is $image');
      print(-1.0 * waterLevelRatio * size.height);*/

      //draw shader with image;
      waveImgShader = new ImageShader(
          image, TileMode.repeated, TileMode.clamp, shdMatrixArray);

      image.dispose();
    } else {
      //print('nothing');
    }
  }
}
