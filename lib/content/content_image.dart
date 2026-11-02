import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_content.dart';
import 'profile_photo_cache.dart';

/// Only the two team portraits can use remote content. All artwork stays bundled.
class AppContentImage extends StatelessWidget {
  final String asset;
  final double? width, height;
  final BoxFit fit;
  final Color? color;
  final ColorFilter? colorFilter;
  final AlignmentGeometry alignment;
  final String? semanticsLabel;
  const AppContentImage(this.asset,
      {super.key,
      this.width,
      this.height,
      this.fit = BoxFit.contain,
      this.color,
      this.colorFilter,
      this.alignment = Alignment.center,
      this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    Widget fallback() => asset.endsWith('.svg')
        ? SvgPicture.asset(asset,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            colorFilter: colorFilter ??
                (color == null
                    ? null
                    : ColorFilter.mode(color!, BlendMode.srcIn)),
            semanticsLabel: semanticsLabel)
        : Image.asset(asset,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            color: color,
            semanticLabel: semanticsLabel);
    if (!ProfilePhotoCache.assets.contains(asset)) return fallback();
    AppContent.watch(context);
    final url = AppContent.instance.imageFor(asset)?['url'];
    if (url == null) return fallback();
    return _CachedPortrait(
        asset: asset,
        url: url,
        fallback: fallback,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        semanticsLabel: semanticsLabel);
  }
}

class _CachedPortrait extends StatefulWidget {
  final String asset, url;
  final Widget Function() fallback;
  final double? width, height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final String? semanticsLabel;
  const _CachedPortrait(
      {required this.asset,
      required this.url,
      required this.fallback,
      this.width,
      this.height,
      required this.fit,
      required this.alignment,
      this.semanticsLabel});
  @override
  State<_CachedPortrait> createState() => _CachedPortraitState();
}

class _CachedPortraitState extends State<_CachedPortrait> {
  late Stream<Uint8List> _photos;
  void _load() =>
      _photos = ProfilePhotoCache.instance.watch(widget.asset, widget.url);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _CachedPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.asset != widget.asset) _load();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Uint8List>(
      stream: _photos,
      initialData: ProfilePhotoCache.instance.peek(widget.asset),
      builder: (context, snapshot) => snapshot.hasData
          ? Image.memory(snapshot.data!,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              alignment: widget.alignment,
              cacheWidth: 512,
              gaplessPlayback: true,
              semanticLabel: widget.semanticsLabel,
              errorBuilder: (_, __, ___) => widget.fallback())
          : widget.fallback());
}
