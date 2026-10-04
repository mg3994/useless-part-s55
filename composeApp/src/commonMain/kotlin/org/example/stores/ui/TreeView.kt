package org.example.stores.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.example.stores.models.SchemaEntity
import org.example.stores.viewmodel.EditorViewModel

@Composable
fun SchemaTreeView(
    viewModel: EditorViewModel,
    rootEntity: SchemaEntity,
    modifier: Modifier = Modifier
) {
    var showAddPropDialogFor by remember { mutableStateOf<SchemaEntity?>(null) }

    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = modifier.fillMaxSize()
    ) {
        item {
            EntityTreeNode(
                viewModel = viewModel,
                entity = rootEntity,
                depth = 0,
                onAddProperty = { showAddPropDialogFor = rootEntity }
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
private fun EntityTreeNode(
    viewModel: EditorViewModel,
    entity: SchemaEntity,
    depth: Int,
    onAddProperty: () -> Unit
) {
    var isExpanded by remember { mutableStateOf(true) }

    Surface(
        color = MaterialTheme.colorScheme.surface,
        shape = RoundedCornerShape(12.dp),
        border = androidx.compose.foundation.BorderStroke(
            width = if (depth == 0) 2.dp else 1.dp,
            color = if (depth == 0) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant
        ),
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = (depth * 16).dp, bottom = 8.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth().clickable { isExpanded = !isExpanded }
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.ArrowDropDown,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = entity.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "${entity.type} (${entity.properties.size} properties)",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.outline
                        )
                    }
                }

                Row {
                    IconButton(onClick = onAddProperty, modifier = Modifier.size(28.dp)) {
                        Icon(Icons.Default.Add, contentDescription = "Add Property", modifier = Modifier.size(18.dp))
                    }
                }
            }

            AnimatedVisibility(visible = isExpanded) {
                Column(modifier = Modifier.padding(top = 12.dp)) {
                    entity.properties.forEach { (propId, values) ->
                        PropertyRow(
                            viewModel = viewModel,
                            entity = entity,
                            propertyId = propId,
                            values = values
                        )
                    }
                }
            }
        }
    }
}
