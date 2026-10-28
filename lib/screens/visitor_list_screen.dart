import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/visitor_model.dart';
import '../providers/visitor_provider.dart';
import '../services/visitor_api_service.dart';
import '../widgets/api_error_banner.dart';
import '../widgets/async_state_view.dart';
import '../widgets/visitor_card.dart';
import 'visitor_details_screen.dart';
import 'visitor_form_screen.dart';

class VisitorListScreen extends StatefulWidget {
  const VisitorListScreen({super.key});

  @override
  State<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VisitorProvider>(
      builder: (context, provider, _) {
        final visitors = provider.search(_searchController.text);
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visitors',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search name or mobile number',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.error != null && provider.visitors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: ApiErrorBanner(
                    message: provider.error!,
                    onRetry: provider.loadVisitors,
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.loadVisitors,
                  child: _body(provider, visitors),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(VisitorProvider provider, List<VisitorModel> visitors) {
    if (provider.isLoading && provider.visitors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.visitors.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: AsyncStateView(
              title: 'Could not load visitors',
              message: provider.error!,
              icon: Icons.cloud_off_outlined,
              action: FilledButton.icon(
                onPressed: provider.loadVisitors,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ),
          ),
        ],
      );
    }
    if (visitors.isEmpty) {
      final searching = _searchController.text.isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: AsyncStateView(
              title: searching ? 'No matching visitors' : 'No visitors yet',
              message: searching
                  ? 'Try another name or mobile number.'
                  : 'Registered visitors will appear here.',
              icon: searching ? Icons.search_off : Icons.people_outline,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: visitors.length,
      itemBuilder: (context, index) {
        final visitor = visitors[index];
        return VisitorCard(
          visitor: visitor,
          onTap: () => _openDetails(visitor),
          onEdit: () => _editVisitor(visitor),
          onDelete: () => _confirmDelete(visitor),
        );
      },
    );
  }

  void _openDetails(VisitorModel visitor) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisitorDetailsScreen(visitor: visitor),
      ),
    );
  }

  void _editVisitor(VisitorModel visitor) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisitorFormScreen(visitor: visitor),
      ),
    );
  }

  Future<void> _confirmDelete(VisitorModel visitor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete visitor?'),
        content: Text('This will permanently delete ${visitor.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<VisitorProvider>().deleteVisitor(visitor.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Visitor deleted.')));
      }
    } on VisitorApiException catch (error) {
      if (mounted) _showError(error.message);
    } on Exception catch (error) {
      if (mounted) _showError('Could not delete visitor: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
