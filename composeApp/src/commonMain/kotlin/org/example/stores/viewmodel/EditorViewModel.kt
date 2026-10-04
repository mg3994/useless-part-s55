package org.example.stores.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.russhwolf.settings.Settings
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import org.example.stores.models.SchemaEntity
import org.example.stores.models.SchemaProperty
import org.example.stores.models.SchemaValue
import org.example.stores.services.SchemaService

class EditorViewModel(
    private val schemaService: SchemaService = SchemaService.instance,
    private val settings: Settings = Settings()
) : ViewModel() {

    private val _state = MutableStateFlow(EditorState())
    val state: StateFlow<EditorState> = _state.asStateFlow()

    private val json = Json { prettyPrint = true }

    init {
        initEditor()
    }

    fun initEditor() {
        val isDark = settings.getBoolean(PREF_DARK_MODE, false)
        _state.update { it.copy(isDarkMode = isDark) }

        val initialDoc = SchemaEntity(
            id = "doc_${System.currentTimeMillis()}",
            type = "schema:Store",
            name = "Main Store",
            baseUri = "https://example.com/stores/"
        ).apply {
            properties["schema:name"] = mutableListOf(
                SchemaValue("val_${System.currentTimeMillis()}_1", "Apex Retail Store")
            )
            properties["schema:description"] = mutableListOf(
                SchemaValue("val_${System.currentTimeMillis()}_2", "Flagship store in downtown with electronics & apparel.")
            )
            properties["schema:telephone"] = mutableListOf(
                SchemaValue("val_${System.currentTimeMillis()}_3", "+1-800-555-0199")
            )
            properties["schema:url"] = mutableListOf(
                SchemaValue("val_${System.currentTimeMillis()}_4", "https://example.com/stores/apex-main")
            )

            val addressEntity = SchemaEntity(
                id = "nest_${System.currentTimeMillis()}_addr",
                type = "schema:PostalAddress",
                name = "PostalAddress Object"
            ).apply {
                properties["schema:streetAddress"] = mutableListOf(SchemaValue("val_${System.currentTimeMillis()}_a1", "100 Market Street"))
                properties["schema:addressLocality"] = mutableListOf(SchemaValue("val_${System.currentTimeMillis()}_a2", "San Francisco"))
                properties["schema:addressRegion"] = mutableListOf(SchemaValue("val_${System.currentTimeMillis()}_a3", "CA"))
                properties["schema:postalCode"] = mutableListOf(SchemaValue("val_${System.currentTimeMillis()}_a4", "94105"))
                properties["schema:addressCountry"] = mutableListOf(SchemaValue("val_${System.currentTimeMillis()}_a5", "US"))
            }
            properties["schema:address"] = mutableListOf(
                SchemaValue("val_${System.currentTimeMillis()}_5", addressEntity)
            )
        }

        _state.update {
            it.copy(
                documents = listOf(initialDoc),
                selectedDocumentIndex = 0,
                schemaClassesCount = schemaService.classes.size,
                schemaPropertiesCount = schemaService.properties.size,
                schemaEnumsCount = schemaService.enumerationValues.size
            )
        }
        rebuildJsonLd()

        viewModelScope.launch {
            loadFullSchema()
        }
    }

    fun loadFullSchema() {
        viewModelScope.launch {
            _state.update { it.copy(isSchemaLoading = true, loadError = null) }
            val cachedJson = settings.getStringOrNull(PREF_SCHEMA_CACHE)
            val success = schemaService.loadSchemaFromCacheOrNetwork(cachedJson)
            if (success) {
                _state.update {
                    it.copy(
                        isSchemaLoading = false,
                        isFullSchemaLoaded = true,
                        schemaClassesCount = schemaService.classes.size,
                        schemaPropertiesCount = schemaService.properties.size,
                        schemaEnumsCount = schemaService.enumerationValues.size
                    )
                }
            } else {
                _state.update {
                    it.copy(
                        isSchemaLoading = false,
                        loadError = schemaService.loadError ?: "Failed to load schema"
                    )
                }
            }
        }
    }

    fun toggleDarkMode() {
        val newDark = !_state.value.isDarkMode
        settings.putBoolean(PREF_DARK_MODE, newDark)
        _state.update { it.copy(isDarkMode = newDark) }
    }

    fun setViewMode(mode: WorkspaceViewMode) {
        _state.update { it.copy(viewMode = mode) }
    }

    fun setActiveMobileTab(tabIndex: Int) {
        _state.update { it.copy(activeMobileTab = tabIndex) }
    }

    fun setSearchQuery(query: String) {
        _state.update { it.copy(searchQuery = query) }
    }

    fun selectDocument(index: Int) {
        if (index in _state.value.documents.indices) {
            _state.update { it.copy(selectedDocumentIndex = index) }
            rebuildJsonLd()
        }
    }

    fun createNewDocument(type: String, name: String? = null): SchemaEntity {
        val cleanType = if (type.contains(":")) type else "schema:$type"
        val docName = name?.takeIf { it.isNotBlank() } ?: "${cleanType.substringAfter(":")} Document"
        val newDoc = SchemaEntity(
            id = "doc_${System.currentTimeMillis()}",
            type = cleanType,
            name = docName
        )
        val updatedList = _state.value.documents + newDoc
        _state.update {
            it.copy(
                documents = updatedList,
                selectedDocumentIndex = updatedList.lastIndex
            )
        }
        rebuildJsonLd()
        return newDoc
    }

    fun duplicateDocument(document: SchemaEntity) {
        val dup = document.clone()
        dup.name = "${document.name} (Copy)"
        val updatedList = _state.value.documents + dup
        _state.update {
            it.copy(
                documents = updatedList,
                selectedDocumentIndex = updatedList.lastIndex
            )
        }
        rebuildJsonLd()
    }

    fun deleteDocument(document: SchemaEntity) {
        if (_state.value.documents.size <= 1) return
        val currentIdx = _state.value.documents.indexOf(document)
        if (currentIdx == -1) return

        val updatedList = _state.value.documents.filter { it != document }
        val newIndex = (if (_state.value.selectedDocumentIndex >= updatedList.size) updatedList.size - 1 else _state.value.selectedDocumentIndex).coerceAtLeast(0)

        _state.update {
            it.copy(
                documents = updatedList,
                selectedDocumentIndex = newIndex
            )
        }
        rebuildJsonLd()
    }

    fun renameDocument(document: SchemaEntity, newName: String) {
        document.name = newName.trim().ifEmpty { "Untitled Document" }
        _state.update { it.copy(documents = ArrayList(it.documents)) }
        rebuildJsonLd()
    }

    fun updateDocumentType(document: SchemaEntity, newType: String) {
        val clean = if (newType.contains(":")) newType else "schema:$newType"
        document.type = clean
        _state.update { it.copy(documents = ArrayList(it.documents)) }
        rebuildJsonLd()
    }

    fun updateBaseUri(document: SchemaEntity, baseUri: String?) {
        document.baseUri = baseUri?.trim()?.ifEmpty { null }
        _state.update { it.copy(documents = ArrayList(it.documents)) }
        rebuildJsonLd()
    }

    fun addPropertyToEntity(targetEntity: SchemaEntity, propertyId: String, initialValue: Any?) {
        val list = targetEntity.properties.getOrPut(propertyId) { mutableListOf() }
        val valId = "val_${System.currentTimeMillis()}_${list.size}"
        list.add(SchemaValue(id = valId, value = initialValue))
        _state.update { it.copy(documents = ArrayList(it.documents)) }
        rebuildJsonLd()
    }

    fun updatePropertyValue(targetEntity: SchemaEntity, propertyId: String, valueId: String, newValue: Any?) {
        val list = targetEntity.properties[propertyId] ?: return
        val item = list.find { it.id == valueId } ?: return
        item.value = newValue
        _state.update { it.copy(documents = ArrayList(it.documents)) }
        rebuildJsonLd()
    }

    fun removeValueFromProperty(targetEntity: SchemaEntity, propertyId: String, valueId: String) {
        val list = targetEntity.properties[propertyId] ?: return
        list.removeAll { it.id == valueId }
        if (list.isEmpty()) {
            targetEntity.properties.remove(propertyId)
        }
        _state.update { it.copy(documents = ArrayList(it.documents)) }
        rebuildJsonLd()
    }

    fun removePropertyFromEntity(targetEntity: SchemaEntity, propertyId: String) {
        targetEntity.properties.remove(propertyId)
        _state.update { it.copy(documents = ArrayList(it.documents)) }
        rebuildJsonLd()
    }

    fun createNestedEntity(targetEntity: SchemaEntity, propertyId: String, childType: String): SchemaEntity {
        val cleanType = if (childType.contains(":")) childType else "schema:$childType"
        val child = SchemaEntity(
            id = "nest_${System.currentTimeMillis()}",
            type = cleanType,
            name = "${cleanType.substringAfter(":")} Object"
        )
        addPropertyToEntity(targetEntity, propertyId, child)
        return child
    }

    fun rebuildJsonLd() {
        val doc = _state.value.currentDocument
        if (doc == null) {
            _state.update { it.copy(jsonLdOutput = "{}") }
            return
        }

        val docIdMap = _state.value.documents.associate { it.id to it.name }
        val jsonObj = doc.toJsonLd(
            isRoot = true,
            docIdToName = docIdMap,
            enumerationValues = schemaService.enumerationValues
        )
        val pretty = json.encodeToString(JsonObject.serializer(), jsonObj)
        _state.update { it.copy(jsonLdOutput = pretty) }
    }

    companion object {
        private const val PREF_DARK_MODE = "is_dark_mode"
        private const val PREF_SCHEMA_CACHE = "schema_org_cache_v1"
    }
}
