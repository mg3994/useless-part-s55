package org.example.stores.viewmodel

import org.example.stores.models.SchemaEntity

enum class WorkspaceViewMode {
    MILLER_COLUMNS,
    TREE,
    CARD_FORM
}

data class EditorState(
    val documents: List<SchemaEntity> = emptyList(),
    val selectedDocumentIndex: Int = 0,
    val isSchemaLoading: Boolean = false,
    val isFullSchemaLoaded: Boolean = false,
    val schemaClassesCount: Int = 0,
    val schemaPropertiesCount: Int = 0,
    val schemaEnumsCount: Int = 0,
    val loadError: String? = null,
    val jsonLdOutput: String = "{\n  \"@context\": \"https://schema.org\",\n  \"@type\": \"Thing\"\n}",
    val saveStatus: String? = null,
    val viewMode: WorkspaceViewMode = WorkspaceViewMode.MILLER_COLUMNS,
    val activeMobileTab: Int = 0,
    val searchQuery: String = "",
    val isDarkMode: Boolean = false
) {
    val currentDocument: SchemaEntity?
        get() = if (documents.isNotEmpty() && selectedDocumentIndex in documents.indices) {
            documents[selectedDocumentIndex]
        } else null
}
