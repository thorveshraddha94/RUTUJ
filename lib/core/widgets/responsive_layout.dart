import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  final Widget? tablet;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static Widget responsiveRow(BuildContext context, List<Widget> children) {
    final isMobile = ResponsiveLayout.isMobile(context);
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child))
            .toList(),
      );
    }
    return Row(
      children: children
          .map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: child)))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return desktop;
    if (width >= 768 && tablet != null) return tablet!;
    return mobile;
  }
}
