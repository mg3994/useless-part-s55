import 'dart:async';
import 'dart:convert';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stores/bloc/editor_state.dart';
import 'package:stores/models/schema_entity.dart';
import 'package:stores/models/schema_value.dart';
import 'package:stores/services/schema_service.dart';

class EditorCubit extends CubitSignal<EditorState> {
  EditorCubit()
      : super(
          initialState: const EditorState(
            documents: [],
            isSchemaLoading: true,
          ),
        );

  Timer? _debounceTimer;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> init() async {
    emit(stateValue.copyWith(isSchemaLoading: true));

    // Initialize Schema.org Service
    await SchemaService.instance.init();

    // Load persisted documents from SharedPreferences
    List<SchemaEntity> loadedDocs = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final docsJson = prefs.getString('jsonld_visual_editor_docs');
      if (docsJson != null) {
        final List<dynamic> decodedList = json.decode(docsJson);
        for (var d in decodedList) {
          final map = d as Map<String, dynamic>;
          final rawProps = map['properties'] as Map<String, dynamic>? ?? {};
          final props = SchemaEntity.deserializeProperties(rawProps);
          loadedDocs.add(
            SchemaEntity(
              id: map['id']?.toString() ?? 'doc_${DateTime.now().millisecondsSinceEpoch}',
              name: map['name']?.toString() ?? 'Untitled Document',
              type: map['type']?.toString() ?? 'schema:Thing',
              properties: props,
              baseUri: map['baseUri']?.toString(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading documents from storage: $e');
    }

    // Default starter documents if empty
    if (loadedDocs.isEmpty) {
      final samplePerson = SchemaEntity(
        id: 'doc_person',
        name: 'Personal Profile',
        type: 'schema:Person',
        baseUri: 'https://example.com/persons/',
        properties: {
          'schema:name': [
            SchemaValue(id: 'val_name', value: 'Alex Morgan'),
          ],
          'schema:jobTitle': [
            SchemaValue(id: 'val_title', value: 'Lead AI Engineer'),
          ],
          'schema:url': [
            SchemaValue(id: 'val_url', value: 'https://alexmorgan.dev'),
          ],
          'schema:address': [
            SchemaValue(
              id: 'val_addr',
              value: SchemaEntity(
                id: 'addr_1',
                name: 'Headquarters Address',
                type: 'schema:PostalAddress',
                properties: {
                  'schema:streetAddress': [
                    SchemaValue(id: 'val_st', value: '100 Innovation Way'),
                  ],
                  'schema:addressLocality': [
                    SchemaValue(id: 'val_city', value: 'San Francisco'),
                  ],
                  'schema:addressRegion': [
                    SchemaValue(id: 'val_region', value: 'CA'),
                  ],
                  'schema:postalCode': [
                    SchemaValue(id: 'val_zip', value: '94107'),
                  ],
                  'schema:addressCountry': [
                    SchemaValue(id: 'val_country', value: 'USA'),
                  ],
                },
              ),
            ),
          ],
        },
      );

      final sampleStore = SchemaEntity(
        id: 'doc_store',
        name: 'Flagship Store',
        type: 'schema:Store',
        baseUri: 'https://store.example.com/',
        properties: {
          'schema:name': [
            SchemaValue(id: 'val_store_name', value: 'Apex Retail Labs'),
          ],
          'schema:description': [
            SchemaValue(
              id: 'val_store_desc',
              value: 'A high-performance modern retail experience.',
            ),
          ],
          'schema:priceRange': [
            SchemaValue(id: 'val_store_price', value: r'$$$'),
          ],
        },
      );

      loadedDocs = [samplePerson, sampleStore];
      _saveDocumentsToStorage(loadedDocs);
    }

    final schemaService = SchemaService.instance;
    final jsonLd = _compileJsonLd(loadedDocs, 0);

    emit(
      stateValue.copyWith(
        documents: loadedDocs,
        selectedDocumentIndex: 0,
        isSchemaLoading: schemaService.isLoadingFullSchema,
        isFullSchemaLoaded: schemaService.isFullSchemaLoaded,
        schemaClassesCount: schemaService.classes.length,
        schemaPropertiesCount: schemaService.properties.length,
        schemaEnumsCount: schemaService.enumerationValues.length,
        loadError: schemaService.loadError,
        jsonLdOutput: jsonLd,
        saveStatus: 'Saved',
      ),
    );
  }

  void toggleTheme() {
    emit(stateValue.copyWith(isDarkMode: !stateValue.isDarkMode));
  }

  void selectDocument(int index) {
    if (index >= 0 && index < stateValue.documents.length) {
      final jsonLd = _compileJsonLd(stateValue.documents, index);
      emit(
        stateValue.copyWith(
          selectedDocumentIndex: index,
          jsonLdOutput: jsonLd,
        ),
      );
    }
  }

  void createNewDocument(String name, String typeId) {
    final doc = SchemaEntity(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? '${typeId.split(':').last} Markup' : name.trim(),
      type: typeId,
      properties: {},
    );
    final newDocs = List<SchemaEntity>.from(stateValue.documents)..add(doc);
    final newIndex = newDocs.length - 1;
    final jsonLd = _compileJsonLd(newDocs, newIndex);

    emit(
      stateValue.copyWith(
        documents: newDocs,
        selectedDocumentIndex: newIndex,
        jsonLdOutput: jsonLd,
      ),
    );
    _persistState();
  }

  void duplicateDocument(int index) {
    if (index >= 0 && index < stateValue.documents.length) {
      final original = stateValue.documents[index];
      final cloned = original.clone();
      cloned.name = '${original.name} (Copy)';
      final newDocs = List<SchemaEntity>.from(stateValue.documents)..add(cloned);
      final newIndex = newDocs.length - 1;
      final jsonLd = _compileJsonLd(newDocs, newIndex);

      emit(
        stateValue.copyWith(
          documents: newDocs,
          selectedDocumentIndex: newIndex,
          jsonLdOutput: jsonLd,
        ),
      );
      _persistState();
    }
  }

  void renameDocument(int index, String newName) {
    if (index >= 0 && index < stateValue.documents.length) {
      final target = stateValue.documents[index];
      target.name = newName.trim();
      final jsonLd = _compileJsonLd(stateValue.documents, stateValue.selectedDocumentIndex);
      emit(
        stateValue.copyWith(
          documents: List.of(stateValue.documents),
          jsonLdOutput: jsonLd,
        ),
      );
      _persistState();
    }
  }

  void deleteDocument(int index) {
    if (index < 0 || index >= stateValue.documents.length) return;

    final newDocs = List<SchemaEntity>.from(stateValue.documents)..removeAt(index);
    if (newDocs.isEmpty) {
      final fallback = SchemaEntity(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        name: 'New Document',
        type: 'schema:Thing',
        properties: {},
      );
      newDocs.add(fallback);
    }

    final newIndex = (stateValue.selectedDocumentIndex >= newDocs.length)
        ? newDocs.length - 1
        : stateValue.selectedDocumentIndex;
    final jsonLd = _compileJsonLd(newDocs, newIndex);

    emit(
      stateValue.copyWith(
        documents: newDocs,
        selectedDocumentIndex: newIndex,
        jsonLdOutput: jsonLd,
      ),
    );
    _persistState();
  }

  void updateRootType(String newType) {
    final current = stateValue.currentDocument;
    if (current == null) return;

    current.type = newType;
    current.properties.clear();
    final jsonLd = _compileJsonLd(stateValue.documents, stateValue.selectedDocumentIndex);

    emit(
      stateValue.copyWith(
        documents: List.of(stateValue.documents),
        jsonLdOutput: jsonLd,
      ),
    );
    _persistState();
  }

  void setBaseUri(String baseUri) {
    final current = stateValue.currentDocument;
    if (current == null) return;

    current.baseUri = baseUri.trim().isEmpty ? null : baseUri.trim();
    final jsonLd = _compileJsonLd(stateValue.documents, stateValue.selectedDocumentIndex);

    emit(
      stateValue.copyWith(
        documents: List.of(stateValue.documents),
        jsonLdOutput: jsonLd,
      ),
    );
    _persistState();
  }

  void addPropertyToEntity(
    SchemaEntity entity,
    String propertyId,
    dynamic initialValue,
  ) {
    if (entity.properties[propertyId] == null) {
      entity.properties[propertyId] = [];
    }
    final dynamic val = (initialValue is SchemaEntity)
        ? initialValue.clone()
        : initialValue;
    entity.properties[propertyId]!.add(
      SchemaValue(
        id: 'val_${DateTime.now().microsecondsSinceEpoch}',
        value: val,
      ),
    );

    final jsonLd = _compileJsonLd(stateValue.documents, stateValue.selectedDocumentIndex);
    emit(
      stateValue.copyWith(
        documents: List.of(stateValue.documents),
        jsonLdOutput: jsonLd,
      ),
    );
    _persistState();
  }

  void updatePropertyValue(
    SchemaEntity entity,
    String propertyId,
    String valueId,
    dynamic newValue,
  ) {
    final list = entity.properties[propertyId];
    if (list != null) {
      final index = list.indexWhere((v) => v.id == valueId);
      if (index != -1) {
        list[index].value = newValue;
        final jsonLd = _compileJsonLd(stateValue.documents, stateValue.selectedDocumentIndex);
        emit(
          stateValue.copyWith(
            documents: List.of(stateValue.documents),
            jsonLdOutput: jsonLd,
          ),
        );
        _persistState();
      }
    }
  }

  void removePropertyValue(
    SchemaEntity entity,
    String propertyId,
    String valueId,
  ) {
    final list = entity.properties[propertyId];
    if (list != null) {
      list.removeWhere((v) => v.id == valueId);
      if (list.isEmpty) {
        entity.properties.remove(propertyId);
      }
      final jsonLd = _compileJsonLd(stateValue.documents, stateValue.selectedDocumentIndex);
      emit(
        stateValue.copyWith(
          documents: List.of(stateValue.documents),
          jsonLdOutput: jsonLd,
        ),
      );
      _persistState();
    }
  }

  void removePropertyFromEntity(SchemaEntity entity, String propertyId) {
    entity.properties.remove(propertyId);
    final jsonLd = _compileJsonLd(stateValue.documents, stateValue.selectedDocumentIndex);
    emit(
      stateValue.copyWith(
        documents: List.of(stateValue.documents),
        jsonLdOutput: jsonLd,
      ),
    );
    _persistState();
  }

  bool importJsonLd(String jsonString) {
    try {
      final dynamic decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        final imported = SchemaEntity.fromJsonLd(decoded);
        final newDocs = List<SchemaEntity>.from(stateValue.documents)..add(imported);
        final newIndex = newDocs.length - 1;
        final jsonLd = _compileJsonLd(newDocs, newIndex);

        emit(
          stateValue.copyWith(
            documents: newDocs,
            selectedDocumentIndex: newIndex,
            jsonLdOutput: jsonLd,
          ),
        );
        _persistState();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error importing JSON-LD: $e');
      return false;
    }
  }

  void setWorkspaceView(WorkspaceViewMode mode) {
    emit(stateValue.copyWith(viewMode: mode));
  }

  void setActiveMobileTab(int tab) {
    emit(stateValue.copyWith(activeMobileTab: tab));
  }

  void setSearchQuery(String query) {
    emit(stateValue.copyWith(searchQuery: query));
  }

  Future<void> refreshSchemaFromNetwork() async {
    emit(stateValue.copyWith(isSchemaLoading: true, loadError: null));
    await SchemaService.instance.fetchAndCacheLatestSchema();
    final schemaService = SchemaService.instance;
    emit(
      stateValue.copyWith(
        isSchemaLoading: schemaService.isLoadingFullSchema,
        isFullSchemaLoaded: schemaService.isFullSchemaLoaded,
        schemaClassesCount: schemaService.classes.length,
        schemaPropertiesCount: schemaService.properties.length,
        schemaEnumsCount: schemaService.enumerationValues.length,
        loadError: schemaService.loadError,
      ),
    );
  }

  String _compileJsonLd(List<SchemaEntity> docs, int selectedIdx) {
    if (docs.isEmpty || selectedIdx < 0 || selectedIdx >= docs.length) {
      return '{}';
    }
    try {
      final current = docs[selectedIdx];
      final Map<String, String> docIdToName = {};
      for (final doc in docs) {
        docIdToName[doc.id] = doc.name;
      }
      final map = current.toJsonLd(isRoot: true, docIdToName: docIdToName);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    } catch (e) {
      return '/* Error generating JSON-LD: $e */';
    }
  }

  void _persistState() {
    emit(stateValue.copyWith(saveStatus: 'Saving...'));
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      await _saveDocumentsToStorage(stateValue.documents);
      emit(stateValue.copyWith(saveStatus: 'Saved'));
    });
  }

  Future<void> _saveDocumentsToStorage(List<SchemaEntity> docs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializedList = docs.map((d) {
        return {
          'id': d.id,
          'name': d.name,
          'type': d.type,
          'baseUri': d.baseUri,
          'properties': d.serializeProperties(),
        };
      }).toList();
      await prefs.setString(
        'jsonld_visual_editor_docs',
        json.encode(serializedList),
      );
    } catch (e) {
      debugPrint('Error saving documents to storage: $e');
    }
  }
}
