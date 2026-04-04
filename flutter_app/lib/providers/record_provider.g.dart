// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recordStatsHash() => r'242c04f12828c2ff6fa9c0174ef73c5137c084a9';

/// 记录统计 Provider
///
/// Copied from [recordStats].
@ProviderFor(recordStats)
final recordStatsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
      recordStats,
      name: r'recordStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recordStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecordStatsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$recordListHash() => r'e8417c0430691fa72df5fdea2db55306a0337539';

/// 记录列表 Provider
///
/// Copied from [RecordList].
@ProviderFor(RecordList)
final recordListProvider =
    AutoDisposeAsyncNotifierProvider<RecordList, List<DatingRecord>>.internal(
      RecordList.new,
      name: r'recordListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recordListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecordList = AutoDisposeAsyncNotifier<List<DatingRecord>>;
String _$currentRecordHash() => r'788bfff4ee639e9e8fadbcaab7a0e2f9b8918668';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$CurrentRecord
    extends BuildlessAutoDisposeAsyncNotifier<DatingRecord?> {
  late final int? recordId;

  FutureOr<DatingRecord?> build(int? recordId);
}

/// 当前记录 Provider (用于编辑)
///
/// Copied from [CurrentRecord].
@ProviderFor(CurrentRecord)
const currentRecordProvider = CurrentRecordFamily();

/// 当前记录 Provider (用于编辑)
///
/// Copied from [CurrentRecord].
class CurrentRecordFamily extends Family<AsyncValue<DatingRecord?>> {
  /// 当前记录 Provider (用于编辑)
  ///
  /// Copied from [CurrentRecord].
  const CurrentRecordFamily();

  /// 当前记录 Provider (用于编辑)
  ///
  /// Copied from [CurrentRecord].
  CurrentRecordProvider call(int? recordId) {
    return CurrentRecordProvider(recordId);
  }

  @override
  CurrentRecordProvider getProviderOverride(
    covariant CurrentRecordProvider provider,
  ) {
    return call(provider.recordId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'currentRecordProvider';
}

/// 当前记录 Provider (用于编辑)
///
/// Copied from [CurrentRecord].
class CurrentRecordProvider
    extends AutoDisposeAsyncNotifierProviderImpl<CurrentRecord, DatingRecord?> {
  /// 当前记录 Provider (用于编辑)
  ///
  /// Copied from [CurrentRecord].
  CurrentRecordProvider(int? recordId)
    : this._internal(
        () => CurrentRecord()..recordId = recordId,
        from: currentRecordProvider,
        name: r'currentRecordProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$currentRecordHash,
        dependencies: CurrentRecordFamily._dependencies,
        allTransitiveDependencies:
            CurrentRecordFamily._allTransitiveDependencies,
        recordId: recordId,
      );

  CurrentRecordProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordId,
  }) : super.internal();

  final int? recordId;

  @override
  FutureOr<DatingRecord?> runNotifierBuild(covariant CurrentRecord notifier) {
    return notifier.build(recordId);
  }

  @override
  Override overrideWith(CurrentRecord Function() create) {
    return ProviderOverride(
      origin: this,
      override: CurrentRecordProvider._internal(
        () => create()..recordId = recordId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordId: recordId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CurrentRecord, DatingRecord?>
  createElement() {
    return _CurrentRecordProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentRecordProvider && other.recordId == recordId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentRecordRef on AutoDisposeAsyncNotifierProviderRef<DatingRecord?> {
  /// The parameter `recordId` of this provider.
  int? get recordId;
}

class _CurrentRecordProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<CurrentRecord, DatingRecord?>
    with CurrentRecordRef {
  _CurrentRecordProviderElement(super.provider);

  @override
  int? get recordId => (origin as CurrentRecordProvider).recordId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
