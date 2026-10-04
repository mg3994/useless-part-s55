package org.example.stores

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import org.example.stores.ui.*
import org.example.stores.viewmodel.EditorState
import org.example.stores.viewmodel.EditorViewModel
import org.example.stores.viewmodel.WorkspaceViewMode

@Composable
fun App(
    viewModel: EditorViewModel = viewModel { EditorViewModel() }
) {
    val state by viewModel.state.collectAsState()
    var currentScreen by remember { mutableStateOf("editor") }

    MaterialTheme(
        colorScheme = if (state.isDarkMode) darkColorScheme() else lightColorScheme()
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
                val isMobile = maxWidth < 600.dp

                if (currentScreen == "catalog") {
                    SchemaCatalogPage(
                        viewModel = viewModel,
                        onBack = { currentScreen = "editor" }
                    )
                } else {
                    val doc = state.currentDocument

                    Column(modifier = Modifier.fillMaxSize()) {
                        if (doc != null) {
                            WorkspaceHeader(
                                viewModel = viewModel,
                                state = state,
                                document = doc,
                                isMobile = isMobile
                            )
                        }

                        if (isMobile) {
                            Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
                                when (state.activeMobileTab) {
                                    0 -> MarkupSidebar(viewModel = viewModel, state = state, modifier = Modifier.fillMaxSize())
                                    1 -> {
                                        if (doc != null) {
                                            when (state.viewMode) {
                                                WorkspaceViewMode.MILLER_COLUMNS -> MillerColumnsView(viewModel = viewModel, rootEntity = doc)
                                                WorkspaceViewMode.TREE -> SchemaTreeView(viewModel = viewModel, rootEntity = doc)
                                                WorkspaceViewMode.CARD_FORM -> CardFormView(viewModel = viewModel, rootEntity = doc)
                                            }
                                        }
                                    }
                                    2 -> JsonLdPreviewPane(state = state, modifier = Modifier.fillMaxSize())
                                    3 -> SchemaCatalogPage(viewModel = viewModel, onBack = { viewModel.setActiveMobileTab(0) })
                                }
                            }

                            NavigationBar {
                                NavigationBarItem(
                                    selected = state.activeMobileTab == 0,
                                    onClick = { viewModel.setActiveMobileTab(0) },
                                    icon = { Icon(Icons.Default.List, contentDescription = "Documents") },
                                    label = { Text("Docs") }
                                )
                                NavigationBarItem(
                                    selected = state.activeMobileTab == 1,
                                    onClick = { viewModel.setActiveMobileTab(1) },
                                    icon = { Icon(Icons.Default.Edit, contentDescription = "Editor") },
                                    label = { Text("Editor") }
                                )
                                NavigationBarItem(
                                    selected = state.activeMobileTab == 2,
                                    onClick = { viewModel.setActiveMobileTab(2) },
                                    icon = { Icon(Icons.Default.Menu, contentDescription = "JSON-LD") },
                                    label = { Text("JSON-LD") }
                                )
                                NavigationBarItem(
                                    selected = state.activeMobileTab == 3,
                                    onClick = { viewModel.setActiveMobileTab(3) },
                                    icon = { Icon(Icons.Default.Search, contentDescription = "Catalog") },
                                    label = { Text("Catalog") }
                                )
                            }
                        } else {
                            Row(modifier = Modifier.weight(1f).fillMaxWidth()) {
                                MarkupSidebar(viewModel = viewModel, state = state)

                                Box(modifier = Modifier.weight(1f).fillMaxHeight()) {
                                    if (doc != null) {
                                        when (state.viewMode) {
                                            WorkspaceViewMode.MILLER_COLUMNS -> MillerColumnsView(viewModel = viewModel, rootEntity = doc)
                                            WorkspaceViewMode.TREE -> SchemaTreeView(viewModel = viewModel, rootEntity = doc)
                                            WorkspaceViewMode.CARD_FORM -> CardFormView(viewModel = viewModel, rootEntity = doc)
                                        }
                                    }
                                }

                                JsonLdPreviewPane(state = state)
                            }
                        }
                    }
                }
            }
        }
    }
}
