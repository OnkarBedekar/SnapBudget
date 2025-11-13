import '../utils/logger.dart';

/// Simple in-memory cache service for frequently accessed data
class CacheService {
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache storage
  final Map<String, CacheEntry> _cache = {};
  
  // Cache configuration
  static const Duration defaultTtl = Duration(minutes: 5);
  static const int maxCacheSize = 100;

  /// Get cached value
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      AppLogger.d('Cache miss: $key');
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      AppLogger.d('Cache expired: $key');
      _cache.remove(key);
      return null;
    }

    AppLogger.d('Cache hit: $key');
    return entry.value as T;
  }

  /// Set cached value
  void set<T>(String key, T value, {Duration? ttl}) {
    // Evict oldest entries if cache is full
    if (_cache.length >= maxCacheSize) {
      _evictOldest();
    }

    _cache[key] = CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
    AppLogger.d('Cache set: $key');
  }

  /// Remove cached value
  void remove(String key) {
    _cache.remove(key);
    AppLogger.d('Cache removed: $key');
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    AppLogger.i('Cache cleared');
  }

  /// Clear cache for a specific pattern (e.g., all monthly budgets)
  void clearPattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    AppLogger.d('Cache cleared for pattern: $pattern (${keysToRemove.length} entries)');
  }

  /// Evict oldest entries
  void _evictOldest() {
    if (_cache.isEmpty) return;

    // Sort by expiration time and remove oldest
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
    
    // Remove 10% of oldest entries
    final toRemove = (sortedEntries.length * 0.1).ceil();
    for (int i = 0; i < toRemove && i < sortedEntries.length; i++) {
      _cache.remove(sortedEntries[i].key);
    }
    AppLogger.d('Evicted $toRemove oldest cache entries');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    int expired = 0;
    int active = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expired++;
      } else {
        active++;
      }
    }

    return {
      'total': _cache.length,
      'active': active,
      'expired': expired,
      'maxSize': maxCacheSize,
    };
  }
}

/// Cache entry with expiration
class CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

