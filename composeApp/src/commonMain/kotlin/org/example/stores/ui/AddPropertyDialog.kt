package org.example.stores.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.example.stores.models.SchemaEntity
import org.example.stores.models.SchemaProperty
import org.example.stores.services.SchemaService

@Composable
fun AddPropertyDialog(
    entity: SchemaEntity,
    schemaService: SchemaService = SchemaService.instance,
    onDismiss: () -> Unit,
    onPropertySelected: (SchemaProperty, initialValue: Any?) -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    val availableProperties = remember(entity.type) {
        schemaService.getPropertiesForClass(entity.type)
    }

    val filtered = availableProperties.filter {
        searchQuery.isBlank() ||
                it.label.contains(searchQuery, ignoreCase = true) ||
                it.comment.contains(searchQuery, ignoreCase = true)
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Property to ${entity.name}") },
        text = {
            Column(modifier = Modifier.fillMaxWidth().height(400.dp)) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text("Search schema properties...") },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
                )

                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    items(filtered) { prop ->
                        Surface(
                            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
                            shape = MaterialTheme.shapes.small,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    onPropertySelected(prop, prop.defaultValue ?: "")
                                    onDismiss()
                                }
                        ) {
                            Column(modifier = Modifier.padding(8.dp)) {
                                Row(
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text(
                                        text = prop.label,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.Bold
                                    )
                                    if (prop.ranges.isNotEmpty()) {
                                        Text(
                                            text = prop.ranges.joinToString(" | ") { it.removePrefix("schema:") },
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                    }
                                }
                                if (prop.comment.isNotEmpty()) {
                                    Text(
                                        text = prop.comment,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.outline,
                                        maxLines = 2
                                    )
                                }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        }
    )
}
