import 'package:flutter/material.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/models/schema_entity.dart';
import 'package:stores/models/schema_value.dart';
import 'package:stores/services/schema_service.dart';

class PropertyRow extends StatelessWidget {
  const PropertyRow({
    super.key,
    required this.cubit,
    required this.entity,
    required this.propertyId,
    required this.values,
    this.onSelectNestedEntity,
  });

  final EditorCubit cubit;
  final SchemaEntity entity;
  final String propertyId;
  final List<SchemaValue> values;
  final void Function(SchemaEntity nested)? onSelectNestedEntity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propMeta = SchemaService.instance.properties[propertyId];
    final propLabel = propMeta?.label ?? propertyId.split(':').last;
    final propComment = propMeta?.comment ?? '';
    final ranges = propMeta?.ranges ?? [];
    final enumOptions = SchemaService.instance.getEnumOptions(ranges);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          propLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        if (ranges.isNotEmpty)
                          Text(
                            ranges.map((r) => r.replaceAll('schema:', '')).join(' | '),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    if (propComment.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          propComment,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                tooltip: 'Add another value for $propLabel',
                onPressed: () {
                  cubit.addPropertyToEntity(entity, propertyId, '');
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Remove property',
                onPressed: () {
                  cubit.removePropertyFromEntity(entity, propertyId);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...values.map(
            (sv) => _buildValueField(context, sv, ranges, enumOptions),
          ),
        ],
      ),
    );
  }

  Widget _buildValueField(
    BuildContext context,
    SchemaValue sv,
    List<String> ranges,
    List<String> enumOptions,
  ) {
    final theme = Theme.of(context);
    final val = sv.value;

    if (val is SchemaEntity) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.device_hub, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    val.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    '${val.type} (${val.properties.length} props)',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (onSelectNestedEntity != null)
              TextButton.icon(
                onPressed: () => onSelectNestedEntity!(val),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Node'),
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => cubit.removePropertyValue(entity, propertyId, sv.id),
            ),
          ],
        ),
      );
    }

    if (enumOptions.isNotEmpty) {
      final currentEnum = val?.toString() ?? enumOptions.first;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: enumOptions.contains(currentEnum) ? currentEnum : enumOptions.first,
                items: enumOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt,
                    child: Text(opt.replaceAll('schema:', '')),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    cubit.updatePropertyValue(entity, propertyId, sv.id, newVal);
                  }
                },
                decoration: const InputDecoration(isDense: true),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => cubit.removePropertyValue(entity, propertyId, sv.id),
            ),
          ],
        ),
      );
    }

    if (ranges.contains('schema:Boolean')) {
      final bool boolVal = (val is bool) ? val : false;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Switch(
              value: boolVal,
              onChanged: (newBool) {
                cubit.updatePropertyValue(entity, propertyId, sv.id, newBool);
              },
            ),
            Text(boolVal ? ' True' : ' False'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => cubit.removePropertyValue(entity, propertyId, sv.id),
            ),
          ],
        ),
      );
    }

    // Default primitive input (Text, Number, URL, Date)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: val?.toString() ?? '',
              onChanged: (newText) {
                cubit.updatePropertyValue(entity, propertyId, sv.id, newText);
              },
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Enter value...',
                suffixIcon: _buildTypeHelperMenu(context, sv),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => cubit.removePropertyValue(entity, propertyId, sv.id),
          ),
        ],
      ),
    );
  }

  Widget? _buildTypeHelperMenu(BuildContext context, SchemaValue sv) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 16),
      tooltip: 'Change value type',
      onSelected: (action) {
        if (action == 'convert_to_nested') {
          final propMeta = SchemaService.instance.properties[propertyId];
          final targetType = propMeta?.ranges.firstWhere(
                (r) => SchemaService.instance.classes.containsKey(r),
                orElse: () => 'schema:Thing',
              ) ??
              'schema:Thing';

          final nested = SchemaEntity(
            id: 'nest_${DateTime.now().microsecondsSinceEpoch}',
            name: '${targetType.split(':').last} Object',
            type: targetType,
            properties: {},
          );
          cubit.updatePropertyValue(entity, propertyId, sv.id, nested);
        } else if (action == 'link_document') {
          _showLinkDocumentDialog(context, sv);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'convert_to_nested',
          child: Row(
            children: [
              Icon(Icons.account_tree, size: 16),
              SizedBox(width: 8),
              Text('Convert to Nested Object'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'link_document',
          child: Row(
            children: [
              Icon(Icons.link, size: 16),
              SizedBox(width: 8),
              Text('Link to Another Markup (@id)'),
            ],
          ),
        ),
      ],
    );
  }

  void _showLinkDocumentDialog(BuildContext context, SchemaValue sv) {
    final docs = cubit.stateValue.documents.where((d) => d.id != entity.id).toList();
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other documents available to link')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link to Document (@id)'),
        content: SizedBox(
          width: 350,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final d = docs[i];
              return ListTile(
                title: Text(d.name),
                subtitle: Text(d.type),
                onTap: () {
                  cubit.updatePropertyValue(
                    entity,
                    propertyId,
                    sv.id,
                    {'@id': d.id, 'docName': d.name},
                  );
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
