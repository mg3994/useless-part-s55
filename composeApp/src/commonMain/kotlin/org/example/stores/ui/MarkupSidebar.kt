package org.example.stores.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.example.stores.models.SchemaEntity
import org.example.stores.viewmodel.EditorState
import org.example.stores.viewmodel.EditorViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MarkupSidebar(
    viewModel: EditorViewModel,
    state: EditorState,
    modifier: Modifier = Modifier
) {
    var showNewDocDialog by remember { mutableStateOf(false) }

    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
        modifier = modifier.fillMaxHeight().width(260.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Markup Documents",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                IconButton(
                    onClick = { showNewDocDialog = true },
                    modifier = Modifier.size(28.dp)
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Add Document", tint = MaterialTheme.colorScheme.primary)
                }
            }

            HorizontalDivider(modifier = Modifier.padding(bottom = 8.dp))

            OutlinedTextField(
                value = state.searchQuery,
                onValueChange = { viewModel.setSearchQuery(it) },
                placeholder = { Text("Filter documents...", fontSize = 12.sp) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, modifier = Modifier.size(16.dp)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
            )

            val filteredDocs = state.documents.filter {
                state.searchQuery.isEmpty() ||
                        it.name.contains(state.searchQuery, ignoreCase = true) ||
                        it.type.contains(state.searchQuery, ignoreCase = true)
            }

            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier.weight(1f)
            ) {
                itemsIndexed(filteredDocs) { _, doc ->
                    val originalIndex = state.documents.indexOf(doc)
                    val isSelected = originalIndex == state.selectedDocumentIndex

                    Surface(
                        color = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface,
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .clickable { viewModel.selectDocument(originalIndex) }
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp)
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = doc.name,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                    maxLines = 1
                                )
                                Text(
                                    text = doc.type.removePrefix("schema:"),
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.outline
                                )
                            }

                            var showMenu by remember { mutableStateOf(false) }
                            Box {
                                IconButton(
                                    onClick = { showMenu = true },
                                    modifier = Modifier.size(24.dp)
                                ) {
                                    Icon(Icons.Default.MoreVert, contentDescription = "Options", modifier = Modifier.size(16.dp))
                                }
                                DropdownMenu(
                                    expanded = showMenu,
                                    onDismissRequest = { showMenu = false }
                                ) {
                                    DropdownMenuItem(
                                        text = { Text("Duplicate") },
                                        onClick = {
                                            viewModel.duplicateDocument(doc)
                                            showMenu = false
                                        }
                                    )
                                    if (state.documents.size > 1) {
                                        DropdownMenuItem(
                                            text = { Text("Delete", color = MaterialTheme.colorScheme.error) },
                                            onClick = {
                                                viewModel.deleteDocument(doc)
                                                showMenu = false
                                            }
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

    if (showNewDocDialog) {
        var docName by remember { mutableStateOf("") }
        var docType by remember { mutableStateOf("Store") }

        AlertDialog(
            onDismissRequest = { showNewDocDialog = false },
            title = { Text("Create New Schema Document") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = docName,
                        onValueChange = { docName = it },
                        label = { Text("Document Name") },
                        placeholder = { Text("e.g. Main Store Markup") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = docType,
                        onValueChange = { docType = it },
                        label = { Text("Schema Type (@type)") },
                        placeholder = { Text("e.g. Store, Product, Person") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.createNewDocument(docType, docName)
                    showNewDocDialog = false
                }) {
                    Text("Create")
                }
            },
            dismissButton = {
                TextButton(onClick = { showNewDocDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}
