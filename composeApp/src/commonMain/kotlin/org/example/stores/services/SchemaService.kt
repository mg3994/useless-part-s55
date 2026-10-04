package org.example.stores.services

import io.ktor.client.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.*
import org.example.stores.models.SchemaClass
import org.example.stores.models.SchemaProperty

class SchemaService(
    private val client: HttpClient = HttpClient()
) {
    var isLoadingFullSchema: Boolean = false
        private set
    var isFullSchemaLoaded: Boolean = false
        private set
    var loadError: String? = null
        private set

    private var _classes: Map<String, SchemaClass> = emptyMap()
    private var _properties: Map<String, SchemaProperty> = emptyMap()
    private var _enumerationValues: Map<String, List<String>> = emptyMap()

    val classes: Map<String, SchemaClass>
        get() = if (_classes.isEmpty()) popularClasses else _classes

    val properties: Map<String, SchemaProperty>
        get() = if (_properties.isEmpty()) popularProperties else _properties

    val enumerationValues: Map<String, List<String>>
        get() = _enumerationValues

    suspend fun loadSchemaFromCacheOrNetwork(cachedJson: String? = null): Boolean = withContext(Dispatchers.IO) {
        if (isFullSchemaLoaded) return@withContext true
        isLoadingFullSchema = true
        loadError = null

        try {
            val jsonText = if (!cachedJson.isNullOrBlank()) {
                cachedJson
            } else {
                client.get("https://schema.org/version/latest/schemaorg-current-https.jsonld").bodyAsText()
            }
            parseSchemaJsonLd(jsonText)
            isFullSchemaLoaded = true
            isLoadingFullSchema = false
            true
        } catch (e: Exception) {
            loadError = e.message ?: "Failed to load schema"
            isLoadingFullSchema = false
            false
        }
    }

    private fun parseSchemaJsonLd(jsonText: String) {
        val json = Json { ignoreUnknownKeys = true }
        val root = json.parseToJsonElement(jsonText)
        val graph = if (root is JsonObject) {
            root["@graph"]?.jsonArray ?: JsonArray(emptyList())
        } else if (root is JsonArray) {
            root
        } else {
            JsonArray(emptyList())
        }

        val parsedClasses = mutableMapOf<String, SchemaClass>()
        val parsedProperties = mutableMapOf<String, SchemaProperty>()
        val parsedEnums = mutableMapOf<String, MutableList<String>>()

        for (item in graph) {
            if (item !is JsonObject) continue
            val rawId = item["@id"]?.jsonPrimitive?.contentOrNull ?: continue
            val id = if (rawId.startsWith("schema:")) rawId else "schema:${rawId.substringAfterLast("/")}"
            val label = item["rdfs:label"]?.let { getLabelString(it) } ?: id.substringAfter(":")
            val comment = item["rdfs:comment"]?.let { getCommentString(it) } ?: ""

            val rawType = item["@type"]
            val types = when (rawType) {
                is JsonArray -> rawType.mapNotNull { it.jsonPrimitive.contentOrNull }
                is JsonPrimitive -> listOf(rawType.content)
                else -> emptyList()
            }

            val isClass = types.any { it.endsWith("Class") || it == "rdfs:Class" }
            val isProperty = types.any { it.endsWith("Property") || it == "rdf:Property" }

            if (isClass) {
                val subClassOf = parseRefList(item["rdfs:subClassOf"])
                parsedClasses[id] = SchemaClass(
                    id = id,
                    label = label,
                    comment = comment,
                    subClassOf = subClassOf
                )
            } else if (isProperty) {
                val domains = parseRefList(item["schema:domainIncludes"])
                val ranges = parseRefList(item["schema:rangeIncludes"])
                parsedProperties[id] = SchemaProperty(
                    id = id,
                    label = label,
                    comment = comment,
                    domains = domains,
                    ranges = ranges
                )
            } else {
                // Check enumerations
                types.forEach { enumTypeRaw ->
                    val enumType = if (enumTypeRaw.startsWith("schema:")) enumTypeRaw else "schema:${enumTypeRaw.substringAfterLast("/")}"
                    parsedEnums.getOrPut(enumType) { mutableListOf() }.add(id)
                }
            }
        }

        _classes = parsedClasses
        _properties = parsedProperties
        _enumerationValues = parsedEnums
    }

    private fun getLabelString(element: JsonElement): String {
        return when (element) {
            is JsonPrimitive -> element.content
            is JsonObject -> element["@value"]?.jsonPrimitive?.content ?: ""
            else -> ""
        }
    }

    private fun getCommentString(element: JsonElement): String {
        return when (element) {
            is JsonPrimitive -> element.content
            is JsonObject -> element["@value"]?.jsonPrimitive?.content ?: ""
            else -> ""
        }
    }

    private fun parseRefList(element: JsonElement?): List<String> {
        if (element == null) return emptyList()
        val list = mutableListOf<String>()
        fun addRef(item: JsonElement) {
            if (item is JsonObject) {
                item["@id"]?.jsonPrimitive?.contentOrNull?.let { raw ->
                    val norm = if (raw.startsWith("schema:")) raw else "schema:${raw.substringAfterLast("/")}"
                    list.add(norm)
                }
            } else if (item is JsonPrimitive) {
                val raw = item.content
                val norm = if (raw.startsWith("schema:")) raw else "schema:${raw.substringAfterLast("/")}"
                list.add(norm)
            }
        }

        if (element is JsonArray) {
            element.forEach { addRef(it) }
        } else {
            addRef(element)
        }
        return list
    }

    fun getPropertiesForClass(classId: String): List<SchemaProperty> {
        val allClasses = classes
        val targetAncestors = mutableSetOf(classId)
        val queue = mutableListOf(classId)

        while (queue.isNotEmpty()) {
            val curr = queue.removeAt(0)
            allClasses[curr]?.subClassOf?.forEach { parent ->
                if (targetAncestors.add(parent)) {
                    queue.add(parent)
                }
            }
        }

        return properties.values.filter { prop ->
            prop.domains.isEmpty() || prop.domains.any { domain -> targetAncestors.contains(domain) }
        }.sortedBy { it.label }
    }

    fun getEnumOptions(ranges: List<String>): List<String> {
        val options = mutableListOf<String>()
        for (range in ranges) {
            val list = enumerationValues[range]
            if (list != null) {
                options.addAll(list)
            }
        }
        return options.distinct().sorted()
    }

    companion object {
        val instance by lazy { SchemaService() }

        val popularClasses = mapOf(
            "schema:Thing" to SchemaClass("schema:Thing", "Thing", "The most generic type of item.", emptyList()),
            "schema:Person" to SchemaClass("schema:Person", "Person", "A person (alive, dead, undead, or fictional).", listOf("schema:Thing")),
            "schema:Organization" to SchemaClass("schema:Organization", "Organization", "An organization such as a school, NGO, corporation, club, etc.", listOf("schema:Thing")),
            "schema:LocalBusiness" to SchemaClass("schema:LocalBusiness", "LocalBusiness", "A particular physical business or branch of an organization.", listOf("schema:Organization", "schema:Place")),
            "schema:Store" to SchemaClass("schema:Store", "Store", "A retail store.", listOf("schema:LocalBusiness")),
            "schema:Product" to SchemaClass("schema:Product", "Product", "Any offered product or service.", listOf("schema:Thing")),
            "schema:Offer" to SchemaClass("schema:Offer", "Offer", "An offer to transfer rights to an item or provide a service.", listOf("schema:Thing")),
            "schema:Event" to SchemaClass("schema:Event", "Event", "An event happening at a certain time and location.", listOf("schema:Thing")),
            "schema:Place" to SchemaClass("schema:Place", "Place", "Entities that have a somewhat fixed, physical extension.", listOf("schema:Thing")),
            "schema:PostalAddress" to SchemaClass("schema:PostalAddress", "PostalAddress", "The mailing address.", listOf("schema:Place")),
            "schema:WebSite" to SchemaClass("schema:WebSite", "WebSite", "A WebSite is a set of related web pages and other items.", listOf("schema:Thing")),
            "schema:Article" to SchemaClass("schema:Article", "Article", "An article, such as a news article or piece of investigative reporting.", listOf("schema:Thing"))
        )

        val popularProperties = mapOf(
            "schema:name" to SchemaProperty("schema:name", "name", "The name of the item.", listOf("schema:Thing"), listOf("schema:Text")),
            "schema:description" to SchemaProperty("schema:description", "description", "A description of the item.", listOf("schema:Thing"), listOf("schema:Text")),
            "schema:url" to SchemaProperty("schema:url", "url", "URL of the item.", listOf("schema:Thing"), listOf("schema:URL")),
            "schema:image" to SchemaProperty("schema:image", "image", "An image of the item.", listOf("schema:Thing"), listOf("schema:URL", "schema:ImageObject")),
            "schema:telephone" to SchemaProperty("schema:telephone", "telephone", "The telephone number.", listOf("schema:Organization", "schema:Person", "schema:Place"), listOf("schema:Text")),
            "schema:email" to SchemaProperty("schema:email", "email", "Email address.", listOf("schema:Organization", "schema:Person"), listOf("schema:Text")),
            "schema:address" to SchemaProperty("schema:address", "address", "Physical address of the item.", listOf("schema:Organization", "schema:Person", "schema:Place"), listOf("schema:PostalAddress", "schema:Text")),
            "schema:price" to SchemaProperty("schema:price", "price", "The offer price.", listOf("schema:Offer"), listOf("schema:Number", "schema:Text")),
            "schema:priceCurrency" to SchemaProperty("schema:priceCurrency", "priceCurrency", "The currency of the price.", listOf("schema:Offer"), listOf("schema:Text")),
            "schema:offers" to SchemaProperty("schema:offers", "offers", "An offer to provide this item.", listOf("schema:Product", "schema:Event"), listOf("schema:Offer")),
            "schema:brand" to SchemaProperty("schema:brand", "brand", "The brand associated with a product.", listOf("schema:Product"), listOf("schema:Brand", "schema:Organization")),
            "schema:sku" to SchemaProperty("schema:sku", "sku", "Stock Keeping Unit.", listOf("schema:Product"), listOf("schema:Text")),
            "schema:startDate" to SchemaProperty("schema:startDate", "startDate", "Start date and time.", listOf("schema:Event"), listOf("schema:Date", "schema:DateTime")),
            "schema:location" to SchemaProperty("schema:location", "location", "The location of for example where the event is happening.", listOf("schema:Event"), listOf("schema:Place", "schema:PostalAddress", "schema:Text"))
        )
    }
}
