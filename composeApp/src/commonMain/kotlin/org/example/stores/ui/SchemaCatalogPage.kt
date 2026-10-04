package org.example.stores.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.example.stores.services.SchemaService
import org.example.stores.viewmodel.EditorViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SchemaCatalogPage(
    viewModel: EditorViewModel,
    onBack: () -> Unit,
    schemaService: SchemaService = SchemaService.instance,
    modifier: Modifier = Modifier
) {
    var searchQuery by remember { mutableStateOf("") }
    val allClasses = remember(schemaService.classes) { schemaService.classes.values.toList() }

    val filtered = allClasses.filter {
        searchQuery.isBlank() ||
                it.label.contains(searchQuery, ignoreCase = true) ||
                it.comment.contains(searchQuery, ignoreCase = true)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Schema.org Catalog") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        },
        modifier = modifier.fillMaxSize()
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Search Schema.org types (e.g., Store, Product, Article)...") },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)
            )

            LazyVerticalGrid(
                columns = GridCells.Adaptive(minSize = 280.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.weight(1f)
            ) {
                items(filtered) { cls ->
                    ElevatedCard(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                viewModel.createNewDocument(cls.id, "${cls.label} Document")
                                onBack()
                            }
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = cls.label,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Icon(
                                    Icons.Default.Add,
                                    contentDescription = "Create Document",
                                    tint = MaterialTheme.colorScheme.primary
                                )
                            }
                            if (cls.subClassOf.isNotEmpty()) {
                                Text(
                                    text = "Subclass of: ${cls.subClassOf.joinToString { it.removePrefix("schema:") }}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = cls.comment.ifEmpty { "Schema.org entity class." },
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.outline,
                                maxLines = 3
                            )
                        }
                    }
                }
            }
        }
    }
}
