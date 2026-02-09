import 'package:flutter/material.dart';

/// Utilidades para diseño responsive
class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Verifica si es móvil
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Verifica si es tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Verifica si es desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Obtiene el ancho de la pantalla
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Obtiene la altura de la pantalla
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Obtiene padding responsive
  static EdgeInsets padding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Obtiene padding horizontal responsive
  static EdgeInsets paddingHorizontal(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 12);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
  }

  /// Obtiene padding vertical responsive
  static EdgeInsets paddingVertical(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(vertical: 12);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(vertical: 16);
    } else {
      return const EdgeInsets.symmetric(vertical: 20);
    }
  }

  /// Obtiene tamaño de fuente responsive
  static double fontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize * 0.9;
    } else if (isTablet(context)) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  /// Obtiene número de columnas para GridView responsive
  static int gridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Obtiene número de columnas para GridView de menú responsive
  static int menuGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Obtiene ancho máximo para contenido centrado
  static double maxContentWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 800;
    } else {
      return 1200;
    }
  }

  /// Obtiene tamaño de ícono responsive
  static double iconSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize * 0.8;
    } else if (isTablet(context)) {
      return baseSize;
    } else {
      return baseSize * 1.2;
    }
  }

  /// Widget que se adapta según el tamaño de pantalla
  static Widget responsive({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    required BuildContext context,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

