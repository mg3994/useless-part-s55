import 'package:flutter/material.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/bloc/editor_state.dart';
import 'package:stores/models/schema_entity.dart';
import 'package:stores/services/schema_service.dart';
import 'package:stores/ui/components/add_property_dialog.dart';

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.cubit,
    required this.state,
    required this.document,
  });

  final EditorCubit cubit;
  final EditorState state;
  final SchemaEntity document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortType = document.type.replaceAll('schema:', '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Document Name & Type Badge
              Expanded(
                child: Row(
                  children: [
                    Text(
                      document.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(width: 12),
                    // Root Type Selector Chip
                    InkWell(
                      onTap: () => _showChangeTypeDialog(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '@type: $shortType',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Base URI chip
                    InkWell(
                      onTap: () => _showBaseUriDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              document.baseUri ?? '@base: default',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Save Status Indicator
              Row(
                children: [
                  Icon(
                    state.saveStatus == 'Saved'
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                    size: 16,
                    color: state.saveStatus == 'Saved' ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.saveStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: state.saveStatus == 'Saved' ? Colors.green : Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // View Mode Switcher
              Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    _buildViewButton(
                      context,
                      icon: Icons.view_column_outlined,
                      label: 'Columns',
                      isSelected: state.viewMode == WorkspaceViewMode.columns,
                      onTap: () => cubit.setWorkspaceView(WorkspaceViewMode.columns),
                    ),
                    _buildViewButton(
                      context,
                      icon: Icons.account_tree_outlined,
                      label: 'Tree',
                      isSelected: state.viewMode == WorkspaceViewMode.tree,
                      onTap: () => cubit.setWorkspaceView(WorkspaceViewMode.tree),
                    ),
                    _buildViewButton(
                      context,
                      icon: Icons.dashboard_outlined,
                      label: 'Cards',
                      isSelected: state.viewMode == WorkspaceViewMode.cards,
                      onTap: () => cubit.setWorkspaceView(WorkspaceViewMode.cards),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Add Property Action Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AddPropertyDialog(
                      entity: document,
                      onPropertySelected: (prop, initialVal) {
                        cubit.addPropertyToEntity(document, prop.id, initialVal);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Property', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeTypeDialog(BuildContext context) {
    final classes = SchemaService.instance.classes.values.toList();
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? classes
              : classes.where((c) {
                  return c.label.toLowerCase().contains(query) ||
                      c.id.toLowerCase().contains(query);
                }).toList();

          return AlertDialog(
            title: const Text('Change Root Schema Type'),
            content: SizedBox(
              width: 420,
              height: 480,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search Schema.org type (e.g. LocalBusiness, Recipe)...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (_) => setLocalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        final isCurrent = c.id == document.type;
                        return ListTile(
                          dense: true,
                          title: Text(
                            c.label,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            c.comment,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: isCurrent
                              ? const Icon(Icons.check, size: 16, color: Colors.green)
                              : null,
                          onTap: () {
                            cubit.updateRootType(c.id);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBaseUriDialog(BuildContext context) {
    final controller = TextEditingController(text: document.baseUri ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Base URI (@base)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the @base IRI for resolving relative IDs (e.g. https://example.com/):',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://example.com/things/',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              cubit.setBaseUri(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
