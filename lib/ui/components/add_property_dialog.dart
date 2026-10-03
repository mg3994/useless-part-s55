import 'package:flutter/material.dart';
import 'package:stores/models/schema_entity.dart';
import 'package:stores/models/schema_property.dart';
import 'package:stores/services/schema_service.dart';

class AddPropertyDialog extends StatefulWidget {
  const AddPropertyDialog({
    super.key,
    required this.entity,
    required this.onPropertySelected,
  });

  final SchemaEntity entity;
  final void Function(SchemaProperty property, dynamic initialValue) onPropertySelected;

  @override
  State<AddPropertyDialog> createState() => _AddPropertyDialogState();
}

class _AddPropertyDialogState extends State<AddPropertyDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<SchemaProperty> _allProperties = [];
  List<SchemaProperty> _filteredProperties = [];
  bool _customPropMode = false;
  final TextEditingController _customNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allProperties = SchemaService.instance.getPropertiesForClass(widget.entity.type);
    _filteredProperties = _allProperties;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProperties = _allProperties;
      } else {
        _filteredProperties = _allProperties.where((p) {
          return p.label.toLowerCase().contains(query) ||
              p.comment.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  dynamic _determineInitialValue(SchemaProperty prop) {
    if (prop.ranges.contains('schema:Boolean')) {
      return false;
    }
    if (prop.ranges.contains('schema:Number') ||
        prop.ranges.contains('schema:Integer') ||
        prop.ranges.contains('schema:Float')) {
      return 0;
    }

    final enums = SchemaService.instance.getEnumOptions(prop.ranges);
    if (enums.isNotEmpty) {
      return enums.first;
    }

    final schemaService = SchemaService.instance;
    for (var r in prop.ranges) {
      if (schemaService.classes.containsKey(r)) {
        return SchemaEntity(
          id: 'nest_${DateTime.now().microsecondsSinceEpoch}',
          name: '${r.split(':').last} Object',
          type: r,
          properties: {},
        );
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.cardTheme.color,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Schema Property',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'For ${widget.entity.type} (${_filteredProperties.length} available)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search properties (e.g. name, address, price, author)...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredProperties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'No matching Schema.org properties found',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _customPropMode = true;
                                  _customNameController.text = _searchController.text;
                                });
                              },
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: const Text('Add as Custom Property'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredProperties.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final prop = _filteredProperties[index];
                          final isAlreadyAdded = widget.entity.properties.containsKey(prop.id);
                          final rangeLabel = prop.ranges.map((r) => r.replaceAll('schema:', '')).join(', ');

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            title: Row(
                              children: [
                                Text(
                                  prop.label,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                if (rangeLabel.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      rangeLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                if (isAlreadyAdded) ...[
                                  const Spacer(),
                                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                ],
                              ],
                            ),
                            subtitle: prop.comment.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      prop.comment,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              final initialVal = _determineInitialValue(prop);
                              widget.onPropertySelected(prop, initialVal);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
              if (_customPropMode) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customNameController,
                          decoration: const InputDecoration(
                            hintText: 'customPropertyKey',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          final key = _customNameController.text.trim();
                          if (key.isNotEmpty) {
                            final customProp = SchemaProperty(
                              id: key.contains(':') ? key : 'schema:$key',
                              label: key,
                              comment: 'Custom property',
                              domains: [widget.entity.type],
                              ranges: ['schema:Text'],
                            );
                            widget.onPropertySelected(customProp, '');
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
