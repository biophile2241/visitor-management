import 'package:flutter/foundation.dart';

import '../models/visitor_model.dart';
import '../services/visitor_api_service.dart';

class VisitorProvider extends ChangeNotifier {
  VisitorProvider(this._api);

  final VisitorApiService _api;
  List<VisitorModel> _visitors = [];
  bool _isLoading = false;
  String? _error;

  List<VisitorModel> get visitors => List.unmodifiable(_visitors);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<VisitorModel> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return visitors;
    return _visitors
        .where(
          (visitor) =>
              visitor.name.toLowerCase().contains(normalized) ||
              visitor.mobile.contains(normalized),
        )
        .toList();
  }

  int get totalToday => _visitors.where((visitor) {
    final created = DateTime.tryParse(visitor.createdAt)?.toLocal();
    return created != null && _isToday(created);
  }).length;

  int get currentlyCheckedIn =>
      _visitors.where((visitor) => visitor.status == 'Checked In').length;

  int get checkedOutToday => _visitors.where((visitor) {
    if (visitor.status != 'Checked Out' || visitor.checkOutTime == null) {
      return false;
    }
    final checkedOut = DateTime.tryParse(visitor.checkOutTime!)?.toLocal();
    return checkedOut != null && _isToday(checkedOut);
  }).length;

  Future<void> loadVisitors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _visitors = await _api.getVisitors();
    } on VisitorApiException catch (error) {
      _error = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VisitorModel> getVisitorById(String id) async {
    final index = _visitors.indexWhere((visitor) => visitor.id == id);
    if (index >= 0) return _visitors[index];
    final visitor = await _api.getVisitorById(id);
    _upsert(visitor);
    return visitor;
  }

  Future<VisitorModel> createVisitor(VisitorModel visitor) async {
    final created = await _api.createVisitor(visitor);
    _upsert(created);
    return created;
  }

  Future<VisitorModel> updateVisitor(VisitorModel visitor) async {
    final updated = await _api.updateVisitor(visitor);
    _upsert(updated);
    return updated;
  }

  Future<void> deleteVisitor(String id) async {
    await _api.deleteVisitor(id);
    _visitors = _visitors.where((visitor) => visitor.id != id).toList();
    notifyListeners();
  }

  Future<VisitorModel> updateVisitorStatus(
    String id,
    String status,
    String timestamp,
  ) async {
    final current = _visitors.where((visitor) => visitor.id == id).firstOrNull;
    if (current == null) {
      throw const VisitorApiException('Visitor is no longer available.');
    }
    final allowedStatus = switch (current.status) {
      'Registered' => 'Checked In',
      'Checked In' => 'Checked Out',
      _ => null,
    };
    if (status != allowedStatus) {
      throw const VisitorApiException(
        'This visitor cannot make that status change.',
      );
    }
    final response = await _api.updateVisitorStatus(id, status, timestamp);
    final updated = response.copyWith(
      status: status,
      checkInTime: status == 'Checked In'
          ? timestamp
          : response.checkInTime ?? current.checkInTime,
      checkOutTime: status == 'Checked Out'
          ? timestamp
          : response.checkOutTime ?? current.checkOutTime,
    );
    _upsert(updated);
    return updated;
  }

  void _upsert(VisitorModel visitor) {
    final index = _visitors.indexWhere((item) => item.id == visitor.id);
    if (index == -1) {
      _visitors = [visitor, ..._visitors];
    } else {
      _visitors = [..._visitors]..[index] = visitor;
    }
    notifyListeners();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
