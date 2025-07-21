import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration cacheDuration;
  final BorderRadius? borderRadius;
  final bool forceFresh;

  const FirebaseStorageImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheDuration = const Duration(days: 1),
    this.borderRadius,
    this.forceFresh = false,
  }) : super(key: key);

  @override
  State<FirebaseStorageImage> createState() => _FirebaseStorageImageState();
}

class _FirebaseStorageImageState extends State<FirebaseStorageImage> {
  String? _effectiveUrl;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  final _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _processImageUrl();
  }

  @override
  void didUpdateWidget(FirebaseStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl || widget.forceFresh) {
      _processImageUrl();
    }
  }

  Future<void> _processImageUrl() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      _setErrorState('URL gambar tidak tersedia');
      return;
    }

    try {
      String url = widget.imageUrl!;

      // Jika URL dimulai dengan gs://
      if (url.startsWith('gs://')) {
        final ref = FirebaseStorage.instance.refFromURL(url);
        url = await ref.getDownloadURL();
      }
      // Jika URL hanya path storage tanpa gs://
      else if (!url.startsWith('http')) {
        final ref = FirebaseStorage.instance.ref(url);
        url = await ref.getDownloadURL();
      }

      // Tambahkan cache buster jika forceFresh
      if (widget.forceFresh) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        url = url.contains('?')
            ? '$url&cacheBuster=$timestamp'
            : '$url?cacheBuster=$timestamp';

        // Hapus cache untuk URL ini
        await _cacheManager.removeFile(url);
      }

      if (mounted) {
        setState(() {
          _effectiveUrl = url;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      print('[FIREBASE_STORAGE_IMAGE] Error: $e');
      _setErrorState('Gagal memuat gambar: ${e.toString()}');
    }
  }

  void _setErrorState(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = message;
      });
    }
  }

  void _retryLoading() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Hapus cache untuk URL asli
      if (widget.imageUrl != null) {
        await _cacheManager.removeFile(widget.imageUrl!);
      }

      // Hapus cache untuk URL yang sudah diproses
      if (_effectiveUrl != null) {
        await _cacheManager.removeFile(_effectiveUrl!);
      }

      _processImageUrl();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: widget.placeholder ?? Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _effectiveUrl == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: widget.errorWidget ?? _buildDefaultErrorWidget(),
      );
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: _effectiveUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: widget.placeholder ?? Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: widget.errorWidget ??
            _buildDefaultErrorWidget(error: error.toString()),
      ),
      cacheManager: CacheManager(
        Config(
          'firebase_storage_cache',
          stalePeriod: widget.cacheDuration,
          maxNrOfCacheObjects: 100,
        ),
      ),
    );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultErrorWidget({String? error}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              error ?? _errorMessage ?? 'Gagal memuat gambar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _retryLoading,
            icon: Icon(Icons.refresh, size: 16),
            label: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(100, 36),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
