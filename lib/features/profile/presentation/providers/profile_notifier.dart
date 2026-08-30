import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/profile_entity.dart';
import 'profile_providers.dart';

class ProfileNotifier extends AsyncNotifier<ProfileEntity> {
  @override
  FutureOr<ProfileEntity> build() {
    return ref.read(getCurrentUserProfileUseCaseProvider).call();
  }

  Future<void> updateProfile({
    required String fullName,
    String? cpfCnpj,
    LatLng? location,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(updateCurrentUserProfileUseCaseProvider).call(
        fullName: fullName,
        cpfCnpj: cpfCnpj,
        location: location,
      );
    });
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileEntity>(ProfileNotifier.new);
