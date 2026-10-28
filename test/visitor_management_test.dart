import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:visitor_management/models/visitor_model.dart';
import 'package:visitor_management/providers/visitor_provider.dart';
import 'package:visitor_management/services/api_config.dart';
import 'package:visitor_management/services/visitor_api_service.dart';

void main() {
  const id = 'visitor-1';

  test('MockAPI project ID builds the default API base URL', () {
    expect(ApiConfig.projectId, '6ae0aa4dbe3bc8fead97b0c5');
    expect(
      ApiConfig.baseUrl,
      'https://${ApiConfig.projectId}.mockapi.io/api/v1',
    );
  });

  Map<String, dynamic> visitorJson({
    String visitorId = id,
    String name = 'Taylor Example',
    String mobile = '1234567890',
    String status = 'Registered',
    String? checkInTime,
    String? checkOutTime,
  }) => {
    'id': visitorId,
    'name': name,
    'mobile': mobile,
    'email': 'taylor@example.com',
    'visitor_type': 'Customer',
    'project': 'Project A',
    'purpose': 'Meeting',
    'status': status,
    'created_at': DateTime.now().toIso8601String(),
    'check_in_time': checkInTime,
    'check_out_time': checkOutTime,
  };

  test('visitor model maps API fields and allows clearing optional values', () {
    final visitor = VisitorModel.fromJson(visitorJson());
    final copy = visitor.copyWith(email: null);

    expect(visitor.visitorType, 'Customer');
    expect(visitor.createdAt, isNotEmpty);
    expect(visitor.toJson()['visitor_type'], 'Customer');
    expect(copy.email, isNull);
    expect(copy.id, id);
  });

  test(
    'provider calculates local-day metrics and searches name/mobile',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode([
            visitorJson(),
            visitorJson(
              visitorId: 'visitor-2',
              name: 'Jordan Example',
              mobile: '0987654321',
              status: 'Checked In',
            ),
            visitorJson(
              visitorId: 'visitor-3',
              name: 'Morgan Example',
              mobile: '9876543210',
              status: 'Checked Out',
              checkOutTime: DateTime.now().toIso8601String(),
            ),
          ]),
          200,
        );
      });
      final provider = VisitorProvider(
        VisitorApiService(
          client: client,
          baseUrl: 'https://example.test/api/v1',
        ),
      );

      await provider.loadVisitors();

      expect(provider.totalToday, 3);
      expect(provider.currentlyCheckedIn, 1);
      expect(provider.checkedOutToday, 1);
      expect(provider.search('taylor'), hasLength(1));
      expect(provider.search('1234567890'), hasLength(1));
      expect(provider.search('unknown'), isEmpty);
    },
  );

  test(
    'API service uses the required visitor endpoints and HTTP methods',
    () async {
      final service = VisitorApiService(
        baseUrl: 'https://example.test/api/v1',
        client: MockClient((request) async {
          expect(request.url.path, startsWith('/api/v1/visitors'));
          if (request.method == 'GET' && request.url.path.endsWith('/$id')) {
            return http.Response(jsonEncode(visitorJson()), 200);
          }
          if (request.method == 'GET') {
            return http.Response(jsonEncode([visitorJson()]), 200);
          }
          if (request.method == 'POST') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body.containsKey('id'), isFalse);
            return http.Response(
              jsonEncode({...body, 'id': 'created-id'}),
              201,
            );
          }
          if (request.method == 'PUT') {
            return http.Response(request.body, 200);
          }
          if (request.method == 'DELETE') {
            return http.Response('', 204);
          }
          fail('Unexpected HTTP method ${request.method}');
        }),
      );
      final visitor = VisitorModel.fromJson(visitorJson());

      expect(await service.getVisitors(), hasLength(1));
      expect((await service.getVisitorById(id)).id, id);
      expect((await service.createVisitor(visitor)).id, 'created-id');
      expect((await service.updateVisitor(visitor)).id, id);
      await service.deleteVisitor(id);
    },
  );

  test(
    'status update uses PATCH and rejects invalid state transitions',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([visitorJson()]), 200);
        }
        expect(request.method, 'PATCH');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], 'Checked In');
        expect(body['check_in_time'], isNotNull);
        return http.Response(
          jsonEncode(
            visitorJson(
              status: 'Checked In',
              checkInTime: body['check_in_time'] as String,
            ),
          ),
          200,
        );
      });
      final provider = VisitorProvider(
        VisitorApiService(
          client: client,
          baseUrl: 'https://example.test/api/v1',
        ),
      );
      await provider.loadVisitors();
      final checkedIn = await provider.updateVisitorStatus(
        id,
        'Checked In',
        DateTime.now().toIso8601String(),
      );
      expect(checkedIn.status, 'Checked In');
      expect(provider.currentlyCheckedIn, 1);
      await expectLater(
        provider.updateVisitorStatus(
          id,
          'Checked In',
          DateTime.now().toIso8601String(),
        ),
        throwsA(isA<VisitorApiException>()),
      );
    },
  );
}
