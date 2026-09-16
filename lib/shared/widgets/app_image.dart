import 'dart:io';
import 'package:flutter/material.dart';

/// A smart image widget that displays either a local file or a network image.
class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const AppImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }

    Widget image;
    if (url!.startsWith('/') || url!.startsWith('file:')) {
      image = Image.file(
        File(url!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorWidget(),
      );
    } else {
      image = Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorWidget(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    return image;
  }

  Widget _errorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
