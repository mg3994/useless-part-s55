package org.example.stores.models

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.*

@Serializable
data class SchemaClass(
    val id: String,
    val label: String,
    val comment: String = "",
    val subClassOf: List<String> = emptyList()
)

@Serializable
data class SchemaProperty(
    val id: String,
    val label: String,
    val comment: String = "",
    val domains: List<String> = emptyList(),
    val ranges: List<String> = emptyList(),
    val defaultValue: String? = null,
    val isRequired: Boolean = false
)

data class SchemaValue(
    val id: String,
    var value: Any?
)

class SchemaEntity(
    val id: String,
    var type: String,
    val properties: MutableMap<String, MutableList<SchemaValue>> = mutableMapOf(),
    var name: String = "Untitled Document",
    var baseUri: String? = null
) {
    companion object {
        val namespaces = mapOf(
            "bibo" to "http://purl.org/ontology/bibo/",
            "brick" to "https://brickschema.org/schema/Brick#",
            "cmns-cls" to "https://www.omg.org/spec/Commons/Classifiers/",
            "cmns-col" to "https://www.omg.org/spec/Commons/Collections/",
            "cmns-dt" to "https://www.omg.org/spec/Commons/DatesAndTimes/",
            "cmns-ge" to "https://www.omg.org/spec/Commons/GeopoliticalEntities/",
            "cmns-id" to "https://www.omg.org/spec/Commons/Identifiers/",
            "cmns-loc" to "https://www.omg.org/spec/Commons/Locations/",
            "cmns-q" to "https://www.omg.org/spec/Commons/Quantities/",
            "cmns-txt" to "https://www.omg.org/spec/Commons/Text/",
            "csvw" to "http://www.w3.org/ns/csvw#",
            "dc" to "http://purl.org/dc/elements/1.1/",
            "dcat" to "http://www.w3.org/ns/dcat#",
            "dct" to "http://purl.org/dc/terms/",
            "eli" to "http://data.europa.eu/eli/ontology#",
            "foaf" to "http://xmlns.com/foaf/0.1/",
            "geo" to "http://www.opengis.net/ont/geosparql#",
            "gs1" to "https://ref.gs1.org/voc/",
            "owl" to "http://www.w3.org/2002/07/owl#",
            "rdf" to "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            "rdfs" to "http://www.w3.org/2000/01/rdf-schema#",
            "schema" to "https://schema.org/",
            "skos" to "http://www.w3.org/2004/02/skos/core#",
            "time" to "http://www.w3.org/2006/time#",
            "xsd" to "http://www.w3.org/2001/XMLSchema#"
        )

        private fun isNameRenamed(nameValue: String): Boolean {
            val clean = nameValue.trim()
            return clean.isNotEmpty() &&
                    clean != "Untitled Document" &&
                    clean != "Untitled Object" &&
                    clean != "Schema Document" &&
                    !clean.startsWith("New ") &&
                    !clean.endsWith(" Reference") &&
                    !clean.endsWith(" Markup")
        }
    }

    private fun collectUsedNamespaces(valObj: Any?, used: MutableSet<String>) {
        when (valObj) {
            is SchemaEntity -> {
                val t = valObj.type
                if (t.contains(":")) {
                    val prefix = t.substringBefore(":")
                    if (namespaces.containsKey(prefix)) used.add(prefix)
                }
                valObj.properties.values.forEach { list ->
                    list.forEach { sv -> collectUsedNamespaces(sv.value, used) }
                }
            }
            is Map<*, *> -> {
                val t = valObj["@type"]?.toString()
                if (t != null && t.contains(":")) {
                    val prefix = t.substringBefore(":")
                    if (namespaces.containsKey(prefix)) used.add(prefix)
                }
                valObj.forEach { (_, v) -> collectUsedNamespaces(v, used) }
            }
            is List<*> -> {
                valObj.forEach { item -> collectUsedNamespaces(item, used) }
            }
        }
    }

    fun toJsonLd(
        isRoot: Boolean = false,
        docIdToName: Map<String, String>? = null,
        enumerationValues: Map<String, List<String>> = emptyMap()
    ): JsonObject {
        val map = mutableMapOf<String, JsonElement>()

        if (isRoot) {
            val usedPrefixes = mutableSetOf<String>()
            collectUsedNamespaces(this, usedPrefixes)

            val extraContext = mutableMapOf<String, JsonElement>()
            for (prefix in usedPrefixes) {
                namespaces[prefix]?.let { url ->
                    extraContext[prefix] = JsonPrimitive(url)
                }
            }

            if (baseUri.isNullOrBlank()) {
                if (extraContext.isNotEmpty()) {
                    val contextObj = mutableMapOf<String, JsonElement>()
                    contextObj["@vocab"] = JsonPrimitive("https://schema.org/")
                    contextObj.putAll(extraContext)
                    map["@context"] = JsonObject(contextObj)
                } else {
                    map["@context"] = JsonPrimitive("https://schema.org")
                }
            } else {
                val contextObj = mutableMapOf<String, JsonElement>()
                contextObj["@vocab"] = JsonPrimitive("https://schema.org/")
                contextObj["@base"] = JsonPrimitive(baseUri!!.trim())
                contextObj.putAll(extraContext)
                map["@context"] = JsonObject(contextObj)
            }
        }

        val typeName = if (type.startsWith("schema:")) type.substring(7) else type
        val isKeyword = typeName.startsWith("@")

        if (!isKeyword) {
            map["@type"] = JsonPrimitive(typeName)
        }

        val effectiveBase = if (!baseUri.isNullOrBlank()) baseUri!!.trim() else "https://example.com/things/"

        if (!isKeyword) {
            if (isNameRenamed(name)) {
                val safeId = name.trim().lowercase()
                    .replace(Regex("[^\\w\\s\\-]"), "")
                    .replace(Regex("\\s+"), "-")
                map["@id"] = JsonPrimitive("#$safeId")
            } else if (id.startsWith(effectiveBase)) {
                map["@id"] = JsonPrimitive(id.substring(effectiveBase.length))
            } else if (id.startsWith("http://") || id.startsWith("https://")) {
                map["@id"] = JsonPrimitive(id)
            }
        }

        properties.forEach { (propId, values) ->
            if (values.isNotEmpty()) {
                val propName = if (propId.startsWith("schema:")) propId.substring(7) else propId
                val jsonValues = mutableListOf<JsonElement>()

                for (sv in values) {
                    val v = sv.value
                    when (v) {
                        is SchemaEntity -> {
                            jsonValues.add(v.toJsonLd(isRoot = false, docIdToName = docIdToName, enumerationValues = enumerationValues))
                        }
                        is Map<*, *> -> {
                            @Suppress("UNCHECKED_CAST")
                            val m = v as Map<String, Any?>
                            if (m.containsKey("@value")) {
                                val valueObj = mutableMapOf<String, JsonElement>()
                                m.forEach { (mk, mv) ->
                                    valueObj[mk] = when (mv) {
                                        is Boolean -> JsonPrimitive(mv)
                                        is Number -> JsonPrimitive(mv)
                                        else -> JsonPrimitive(mv.toString())
                                    }
                                }
                                jsonValues.add(JsonObject(valueObj))
                            } else if (m.containsKey("@id")) {
                                val targetDocId = m["@id"].toString()
                                val targetDocName = docIdToName?.get(targetDocId)
                                    ?: m["docName"]?.toString()
                                    ?: ""
                                if (isNameRenamed(targetDocName)) {
                                    val safeLinkedId = targetDocName.trim().lowercase()
                                        .replace(Regex("[^\\w\\s\\-]"), "")
                                        .replace(Regex("\\s+"), "-")
                                    jsonValues.add(JsonObject(mapOf("@id" to JsonPrimitive("#$safeLinkedId"))))
                                } else {
                                    val refId = when {
                                        targetDocId.startsWith(effectiveBase) -> targetDocId.substring(effectiveBase.length)
                                        targetDocId.startsWith("http://") || targetDocId.startsWith("https://") || targetDocId.startsWith("#") -> targetDocId
                                        else -> "#$targetDocId"
                                    }
                                    jsonValues.add(JsonObject(mapOf("@id" to JsonPrimitive(refId))))
                                }
                            }
                        }
                        is String -> {
                            val strVal = v
                            var isEnum = false
                            if (strVal.startsWith("schema:")) {
                                for (list in enumerationValues.values) {
                                    if (list.contains(strVal)) {
                                        isEnum = true
                                        break
                                    }
                                }
                            }
                            if (isEnum) {
                                jsonValues.add(JsonPrimitive("https://schema.org/${strVal.substring(7)}"))
                            } else {
                                jsonValues.add(JsonPrimitive(strVal))
                            }
                        }
                        is Boolean -> jsonValues.add(JsonPrimitive(v))
                        is Number -> jsonValues.add(JsonPrimitive(v))
                        null -> {}
                        else -> jsonValues.add(JsonPrimitive(v.toString()))
                    }
                }

                if (jsonValues.isNotEmpty()) {
                    if (jsonValues.size == 1) {
                        map[propName] = jsonValues.first()
                    } else {
                        map[propName] = JsonArray(jsonValues)
                    }
                }
            }
        }

        return JsonObject(map)
    }

    fun clone(timeProvider: () -> Long = { System.currentTimeMillis() }): SchemaEntity {
        val clonedProps = mutableMapOf<String, MutableList<SchemaValue>>()
        properties.forEach { (key, list) ->
            clonedProps[key] = list.map { sv ->
                val valObj = sv.value
                val newValue = when (valObj) {
                    is SchemaEntity -> valObj.clone(timeProvider)
                    is Map<*, *> -> valObj.toMutableMap()
                    else -> valObj
                }
                SchemaValue(id = sv.id, value = newValue)
            }.toMutableList()
        }
        return SchemaEntity(
            id = "nest_${timeProvider()}_$id",
            type = type,
            properties = clonedProps,
            name = name,
            baseUri = baseUri
        )
    }
}
