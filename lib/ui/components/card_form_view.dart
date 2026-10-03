import 'package:flutter/material.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/models/schema_entity.dart';
import 'package:stores/ui/components/property_row.dart';

class CardFormView extends StatelessWidget {
  const CardFormView({
    super.key,
    required this.cubit,
    required this.rootEntity,
  });

  final EditorCubit cubit;
  final SchemaEntity rootEntity;

  @override
  Widget build(BuildContext context) {
    final entries = rootEntity.properties.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...entries.map((entry) {
                return PropertyRow(
                  cubit: cubit,
                  entity: rootEntity,
                  propertyId: entry.key,
                  values: entry.value,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
