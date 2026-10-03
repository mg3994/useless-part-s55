import 'package:stores/models/schema_entity.dart';

enum WorkspaceViewMode {
  columns,
  tree,
  cards,
}

class EditorState {
  const EditorState({
    required this.documents,
    this.selectedDocumentIndex = 0,
    this.isSchemaLoading = false,
    this.isFullSchemaLoaded = false,
    this.schemaClassesCount = 0,
    this.schemaPropertiesCount = 0,
    this.schemaEnumsCount = 0,
    this.loadError,
    this.jsonLdOutput = '{}',
    this.saveStatus = 'Saved',
    this.viewMode = WorkspaceViewMode.columns,
    this.activeMobileTab = 1, // 0: Markups, 1: Editor, 2: JSON-LD Preview
    this.searchQuery = '',
    this.isDarkMode = true,
  });

  final List<SchemaEntity> documents;
  final int selectedDocumentIndex;
  final bool isSchemaLoading;
  final bool isFullSchemaLoaded;
  final int schemaClassesCount;
  final int schemaPropertiesCount;
  final int schemaEnumsCount;
  final String? loadError;
  final String jsonLdOutput;
  final String saveStatus;
  final WorkspaceViewMode viewMode;
  final int activeMobileTab;
  final String searchQuery;
  final bool isDarkMode;

  SchemaEntity? get currentDocument {
    if (documents.isEmpty) return null;
    if (selectedDocumentIndex < 0 || selectedDocumentIndex >= documents.length) {
      return documents.first;
    }
    return documents[selectedDocumentIndex];
  }

  EditorState copyWith({
    List<SchemaEntity>? documents,
    int? selectedDocumentIndex,
    bool? isSchemaLoading,
    bool? isFullSchemaLoaded,
    int? schemaClassesCount,
    int? schemaPropertiesCount,
    int? schemaEnumsCount,
    String? loadError,
    String? jsonLdOutput,
    String? saveStatus,
    WorkspaceViewMode? viewMode,
    int? activeMobileTab,
    String? searchQuery,
    bool? isDarkMode,
  }) {
    return EditorState(
      documents: documents ?? this.documents,
      selectedDocumentIndex:
          selectedDocumentIndex ?? this.selectedDocumentIndex,
      isSchemaLoading: isSchemaLoading ?? this.isSchemaLoading,
      isFullSchemaLoaded: isFullSchemaLoaded ?? this.isFullSchemaLoaded,
      schemaClassesCount: schemaClassesCount ?? this.schemaClassesCount,
      schemaPropertiesCount:
          schemaPropertiesCount ?? this.schemaPropertiesCount,
      schemaEnumsCount: schemaEnumsCount ?? this.schemaEnumsCount,
      loadError: loadError ?? this.loadError,
      jsonLdOutput: jsonLdOutput ?? this.jsonLdOutput,
      saveStatus: saveStatus ?? this.saveStatus,
      viewMode: viewMode ?? this.viewMode,
      activeMobileTab: activeMobileTab ?? this.activeMobileTab,
      searchQuery: searchQuery ?? this.searchQuery,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
