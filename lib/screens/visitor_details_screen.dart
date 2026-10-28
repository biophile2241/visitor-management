import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/visitor_model.dart';
import '../providers/visitor_provider.dart';
import '../services/visitor_api_service.dart';
import '../widgets/status_chip.dart';
import 'visitor_form_screen.dart';

class VisitorDetailsScreen extends StatelessWidget {
  const VisitorDetailsScreen({super.key, required this.visitor});

  final VisitorModel visitor;

  @override
  Widget build(BuildContext context) {
    return Consumer<VisitorProvider>(
      builder: (context, provider, _) {
        final current =
            provider.visitors
                .where((item) => item.id == visitor.id)
                .firstOrNull ??
            visitor;
        final completed = current.status == 'Checked Out';
        final actionLabel = switch (current.status) {
          'Registered' => 'Check In',
          'Checked In' => 'Check Out',
          _ => 'Visit Completed',
        };
        return Scaffold(
          appBar: AppBar(
            title: const Text('Visitor Details'),
            actions: [
              IconButton(
                tooltip: 'Edit visitor',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VisitorFormScreen(visitor: current),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                current.name,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            StatusChip(status: current.status),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _DetailLine(
                          icon: Icons.phone_outlined,
                          label: 'Mobile',
                          value: current.mobile,
                        ),
                        if (current.email?.isNotEmpty == true)
                          _DetailLine(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: current.email!,
                          ),
                        _DetailLine(
                          icon: Icons.badge_outlined,
                          label: 'Visitor type',
                          value: current.visitorType,
                        ),
                        _DetailLine(
                          icon: Icons.apartment_outlined,
                          label: 'Project',
                          value: current.project,
                        ),
                        _DetailLine(
                          icon: Icons.notes_outlined,
                          label: 'Purpose',
                          value: current.purpose,
                        ),
                        _DetailLine(
                          icon: Icons.fingerprint,
                          label: 'Visitor ID',
                          value: current.id,
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit timeline',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 15),
                        _TimeLine(
                          label: 'Registered',
                          value: current.createdAt,
                        ),
                        _TimeLine(
                          label: 'Checked in',
                          value: current.checkInTime,
                        ),
                        _TimeLine(
                          label: 'Checked out',
                          value: current.checkOutTime,
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Visitor pass',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (current.id.isEmpty)
                          const Text('A visitor ID is required for a QR pass.')
                        else
                          QrImageView(
                            data: current.id,
                            size: 190,
                            backgroundColor: Colors.white,
                          ),
                        const SizedBox(height: 5),
                        Text(
                          'Scan this code to retrieve visitor details',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blueGrey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: completed
                      ? null
                      : () => _updateStatus(context, current),
                  icon: Icon(
                    current.status == 'Registered'
                        ? Icons.login
                        : current.status == 'Checked In'
                        ? Icons.logout
                        : Icons.check_circle_outline,
                  ),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(BuildContext context, VisitorModel visitor) async {
    final nextStatus = visitor.status == 'Registered'
        ? 'Checked In'
        : visitor.status == 'Checked In'
        ? 'Checked Out'
        : null;
    if (nextStatus == null) return;
    try {
      await context.read<VisitorProvider>().updateVisitorStatus(
        visitor.id,
        nextStatus,
        DateTime.now().toIso8601String(),
      );
    } on VisitorApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Exception catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update visitor status: $error')),
        );
      }
    }
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.blueGrey.shade500),
          const SizedBox(width: 11),
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final date = value == null ? null : DateTime.tryParse(value!)?.toLocal();
    final formatted = date == null
        ? '—'
        : DateFormat('dd MMM yyyy, hh:mm a').format(date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            formatted,
            style: TextStyle(
              color: date == null
                  ? Colors.blueGrey.shade400
                  : Colors.blueGrey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
