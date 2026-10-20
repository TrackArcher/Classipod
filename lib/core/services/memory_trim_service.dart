import 'package:flutter/painting.dart';

/// Drops in-memory artwork/bitmaps; disk caches are kept.
void trimHeavyCaches() {
  final cache = PaintingBinding.instance.imageCache;
  cache.clear();
  cache.clearLiveImages();
}
