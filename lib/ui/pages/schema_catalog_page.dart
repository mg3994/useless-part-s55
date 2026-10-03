import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/models/schema_class.dart';
import 'package:stores/routing/routes.dart';
import 'package:stores/services/schema_service.dart';

class SchemaCatalogPage extends StatefulWidget {
  const SchemaCatalogPage({super.key, required this.cubit});

  final EditorCubit cubit;

  @override
  State<SchemaCatalogPage> createState() => _SchemaCatalogPageState();
}

class _SchemaCatalogPageState extends State<SchemaCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Thing',
    'Person',
    'Organization',
    'Place',
    'Product',
    'Event',
    'Action',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schemaService = SchemaService.instance;
    final allClasses = schemaService.classes.values.toList();
    final query = _searchController.text.trim().toLowerCase();

    final filtered = allClasses.where((cls) {
      final matchesQuery = query.isEmpty ||
          cls.label.toLowerCase().contains(query) ||
          cls.comment.toLowerCase().contains(query);

      final matchesCat = _selectedCategory == 'All' ||
          cls.label == _selectedCategory ||
          schemaService.isSubclassOf(cls.id, 'schema:$_selectedCategory');

      return matchesQuery && matchesCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.router<AppRoute>().push(const EditorRoute());
            }
          },
        ),
        title: const Text('Schema.org Ontology Explorer'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                '${allClasses.length} Classes • ${schemaService.properties.length} Properties',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Schema.org definitions (e.g. LocalBusiness, MedicalCondition, Recipe)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No matching Schema.org classes found.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cls = filtered[index];
                      final subClassesStr = cls.subClassOf
                          .map((s) => s.replaceAll('schema:', ''))
                          .join(', ');

                      return Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                cls.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (subClassesStr.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'extends $subClassesStr',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              cls.comment.isEmpty ? 'Schema.org class definition' : cls.comment,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          trailing: FilledButton.tonal(
                            onPressed: () {
                              widget.cubit.createNewDocument(
                                '${cls.label} Markup',
                                cls.id,
                              );
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                context.router<AppRoute>().push(const EditorRoute());
                              }
                            },
                            child: const Text('Create Markup'),
                          ),
                          onTap: () => _showClassDetails(context, cls),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showClassDetails(BuildContext context, SchemaClass cls) {
    final props = SchemaService.instance.getPropertiesForClass(cls.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cls.label),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cls.comment,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                'Available Properties (${props.length}):',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: props.length,
                  itemBuilder: (ctx, i) {
                    final p = props[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        p.comment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Text(
                        p.ranges.map((r) => r.replaceAll('schema:', '')).join(', '),
                        style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.cubit.createNewDocument('${cls.label} Markup', cls.id);
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.router<AppRoute>().push(const EditorRoute());
              }
            },
            child: const Text('Create Markup'),
          ),
        ],
      ),
    );
  }
}
