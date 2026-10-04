package org.example.stores.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.example.stores.models.SchemaEntity
import org.example.stores.models.SchemaValue
import org.example.stores.services.SchemaService
import org.example.stores.viewmodel.EditorViewModel

@Composable
fun PropertyRow(
    viewModel: EditorViewModel,
    entity: SchemaEntity,
    propertyId: String,
    values: List<SchemaValue>,
    schemaService: SchemaService = SchemaService.instance,
    modifier: Modifier = Modifier
) {
    val propLabel = propertyId.removePrefix("schema:")
    val propMeta = schemaService.properties[propertyId]
    val ranges = propMeta?.ranges ?: emptyList()
    val enumOptions = remember(ranges) { schemaService.getEnumOptions(ranges) }

    Surface(
        color = MaterialTheme.colorScheme.surface,
        shape = RoundedCornerShape(10.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        modifier = modifier.fillMaxWidth().padding(bottom = 8.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = propLabel,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        if (ranges.isNotEmpty()) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = ranges.joinToString(" | ") { it.removePrefix("schema:") },
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                    if (!propMeta?.comment.isNullOrEmpty()) {
                        Text(
                            text = propMeta!!.comment,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.outline,
                            maxLines = 1
                        )
                    }
                }

                Row {
                    IconButton(
                        onClick = { viewModel.addPropertyToEntity(entity, propertyId, "") },
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(Icons.Default.Add, contentDescription = "Add Value", modifier = Modifier.size(18.dp))
                    }
                    IconButton(
                        onClick = { viewModel.removePropertyFromEntity(entity, propertyId) },
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(Icons.Default.Delete, contentDescription = "Delete Property", tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(18.dp))
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            values.forEach { sv ->
                ValueField(
                    viewModel = viewModel,
                    entity = entity,
                    propertyId = propertyId,
                    schemaValue = sv,
                    ranges = ranges,
                    enumOptions = enumOptions
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ValueField(
    viewModel: EditorViewModel,
    entity: SchemaEntity,
    propertyId: String,
    schemaValue: SchemaValue,
    ranges: List<String>,
    enumOptions: List<String>
) {
    val valObj = schemaValue.value

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)
    ) {
        Box(modifier = Modifier.weight(1f)) {
            when {
                valObj is SchemaEntity -> {
                    Surface(
                        color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.fillMaxWidth().padding(4.dp)
                    ) {
                        Column(modifier = Modifier.padding(8.dp)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = "${valObj.name} (${valObj.type.removePrefix("schema:")})",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            valObj.properties.forEach { (childPropId, childValues) ->
                                PropertyRow(
                                    viewModel = viewModel,
                                    entity = valObj,
                                    propertyId = childPropId,
                                    values = childValues
                                )
                            }
                        }
                    }
                }

                enumOptions.isNotEmpty() -> {
                    var expanded by remember { mutableStateOf(false) }
                    var selectedText by remember { mutableStateOf(valObj?.toString() ?: "") }

                    ExposedDropdownMenuBox(
                        expanded = expanded,
                        onExpandedChange = { expanded = !expanded }
                    ) {
                        OutlinedTextField(
                            value = selectedText,
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Enum Value") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                            modifier = Modifier.menuAnchor().fillMaxWidth()
                        )
                        ExposedDropdownMenu(
                            expanded = expanded,
                            onDismissRequest = { expanded = false }
                        ) {
                            enumOptions.forEach { option ->
                                DropdownMenuItem(
                                    text = { Text(option.removePrefix("schema:")) },
                                    onClick = {
                                        selectedText = option
                                        viewModel.updatePropertyValue(entity, propertyId, schemaValue.id, option)
                                        expanded = false
                                    }
                                )
                            }
                        }
                    }
                }

                else -> {
                    var textState by remember(schemaValue.id) { mutableStateOf(valObj?.toString() ?: "") }
                    OutlinedTextField(
                        value = textState,
                        onValueChange = {
                            textState = it
                            viewModel.updatePropertyValue(entity, propertyId, schemaValue.id, it)
                        },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }

        IconButton(
            onClick = { viewModel.removeValueFromProperty(entity, propertyId, schemaValue.id) },
            modifier = Modifier.size(28.dp).padding(start = 4.dp)
        ) {
            Icon(Icons.Default.Close, contentDescription = "Remove Value", modifier = Modifier.size(16.dp))
        }
    }
}
