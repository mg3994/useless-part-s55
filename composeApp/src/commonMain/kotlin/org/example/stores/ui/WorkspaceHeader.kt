package org.example.stores.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.example.stores.models.SchemaEntity
import org.example.stores.viewmodel.EditorState
import org.example.stores.viewmodel.EditorViewModel
import org.example.stores.viewmodel.WorkspaceViewMode

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkspaceHeader(
    viewModel: EditorViewModel,
    state: EditorState,
    document: SchemaEntity,
    isMobile: Boolean = false,
    modifier: Modifier = Modifier
) {
    var showTypeDialog by remember { mutableStateOf(false) }
    var showBaseUriDialog by remember { mutableStateOf(false) }

    Surface(
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp,
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.weight(1f, fill = false)
                ) {
                    Text(
                        text = document.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Surface(
                        color = MaterialTheme.colorScheme.primaryContainer,
                        shape = RoundedCornerShape(16.dp),
                        modifier = Modifier.clip(RoundedCornerShape(16.dp)).clickable { showTypeDialog = true }
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = "@type: ${document.type.removePrefix("schema:")}",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                            Icon(
                                Icons.Default.ArrowDropDown,
                                contentDescription = "Change Type",
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }

                    if (!isMobile) {
                        Surface(
                            color = MaterialTheme.colorScheme.surfaceVariant,
                            shape = RoundedCornerShape(6.dp),
                            modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable { showBaseUriDialog = true }
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Icon(
                                    Icons.Default.Info,
                                    contentDescription = null,
                                    modifier = Modifier.size(14.dp),
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = document.baseUri ?: "@base: default",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    if (!isMobile) {
                        SingleChoiceSegmentedButtonRow {
                            SegmentedButton(
                                selected = state.viewMode == WorkspaceViewMode.MILLER_COLUMNS,
                                onClick = { viewModel.setViewMode(WorkspaceViewMode.MILLER_COLUMNS) },
                                shape = SegmentedButtonDefaults.itemShape(index = 0, count = 3)
                            ) {
                                Text("Columns")
                            }
                            SegmentedButton(
                                selected = state.viewMode == WorkspaceViewMode.TREE,
                                onClick = { viewModel.setViewMode(WorkspaceViewMode.TREE) },
                                shape = SegmentedButtonDefaults.itemShape(index = 1, count = 3)
                            ) {
                                Text("Tree")
                            }
                            SegmentedButton(
                                selected = state.viewMode == WorkspaceViewMode.CARD_FORM,
                                onClick = { viewModel.setViewMode(WorkspaceViewMode.CARD_FORM) },
                                shape = SegmentedButtonDefaults.itemShape(index = 2, count = 3)
                            ) {
                                Text("Form")
                            }
                        }

                        Spacer(modifier = Modifier.width(8.dp))
                    }

                    IconButton(onClick = { viewModel.toggleDarkMode() }) {
                        Icon(
                            imageVector = Icons.Default.Settings,
                            contentDescription = "Toggle Theme Mode"
                        )
                    }
                }
            }
        }
    }

    if (showTypeDialog) {
        var tempType by remember { mutableStateOf(document.type.removePrefix("schema:")) }
        AlertDialog(
            onDismissRequest = { showTypeDialog = false },
            title = { Text("Change Root @type") },
            text = {
                OutlinedTextField(
                    value = tempType,
                    onValueChange = { tempType = it },
                    label = { Text("Schema Type") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.updateDocumentType(document, tempType)
                    showTypeDialog = false
                }) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { showTypeDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showBaseUriDialog) {
        var tempBaseUri by remember { mutableStateOf(document.baseUri ?: "") }
        AlertDialog(
            onDismissRequest = { showBaseUriDialog = false },
            title = { Text("Configure @base URI") },
            text = {
                OutlinedTextField(
                    value = tempBaseUri,
                    onValueChange = { tempBaseUri = it },
                    label = { Text("Base URI (e.g. https://example.com/item/)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.updateBaseUri(document, tempBaseUri)
                    showBaseUriDialog = false
                }) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { showBaseUriDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
