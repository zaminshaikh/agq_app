import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'app_content.dart';

/// Resolves both raster and SVG defaults; every failed replacement falls back.
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
    AppContent.watch(context);
    final replacement = AppContent.instance.imageFor(asset);
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
    if (replacement == null) return fallback();
    Widget image;
    if (replacement['contentType'] == 'image/svg+xml') {
      image = _RemoteSvg(
          url: replacement['url']!,
          fallback: fallback,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          semanticsLabel: semanticsLabel);
    } else {
      image = Image.network(replacement['url']!,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          semanticLabel: semanticsLabel,
          errorBuilder: (_, __, ___) => fallback(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : fallback());
    }
    final filter = colorFilter ??
        (color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn));
    return filter == null
        ? image
        : ColorFiltered(colorFilter: filter, child: image);
  }
}

/// DecorationImage/portrait support, including network and decode fallback.
class ContentImageProvider extends ImageProvider<ContentImageProvider> {
  final String asset;
  final String? url;
  const ContentImageProvider({required this.asset, this.url});
  @override
  Future<ContentImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
          ContentImageProvider key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);
  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    if (url != null) {
      try {
        final response =
            await http.get(Uri.parse(url!)).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 &&
            response.bodyBytes.length <= 5 * 1024 * 1024) {
          return await decode(
              await ui.ImmutableBuffer.fromUint8List(response.bodyBytes));
        }
      } catch (_) {
        /* Keep the bundled portrait if loading or decoding fails. */
      }
    }
    return decode(await ui.ImmutableBuffer.fromAsset(asset));
  }

  @override
  bool operator ==(Object other) =>
      other is ContentImageProvider && other.asset == asset && other.url == url;
  @override
  int get hashCode => Object.hash(asset, url);
}

class _RemoteSvg extends StatefulWidget {
  final String url;
  final Widget Function() fallback;
  final double? width, height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final String? semanticsLabel;
  const _RemoteSvg(
      {required this.url,
      required this.fallback,
      this.width,
      this.height,
      required this.fit,
      required this.alignment,
      this.semanticsLabel});
  @override
  State<_RemoteSvg> createState() => _RemoteSvgState();
}

class _RemoteSvgState extends State<_RemoteSvg> {
  late Future<Uint8List> _bytes;
  Future<Uint8List> _load() async {
    final result = await http
        .get(Uri.parse(widget.url))
        .timeout(const Duration(seconds: 8));
    if (result.statusCode != 200 || result.bodyBytes.length > 5 * 1024 * 1024) {
      throw StateError('Image unavailable');
    }
    return result.bodyBytes;
  }

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(covariant _RemoteSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) _bytes = _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (context, snapshot) => snapshot.hasData
            ? SvgPicture.memory(snapshot.data!,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                alignment: widget.alignment,
                semanticsLabel: widget.semanticsLabel)
            : widget.fallback(),
      );
}
