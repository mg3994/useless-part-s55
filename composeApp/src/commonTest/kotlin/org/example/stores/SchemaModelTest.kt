package org.example.stores

import org.example.stores.models.SchemaEntity
import org.example.stores.models.SchemaValue
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class SchemaModelTest {

    @Test
    fun testJsonLdGeneration() {
        val entity = SchemaEntity(
            id = "doc_1",
            type = "schema:Store",
            name = "My Main Store",
            baseUri = "https://example.com/stores/"
        )

        entity.properties["schema:name"] = mutableListOf(SchemaValue("v1", "Tech Store"))
        entity.properties["schema:price"] = mutableListOf(SchemaValue("v2", 99.99))

        val json = entity.toJsonLd(isRoot = true)

        assertNotNull(json["@context"])
        assertEquals("Store", json["@type"]?.let { (it as kotlinx.serialization.json.JsonPrimitive).content })
        assertEquals("Tech Store", json["name"]?.let { (it as kotlinx.serialization.json.JsonPrimitive).content })
    }

    @Test
    fun testEntityCloning() {
        val entity = SchemaEntity(
            id = "doc_1",
            type = "schema:Product",
            name = "Awesome Laptop"
        )
        entity.properties["schema:name"] = mutableListOf(SchemaValue("v1", "Awesome Laptop"))

        val cloned = entity.clone { 123456L }

        assertEquals("nest_123456_doc_1", cloned.id)
        assertEquals("schema:Product", cloned.type)
        assertEquals("Awesome Laptop", cloned.name)
        assertEquals(1, cloned.properties["schema:name"]?.size)
    }
}
