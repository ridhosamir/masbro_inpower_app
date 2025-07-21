import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageHelper {
  static Future<void> clearImageCache() async {
    await DefaultCacheManager().emptyCache();
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  static String addCacheBuster(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return url.contains('?') ? '$url&cb=$timestamp' : '$url?cb=$timestamp';
  }
}

class EnhancedNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Duration cacheDuration;
  final bool forceFresh;

  const EnhancedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.cacheDuration = const Duration(days: 1),
    this.forceFresh = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorContainer(
        width: width,
        height: height,
        errorWidget: errorWidget?.call(context, '', 'No image URL provided'),
      );
    }

    String effectiveUrl = imageUrl!;
    if (forceFresh) {
      effectiveUrl = ImageHelper.addCacheBuster(effectiveUrl);
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: effectiveUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholderContainer(
        width: width,
        height: height,
        placeholder: placeholder?.call(context, url),
      ),
      errorWidget: (context, url, error) => _buildErrorContainer(
        width: width,
        height: height,
        errorWidget: errorWidget?.call(context, url, error),
        error: error.toString(),
      ),
      cacheManager: CacheManager(
        Config(
          'enhanced_image_cache',
          stalePeriod: cacheDuration,
          maxNrOfCacheObjects: 100,
        ),
      ),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: imageWidget,
    );
  }

  Widget _buildPlaceholderContainer({
    double? width,
    double? height,
    Widget? placeholder,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: placeholder ?? Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorContainer({
    double? width,
    double? height,
    Widget? errorWidget,
    String? error,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: errorWidget ?? _buildDefaultErrorWidget(error),
    );
  }

  Widget _buildDefaultErrorWidget(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              error ?? 'Gagal memuat gambar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
