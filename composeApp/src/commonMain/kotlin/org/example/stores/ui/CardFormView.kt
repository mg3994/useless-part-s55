package org.example.stores.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.example.stores.models.SchemaEntity
import org.example.stores.viewmodel.EditorViewModel

@Composable
fun CardFormView(
    viewModel: EditorViewModel,
    rootEntity: SchemaEntity,
    modifier: Modifier = Modifier
) {
    var showAddPropDialog by remember { mutableStateOf(false) }

    Box(
        modifier = modifier.fillMaxSize().padding(16.dp),
        contentAlignment = Alignment.TopCenter
    ) {
        Column(
            modifier = Modifier.widthIn(max = 800.dp).fillMaxWidth()
        ) {
            ElevatedCard(
                modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column {
                            Text(
                                text = rootEntity.name,
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "Root Type: ${rootEntity.type}",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        Button(onClick = { showAddPropDialog = true }) {
                            Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Add Property")
                        }
                    }
                }
            }

            HorizontalDivider(modifier = Modifier.padding(bottom = 16.dp))

            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.weight(1f)
            ) {
                val entries = rootEntity.properties.entries.toList()
                items(entries) { (propId, values) ->
                    PropertyRow(
                        viewModel = viewModel,
                        entity = rootEntity,
                        propertyId = propId,
                        values = values
                    )
                }
            }
        }
    }

    if (showAddPropDialog) {
        AddPropertyDialog(
            entity = rootEntity,
            onDismiss = { showAddPropDialog = false },
            onPropertySelected = { prop, initialVal ->
                viewModel.addPropertyToEntity(rootEntity, prop.id, initialVal)
            }
        )
    }
}
