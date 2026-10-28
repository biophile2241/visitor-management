import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/visitor_model.dart';
import '../providers/visitor_provider.dart';
import '../services/visitor_api_service.dart';
import 'visitor_details_screen.dart';

class VisitorFormScreen extends StatefulWidget {
  const VisitorFormScreen({super.key, this.visitor});

  final VisitorModel? visitor;

  @override
  State<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends State<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _purposeController;
  late String _visitorType;
  late String _project;
  bool _isSaving = false;

  static const _visitorTypes = ['Customer', 'Vendor', 'Other'];
  static const _projects = ['Project A', 'Project B', 'Project C'];

  @override
  void initState() {
    super.initState();
    final visitor = widget.visitor;
    _nameController = TextEditingController(text: visitor?.name ?? '');
    _mobileController = TextEditingController(text: visitor?.mobile ?? '');
    _emailController = TextEditingController(text: visitor?.email ?? '');
    _purposeController = TextEditingController(text: visitor?.purpose ?? '');
    _visitorType = visitor?.visitorType ?? _visitorTypes.first;
    _project = visitor?.project ?? _projects.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.visitor != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Visitor' : 'Register Visitor'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                isEditing
                    ? 'Update visitor information'
                    : 'Enter visitor information',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Colors.blueGrey.shade600),
              ),
              const SizedBox(height: 22),
              _field(
                controller: _nameController,
                label: 'Full name *',
                icon: Icons.person_outline,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _mobileController,
                label: 'Mobile number *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Enter exactly 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                controller: _emailController,
                label: 'Email (optional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                      ? null
                      : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _visitorType,
                decoration: const InputDecoration(
                  labelText: 'Visitor type',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: _visitorTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _visitorType = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _project,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: _projects
                    .map(
                      (project) => DropdownMenuItem(
                        value: project,
                        child: Text(project),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _project = value);
                },
              ),
              const SizedBox(height: 16),
              _field(
                controller: _purposeController,
                label: 'Purpose of visit *',
                icon: Icons.notes_outlined,
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Purpose is required'
                    : null,
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isEditing ? Icons.save_outlined : Icons.person_add),
                label: Text(isEditing ? 'Save Changes' : 'Register Visitor'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final oldVisitor = widget.visitor;
    final now = DateTime.now().toIso8601String();
    final visitor = VisitorModel(
      id: oldVisitor?.id ?? '',
      name: _nameController.text.trim(),
      mobile: _mobileController.text,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      visitorType: _visitorType,
      project: _project,
      purpose: _purposeController.text.trim(),
      status: oldVisitor?.status ?? 'Registered',
      createdAt: oldVisitor?.createdAt ?? now,
      checkInTime: oldVisitor?.checkInTime,
      checkOutTime: oldVisitor?.checkOutTime,
    );
    try {
      final provider = context.read<VisitorProvider>();
      final saved = oldVisitor == null
          ? await provider.createVisitor(visitor)
          : await provider.updateVisitor(visitor);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            oldVisitor == null ? 'Visitor registered.' : 'Visitor updated.',
          ),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VisitorDetailsScreen(visitor: saved),
        ),
      );
    } on VisitorApiException catch (error) {
      _showError(error.message);
    } on Exception catch (error) {
      _showError('Could not save visitor: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
