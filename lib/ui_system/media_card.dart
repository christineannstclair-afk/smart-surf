import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'app_theme.dart';
import 'spacing.dart';

enum MediaCardState { empty, image, video }

class MediaCard extends StatelessWidget {
  final MediaCardState state;
  final VoidCallback? onAddMedia;
  final VoidCallback? onTap;
  final Widget? imageWidget;
  final String? footerLabel;
  final String? mediaPath;
  final String? mediaType;
  final bool isEditable;
  final bool isSpanish;
  
  const MediaCard({
    super.key,
    this.state = MediaCardState.empty,
    this.onAddMedia,
    this.onTap,
    this.imageWidget,
    this.footerLabel,
    this.mediaPath,
    this.mediaType,
    this.isEditable = true,
    this.isSpanish = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: AppTheme.surfaceVariant,
          child: InkWell(
            onTap: isEditable ? (state == MediaCardState.empty ? onAddMedia : onTap) : onTap,
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (state == MediaCardState.empty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/surf_placeholder_latest_session.png',
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(color: AppTheme.surfaceVariant),
          ),
          /* Removed duplicate overlay layer */
          if (isEditable)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_a_photo_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      isSpanish ? "Sube una foto o clip corto (<10s)" : "Upload photo or short clip (<10s)",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageWidget != null)
          imageWidget!
        else if (mediaPath != null)
          _buildMediaContent(context)
        else
          Center(child: Icon(state == MediaCardState.video ? Icons.videocam : Icons.image, color: AppTheme.textMuted, size: 48)),
          
        if (state == MediaCardState.video)
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ),
          ),
        
        if (footerLabel != null)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                footerLabel!,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaContent(BuildContext context) {
     if (mediaPath == null) return _buildErrorPlaceholder();
 
     if (mediaType == 'video') {
       return _VideoThumbnailPlayer(path: mediaPath!);
     }
 
     final bool isNetwork = mediaPath!.startsWith('http');
     if (isNetwork) {
       return Image.network(
         mediaPath!,
         fit: BoxFit.cover,
         errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder(),
       );
     } else {
       return Image.file(
         File(mediaPath!),
         fit: BoxFit.cover,
         errorBuilder: (ctx, err, stack) => _buildErrorPlaceholder(),
       );
     }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppTheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 48),
      ),
    );
  }
}

class _VideoThumbnailPlayer extends StatefulWidget {
  final String path;
  const _VideoThumbnailPlayer({required this.path});

  @override
  State<_VideoThumbnailPlayer> createState() => _VideoThumbnailPlayerState();
}

class _VideoThumbnailPlayerState extends State<_VideoThumbnailPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = kIsWeb || widget.path.startsWith('http') || widget.path.startsWith('data:')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));
    
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _initialized = true);
        // Pause by default for preview thumbnail
      }
    }).catchError((err) {
      debugPrint("Thumbnail video error: $err");
      if (mounted) setState(() => _error = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: AppTheme.surfaceVariant,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 48),
        ),
      );
    }
    if (!_initialized) {
      return Container(
        color: AppTheme.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
