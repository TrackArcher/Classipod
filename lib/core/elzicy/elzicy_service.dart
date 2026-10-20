import 'dart:async';

import 'package:classipod/core/elzicy/elzicy_client.dart';
import 'package:classipod/features/settings/repository/elzicy_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final elzicyServiceProvider = Provider<ElzicyService>((ref) {
  final service = ElzicyService(ref.read(elzicySettingsRepositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});

class ElzicyService {
  ElzicyService(this._repository);

  final ElzicySettingsRepository _repository;
  ElzicyClient? _client;
  Future<ElzicyClient?>? _pendingClient;

  Future<ElzicyClient?> client() async {
    if (_client != null) return _client;
    _pendingClient ??= _createClient();
    return _pendingClient;
  }

  Future<ElzicyClient?> _createClient() async {
    final configured = await _repository.isConfigured();
    if (!configured) return null;
    final baseUrl = await _repository.baseUrl();
    final token = await _repository.token();
    if (baseUrl == null || token == null) return null;
    _client = ElzicyClient(
      httpClient: http.Client(),
      baseUrl: baseUrl,
      token: token,
    );
    return _client;
  }

  Future<void> reload() async {
    await dispose();
    _pendingClient = null;
  }

  Future<void> dispose() async {
    await _client?.dispose();
    _client = null;
  }
}
