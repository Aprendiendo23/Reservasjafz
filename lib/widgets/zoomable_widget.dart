import 'package:flutter/material.dart';

class ZoomableWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final double initialScale;

  const ZoomableWidget({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.initialScale = 1.0,
  });

  @override
  State<ZoomableWidget> createState() => _ZoomableWidgetState();
}

class _ZoomableWidgetState extends State<ZoomableWidget> {
  late TransformationController _transformationController;
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _scale = widget.initialScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          // Restablecer zoom al hacer doble toque
          onDoubleTap: () {
            _resetZoom();
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            panEnabled: true, // Habilitar desplazamiento con el dedo
            scaleEnabled: true, // Habilitar zoom con pellizco
            boundaryMargin: EdgeInsets.zero, // Sin márgenes para permitir desplazamiento completo
            constrained: false, // Permitir desplazamiento libre cuando hay zoom
            clipBehavior: Clip.none, // No recortar para permitir ver todo el contenido
            onInteractionUpdate: (details) {
              // Actualizar la escala actual si es necesario
              setState(() {
                _scale = _transformationController.value.getMaxScaleOnAxis();
              });
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}

