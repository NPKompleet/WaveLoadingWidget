import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:waveloadingwidget/wave_painter.dart';

class WaveLoadingWidget extends StatefulWidget {
  final fluidHeight;
  WaveLoadingWidget({this.fluidHeight=0.5});


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
    _fluidHeight= widget.fluidHeight;
    timer = new Timer(const Duration(milliseconds: 9500), stopAnimation);

    waveAnimController = new AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    heightAnimController = new AnimationController(
      upperBound: _fluidHeight,
      vsync: this,
      duration: const Duration(seconds: 1),
    );



    heightAnimController.forward();
    waveAnimController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return new AnimatedBuilder(
      animation: waveAnimController,
      builder: _buildAnim,
    );
  }

  Widget _buildAnim(BuildContext context, Widget child) {
    return new GestureDetector(
      onTap: onTap,
      child: new Container(
      width: double.INFINITY,
      //color: Colors.amber,
      child: new CustomPaint(
        painter: new WavePainter(
            animation: waveAnimController,
            waveColor: Colors.red,
            waveBGColor: Colors.green,
            waveShiftRatio: waveAnimController.value,
            bgg: heightAnimController.value),
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

  void setFluidHeight(double newFluidHeight){
    if (_fluidHeight > newFluidHeight){
      setupControllerBounds(newFluidHeight, _fluidHeight);
      heightAnimController.reverse(from: _fluidHeight);
    }else{
      setupControllerBounds(_fluidHeight, newFluidHeight);
      heightAnimController.forward(from: _fluidHeight);
    }
    _fluidHeight= newFluidHeight;

    timer = new Timer(const Duration(milliseconds: 9500), stopAnimation);
    waveAnimController.repeat();
  }

  void setupControllerBounds(lower, upper){
    heightAnimController = new AnimationController(
      lowerBound: lower,
      upperBound: upper,
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  void onTap(){
    _fluidHeight>=0.5? setFluidHeight(0.4): setFluidHeight(0.7);
  }



}
