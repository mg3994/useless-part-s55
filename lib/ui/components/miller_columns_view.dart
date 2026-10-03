import 'package:flutter/material.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/models/schema_entity.dart';
import 'package:stores/ui/components/add_property_dialog.dart';
import 'package:stores/ui/components/property_row.dart';

class MillerColumnsView extends StatefulWidget {
  const MillerColumnsView({
    super.key,
    required this.cubit,
    required this.rootEntity,
  });

  final EditorCubit cubit;
  final SchemaEntity rootEntity;

  @override
  State<MillerColumnsView> createState() => _MillerColumnsViewState();
}

class _MillerColumnsViewState extends State<MillerColumnsView> {
  final List<SchemaEntity> _selectedPath = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedPath.add(widget.rootEntity);
  }

  @override
  void didUpdateWidget(covariant MillerColumnsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootEntity.id != widget.rootEntity.id) {
      _selectedPath.clear();
      _selectedPath.add(widget.rootEntity);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectNested(SchemaEntity nested, int depth) {
    setState(() {
      while (_selectedPath.length > depth + 1) {
        _selectedPath.removeLast();
      }
      _selectedPath.add(nested);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_selectedPath.length, (depth) {
          final entity = _selectedPath[depth];
          return _buildColumnPane(context, entity, depth);
        }),
      ),
    );
  }

  Widget _buildColumnPane(BuildContext context, SchemaEntity entity, int depth) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;
    final entries = entity.properties.entries.toList();

    return Container(
      width: 360,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isRoot
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.scaffoldBackgroundColor.withOpacity(0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  isRoot ? Icons.account_circle_outlined : Icons.device_hub,
                  size: 18,
                  color: isRoot ? theme.colorScheme.primary : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entity.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        entity.type,
                        style: TextStyle(
                          fontSize: 11,
                          color: isRoot ? theme.colorScheme.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 18),
                  tooltip: 'Add property to ${entity.name}',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AddPropertyDialog(
                        entity: entity,
                        onPropertySelected: (prop, initialVal) {
                          widget.cubit.addPropertyToEntity(entity, prop.id, initialVal);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Properties Content
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.post_add, size: 36, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No properties added yet',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.tonal(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AddPropertyDialog(
                                  entity: entity,
                                  onPropertySelected: (prop, initialVal) {
                                    widget.cubit.addPropertyToEntity(entity, prop.id, initialVal);
                                  },
                                ),
                              );
                            },
                            child: const Text('Add Property', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return PropertyRow(
                        cubit: widget.cubit,
                        entity: entity,
                        propertyId: entry.key,
                        values: entry.value,
                        onSelectNestedEntity: (nested) => _onSelectNested(nested, depth),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
