import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/visitor_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/api_error_banner.dart';
import '../widgets/async_state_view.dart';
import 'visitor_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return Consumer<VisitorProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: provider.loadVisitors,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VISITOR MANAGEMENT',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.blue,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Good day',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppTheme.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE8EFFF),
                      foregroundColor: AppTheme.blue,
                      child: const Icon(Icons.apartment),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  "Today's overview",
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                if (provider.error != null && provider.visitors.isNotEmpty)
                  ApiErrorBanner(
                    message: provider.error!,
                    onRetry: provider.loadVisitors,
                  ),
                if (provider.isLoading && provider.visitors.isEmpty)
                  const LinearProgressIndicator()
                else if (provider.error != null && provider.visitors.isEmpty)
                  AsyncStateView(
                    title: 'Could not load visitors',
                    message: provider.error!,
                    icon: Icons.cloud_off_outlined,
                    action: FilledButton.icon(
                      onPressed: provider.loadVisitors,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  )
                else ...[
                  _MetricsGrid(
                    metrics: [
                      _MetricData(
                        label: 'Total Today',
                        value: provider.totalToday,
                        icon: Icons.groups_2_outlined,
                        color: AppTheme.blue,
                      ),
                      _MetricData(
                        label: 'Checked In',
                        value: provider.currentlyCheckedIn,
                        icon: Icons.login,
                        color: const Color(0xFF147D53),
                      ),
                      _MetricData(
                        label: 'Checked Out Today',
                        value: provider.checkedOutToday,
                        icon: Icons.logout,
                        color: const Color(0xFF8A5AD5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  _QuickAction(
                    title: 'Register Visitor',
                    subtitle: 'Create a new visitor pass',
                    icon: Icons.person_add_alt_1,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VisitorFormScreen(),
                      ),
                    ),
                  ),
                  _QuickAction(
                    title: 'Visitor List',
                    subtitle: 'Search and manage visitors',
                    icon: Icons.people_alt_outlined,
                    onTap: () => onNavigateToTab(1),
                  ),
                  _QuickAction(
                    title: 'Scan QR',
                    subtitle: 'Check a visitor pass',
                    icon: Icons.qr_code_scanner,
                    onTap: () => onNavigateToTab(2),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 24) / 3;
        return Row(
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              SizedBox(
                width: width,
                child: _MetricCard(metric: metrics[index]),
              ),
              if (index != metrics.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(metric.icon, color: metric.color, size: 22),
            const SizedBox(height: 11),
            Text(
              '${metric.value}',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              metric.label,
              maxLines: 2,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.blueGrey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8EFFF),
          foregroundColor: AppTheme.blue,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
