package org.example.stores.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.example.stores.models.SchemaEntity
import org.example.stores.viewmodel.EditorViewModel

@Composable
fun MillerColumnsView(
    viewModel: EditorViewModel,
    rootEntity: SchemaEntity,
    modifier: Modifier = Modifier
) {
    var path by remember(rootEntity.id) { mutableStateOf(listOf(rootEntity)) }
    var showAddPropDialogFor by remember { mutableStateOf<SchemaEntity?>(null) }

    val horizontalScrollState = rememberScrollState()

    Row(
        modifier = modifier
            .fillMaxSize()
            .horizontalScroll(horizontalScrollState)
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        path.forEachIndexed { depth, entity ->
            MillerColumn(
                viewModel = viewModel,
                entity = entity,
                depth = depth,
                isSelectedInPath = { childEntity ->
                    depth + 1 < path.size && path[depth + 1] == childEntity
                },
                onSelectNestedEntity = { childEntity ->
                    path = path.take(depth + 1) + childEntity
                },
                onAddPropertyClick = {
                    showAddPropDialogFor = entity
                }
            )
        }
    }

    showAddPropDialogFor?.let { targetEntity ->
        AddPropertyDialog(
            entity = targetEntity,
            onDismiss = { showAddPropDialogFor = null },
            onPropertySelected = { prop, initialVal ->
                viewModel.addPropertyToEntity(targetEntity, prop.id, initialVal)
            }
        )
    }
}

@Composable
private fun MillerColumn(
    viewModel: EditorViewModel,
    entity: SchemaEntity,
    depth: Int,
    isSelectedInPath: (SchemaEntity) -> Boolean,
    onSelectNestedEntity: (SchemaEntity) -> Unit,
    onAddPropertyClick: () -> Unit
) {
    Surface(
        color = MaterialTheme.colorScheme.surface,
        shape = RoundedCornerShape(12.dp),
        tonalElevation = 2.dp,
        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        modifier = Modifier.width(320.dp).fillMaxHeight()
    ) {
        Column(modifier = Modifier.fillMaxSize().padding(12.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
            ) {
                Column {
                    Text(
                        text = entity.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = entity.type,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                IconButton(onClick = onAddPropertyClick, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Default.Add, contentDescription = "Add Property")
                }
            }

            HorizontalDivider(modifier = Modifier.padding(bottom = 8.dp))

            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.weight(1f)
            ) {
                val entries = entity.properties.entries.toList()
                items(entries) { (propId, values) ->
                    Column {
                        PropertyRow(
                            viewModel = viewModel,
                            entity = entity,
                            propertyId = propId,
                            values = values
                        )

                        values.forEach { sv ->
                            val v = sv.value
                            if (v is SchemaEntity) {
                                val isSelected = isSelectedInPath(v)
                                Surface(
                                    color = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                                    shape = RoundedCornerShape(6.dp),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(start = 8.dp, bottom = 4.dp)
                                        .clip(RoundedCornerShape(6.dp))
                                        .clickable { onSelectNestedEntity(v) }
                                ) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp)
                                    ) {
                                        Text(
                                            text = "→ ${v.name} (${v.type.removePrefix("schema:")})",
                                            style = MaterialTheme.typography.bodySmall,
                                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                        )
                                        Icon(
                                            Icons.Default.ArrowDropDown,
                                            contentDescription = "Expand Column",
                                            modifier = Modifier.size(16.dp),
                                            tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
