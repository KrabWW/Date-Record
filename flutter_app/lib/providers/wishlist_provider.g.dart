// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$wishlistListHash() => r'5429eb90bdfebdf1859cf10a0420cd46f6bb7ee9';

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

abstract class _$WishlistList
    extends BuildlessAutoDisposeAsyncNotifier<List<Wishlist>> {
  late final String? status;

  FutureOr<List<Wishlist>> build({String? status});
}

/// 愿望清单列表 Provider
///
/// Copied from [WishlistList].
@ProviderFor(WishlistList)
const wishlistListProvider = WishlistListFamily();

/// 愿望清单列表 Provider
///
/// Copied from [WishlistList].
class WishlistListFamily extends Family<AsyncValue<List<Wishlist>>> {
  /// 愿望清单列表 Provider
  ///
  /// Copied from [WishlistList].
  const WishlistListFamily();

  /// 愿望清单列表 Provider
  ///
  /// Copied from [WishlistList].
  WishlistListProvider call({String? status}) {
    return WishlistListProvider(status: status);
  }

  @override
  WishlistListProvider getProviderOverride(
    covariant WishlistListProvider provider,
  ) {
    return call(status: provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'wishlistListProvider';
}

/// 愿望清单列表 Provider
///
/// Copied from [WishlistList].
class WishlistListProvider
    extends AutoDisposeAsyncNotifierProviderImpl<WishlistList, List<Wishlist>> {
  /// 愿望清单列表 Provider
  ///
  /// Copied from [WishlistList].
  WishlistListProvider({String? status})
    : this._internal(
        () => WishlistList()..status = status,
        from: wishlistListProvider,
        name: r'wishlistListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$wishlistListHash,
        dependencies: WishlistListFamily._dependencies,
        allTransitiveDependencies:
            WishlistListFamily._allTransitiveDependencies,
        status: status,
      );

  WishlistListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final String? status;

  @override
  FutureOr<List<Wishlist>> runNotifierBuild(covariant WishlistList notifier) {
    return notifier.build(status: status);
  }

  @override
  Override overrideWith(WishlistList Function() create) {
    return ProviderOverride(
      origin: this,
      override: WishlistListProvider._internal(
        () => create()..status = status,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<WishlistList, List<Wishlist>>
  createElement() {
    return _WishlistListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WishlistListProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WishlistListRef on AutoDisposeAsyncNotifierProviderRef<List<Wishlist>> {
  /// The parameter `status` of this provider.
  String? get status;
}

class _WishlistListProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<WishlistList, List<Wishlist>>
    with WishlistListRef {
  _WishlistListProviderElement(super.provider);

  @override
  String? get status => (origin as WishlistListProvider).status;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
