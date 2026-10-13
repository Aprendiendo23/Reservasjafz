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
            panEnabled: true, // Desplazamiento con el dedo (scroll horizontal y vertical)
            scaleEnabled: true, // Zoom con pellizco
            boundaryMargin: EdgeInsets.zero, // Sin márgenes extra para evitar sensación de flotante
            constrained: false, // Contenido puede ser más grande que el viewport para permitir scroll tras el zoom
            clipBehavior: Clip.hardEdge, // Recortar contenido que se salga del viewport
            child: widget.child,
          ),
        );
      },
    );
  }
}

