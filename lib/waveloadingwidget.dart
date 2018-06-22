import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:waveloadingwidget/wave_painter.dart';

class WaveLoadingWidget extends StatefulWidget {
  final fluidHeight;
  final Color backgroundColor;
  final Color waveColor;

  WaveLoadingWidget(
      {this.fluidHeight = 0.5, this.backgroundColor, this.waveColor});

  @override
  _WaveLoadingWidgetState createState() => new _WaveLoadingWidgetState();
}

class _WaveLoadingWidgetState extends State<WaveLoadingWidget>
    with TickerProviderStateMixin {
  AnimationController waveAnimController;
  AnimationController heightAnimController;
  Timer timer;

  double _fluidHeight;

  @override
  void initState() {
    super.initState();
    _fluidHeight = widget.fluidHeight;
    timer = Timer(const Duration(milliseconds: 9500), stopAnimation);

    waveAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    heightAnimController = AnimationController(
      upperBound: _fluidHeight,
      vsync: this,
      duration: Duration(seconds: 1),
    );

    heightAnimController.forward();
    waveAnimController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveAnimController,
      builder: _buildAnim,
    );
  }

  Widget _buildAnim(BuildContext context, Widget child) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        child: CustomPaint(
          painter: WavePainter(
              animation: waveAnimController,
              waveColor: widget.waveColor,
              waveBGColor: widget.backgroundColor,
              waveShiftRatio: waveAnimController.value,
              fluidHeight: heightAnimController.value),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    waveAnimController.dispose();
    heightAnimController.dispose();
  }

  void stopAnimation() {
    waveAnimController.stop();
  }

  void setFluidHeight(double newFluidHeight) {
    if (_fluidHeight > newFluidHeight) {
      setupControllerBounds(newFluidHeight, _fluidHeight);
      heightAnimController.reverse(from: _fluidHeight);
    } else {
      setupControllerBounds(_fluidHeight, newFluidHeight);
      heightAnimController.forward(from: _fluidHeight);
    }
    _fluidHeight = newFluidHeight;

    timer = Timer(Duration(milliseconds: 9500), stopAnimation);
    waveAnimController.repeat();
  }

  void setupControllerBounds(lower, upper) {
    heightAnimController = AnimationController(
      lowerBound: lower,
      upperBound: upper,
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  void onTap() {
    _fluidHeight >= 0.5 ? setFluidHeight(0.4) : setFluidHeight(0.7);
  }
}
