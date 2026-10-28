import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/visitor_model.dart';
import 'api_config.dart';

class VisitorApiException implements Exception {
  const VisitorApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VisitorApiService {
  VisitorApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String baseUrl;

  Uri _visitorUri([String? id]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse(
      '$normalizedBase/visitors${id == null ? '' : '/${Uri.encodeComponent(id)}'}',
    );
  }

  Future<List<VisitorModel>> getVisitors() async {
    final response = await _send(() => _client.get(_visitorUri()));
    final decoded = _decode(response);
    if (decoded is! List) {
      throw const VisitorApiException(
        'The server returned an invalid visitor list.',
      );
    }
    return decoded.map((item) {
      if (item is! Map) {
        throw const VisitorApiException(
          'The server returned an invalid visitor record.',
        );
      }
      return VisitorModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<VisitorModel> getVisitorById(String id) async {
    final response = await _send(() => _client.get(_visitorUri(id)));
    return _visitorFromResponse(response);
  }

  Future<VisitorModel> createVisitor(VisitorModel visitor) async {
    final response = await _send(
      () => _client.post(
        _visitorUri(),
        headers: _headers,
        body: jsonEncode(visitor.toJson(includeId: false)),
      ),
    );
    return _visitorFromResponse(response);
  }

  Future<VisitorModel> updateVisitor(VisitorModel visitor) async {
    final response = await _send(
      () => _client.put(
        _visitorUri(visitor.id),
        headers: _headers,
        body: jsonEncode(visitor.toJson()),
      ),
    );
    return _visitorFromResponse(response);
  }

  Future<void> deleteVisitor(String id) async {
    await _send(() => _client.delete(_visitorUri(id)));
  }

  Future<VisitorModel> updateVisitorStatus(
    String id,
    String status,
    String timestamp,
  ) async {
    final timestampField = switch (status) {
      'Checked In' => 'check_in_time',
      'Checked Out' => 'check_out_time',
      _ => throw ArgumentError.value(status, 'status', 'Unsupported status'),
    };
    final response = await _send(
      () => _client.patch(
        _visitorUri(id),
        headers: _headers,
        body: jsonEncode({'status': status, timestampField: timestamp}),
      ),
    );
    return _visitorFromResponse(response);
  }

  static const _headers = {'Content-Type': 'application/json'};

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    if (baseUrl.contains('YOUR_MOCKAPI_ID')) {
      throw const VisitorApiException(
        'Configure VISITOR_API_BASE_URL with your MockAPI project URL to connect.',
      );
    }
    try {
      final response = await request().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VisitorApiException('Request failed (${response.statusCode}).');
      }
      return response;
    } on VisitorApiException {
      rethrow;
    } on Exception catch (error) {
      throw VisitorApiException('Unable to reach the visitor service: $error');
    }
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const VisitorApiException('The server returned malformed JSON.');
    }
  }

  VisitorModel _visitorFromResponse(http.Response response) {
    final decoded = _decode(response);
    if (decoded is! Map) {
      throw const VisitorApiException(
        'The server returned an invalid visitor.',
      );
    }
    return VisitorModel.fromJson(Map<String, dynamic>.from(decoded));
  }
}
