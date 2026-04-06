// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'couple_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hasCoupleHash() => r'f6fec9ae1b4889f87e9df01496f81a773ce9b2e5';

/// 是否有情侣空间 Provider
///
/// Copied from [hasCouple].
@ProviderFor(hasCouple)
final hasCoupleProvider = AutoDisposeProvider<bool>.internal(
  hasCouple,
  name: r'hasCoupleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasCoupleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasCoupleRef = AutoDisposeProviderRef<bool>;
String _$partnerHash() => r'03fee404c53f569106c4c84f8ffa0da4ef64e062';

/// 获取伴侣信息 Provider
///
/// Copied from [partner].
@ProviderFor(partner)
final partnerProvider =
    AutoDisposeProvider<({String? name, String? email})>.internal(
      partner,
      name: r'partnerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$partnerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PartnerRef = AutoDisposeProviderRef<({String? name, String? email})>;
String _$partnerIdHash() => r'5c16f3beeaf09aaa753574d3b103fcf09fc1f649';

/// 获取伴侣 ID Provider
///
/// Copied from [partnerId].
@ProviderFor(partnerId)
final partnerIdProvider = AutoDisposeProvider<int?>.internal(
  partnerId,
  name: r'partnerIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$partnerIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PartnerIdRef = AutoDisposeProviderRef<int?>;
String _$currentCoupleHash() => r'3aef96078330e02a60e00abff3410184290ea170';

/// 当前情侣空间 Provider
///
/// Copied from [CurrentCouple].
@ProviderFor(CurrentCouple)
final currentCoupleProvider =
    AutoDisposeAsyncNotifierProvider<CurrentCouple, Couple?>.internal(
      CurrentCouple.new,
      name: r'currentCoupleProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentCoupleHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentCouple = AutoDisposeAsyncNotifier<Couple?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
