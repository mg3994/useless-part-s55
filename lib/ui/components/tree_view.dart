import 'package:flutter/material.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/models/schema_entity.dart';
import 'package:stores/ui/components/add_property_dialog.dart';
import 'package:stores/ui/components/property_row.dart';

class SchemaTreeView extends StatelessWidget {
  const SchemaTreeView({
    super.key,
    required this.cubit,
    required this.rootEntity,
  });

  final EditorCubit cubit;
  final SchemaEntity rootEntity;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: _buildEntityNode(context, rootEntity, 0),
        ),
      ),
    );
  }

  Widget _buildEntityNode(BuildContext context, SchemaEntity entity, int depth) {
    final theme = Theme.of(context);
    final entries = entity.properties.entries.toList();

    return Container(
      margin: EdgeInsets.only(left: depth * 20.0, bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: depth == 0
              ? theme.colorScheme.primary.withOpacity(0.4)
              : (theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          depth == 0 ? Icons.folder_open : Icons.subdirectory_arrow_right,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          entity.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${entity.type} (${entries.length} properties)',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          tooltip: 'Add property',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AddPropertyDialog(
                entity: entity,
                onPropertySelected: (prop, initialVal) {
                  cubit.addPropertyToEntity(entity, prop.id, initialVal);
                },
              ),
            );
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: entries.map((entry) {
                return PropertyRow(
                  cubit: cubit,
                  entity: entity,
                  propertyId: entry.key,
                  values: entry.value,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
