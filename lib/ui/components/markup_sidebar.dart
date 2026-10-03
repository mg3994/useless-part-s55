import 'package:flutter/material.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/bloc/editor_state.dart';

class MarkupSidebar extends StatelessWidget {
  const MarkupSidebar({
    super.key,
    required this.cubit,
    required this.state,
    this.onOpenCatalog,
  });

  final EditorCubit cubit;
  final EditorState state;
  final VoidCallback? onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = state.documents;

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.hub_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JSON-LD Studio',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Schema.org Visual Editor',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 18,
                  ),
                  tooltip: 'Toggle Theme',
                  onPressed: () => cubit.toggleTheme(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Actions Row (New Markup + Import)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Markup', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  tooltip: 'Import JSON-LD',
                  onPressed: () => _showImportDialog(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filter markups...',
                prefixIcon: const Icon(Icons.search, size: 16),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () => cubit.setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: (val) => cubit.setSearchQuery(val),
            ),
          ),
          const SizedBox(height: 8),

          // Markups List
          Expanded(
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                if (state.searchQuery.isNotEmpty &&
                    !doc.name.toLowerCase().contains(state.searchQuery.toLowerCase()) &&
                    !doc.type.toLowerCase().contains(state.searchQuery.toLowerCase())) {
                  return const SizedBox.shrink();
                }

                final isSelected = index == state.selectedDocumentIndex;
                final typeShort = doc.type.replaceAll('schema:', '');

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getIconForType(typeShort),
                        size: 14,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                    title: Text(
                      doc.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          typeShort,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          ' • ${doc.properties.length} props',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 16),
                      onSelected: (action) {
                        if (action == 'duplicate') {
                          cubit.duplicateDocument(index);
                        } else if (action == 'rename') {
                          _showRenameDialog(context, index, doc.name);
                        } else if (action == 'delete') {
                          cubit.deleteDocument(index);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => cubit.selectDocument(index),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Schema.org Status Badge & Catalog Link
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.scaffoldBackgroundColor.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isFullSchemaLoaded ? Colors.green : Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.isFullSchemaLoaded
                            ? 'Schema.org vLatest Synced'
                            : (state.isSchemaLoading ? 'Syncing Schema.org...' : 'Offline Core'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: state.isSchemaLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync, size: 16),
                      tooltip: 'Refresh Schema.org from network',
                      onPressed: state.isSchemaLoading
                          ? null
                          : () => cubit.refreshSchemaFromNetwork(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '${state.schemaClassesCount} classes • ${state.schemaPropertiesCount} properties',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 6),
                if (onOpenCatalog != null)
                  InkWell(
                    onTap: onOpenCatalog,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_outlined, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Browse Schema.org Ontology',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Person':
        return Icons.person_outline;
      case 'Organization':
      case 'LocalBusiness':
      case 'Store':
        return Icons.business_outlined;
      case 'Product':
        return Icons.shopping_bag_outlined;
      case 'Offer':
        return Icons.local_offer_outlined;
      case 'Event':
        return Icons.event_outlined;
      case 'Place':
      case 'PostalAddress':
        return Icons.place_outlined;
      case 'Article':
        return Icons.article_outlined;
      case 'WebSite':
        return Icons.language_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'schema:Person';
    final popularTypes = [
      'schema:Person',
      'schema:Organization',
      'schema:LocalBusiness',
      'schema:Store',
      'schema:Product',
      'schema:Offer',
      'schema:Event',
      'schema:Article',
      'schema:WebSite',
      'schema:Place',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create New Markup Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Document Name',
                  hintText: 'e.g. Acme Corp WebSite',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Root Schema.org Type:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                items: popularTypes.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.replaceAll('schema:', '')),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => selectedType = newVal);
                  }
                },
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
                cubit.createNewDocument(nameController.text, selectedType);
                Navigator.of(ctx).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Document Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              cubit.renameDocument(index, controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import JSON-LD'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste any Schema.org JSON-LD code below to visually edit its nodes and properties:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '{\n  "@context": "https://schema.org",\n  "@type": "Product",\n  "name": "Widget"\n}',
                  hintStyle: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ok = cubit.importJsonLd(controller.text);
              Navigator.of(ctx).pop();
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid JSON-LD format. Please check syntax.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
