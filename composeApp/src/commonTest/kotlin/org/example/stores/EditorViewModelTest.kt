package org.example.stores

import com.russhwolf.settings.Settings
import org.example.stores.viewmodel.EditorViewModel
import org.example.stores.viewmodel.WorkspaceViewMode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class EditorViewModelTest {

    @Test
    fun testInitialStateAndDocumentOperations() {
        val settings = Settings()
        val viewModel = EditorViewModel(settings = settings)

        val state = viewModel.state.value
        assertEquals(1, state.documents.size)
        assertNotNull(state.currentDocument)
        assertEquals("schema:Store", state.currentDocument?.type)

        viewModel.createNewDocument("schema:Product", "My Product Document")
        val updatedState = viewModel.state.value
        assertEquals(2, updatedState.documents.size)
        assertEquals(1, updatedState.selectedDocumentIndex)
        assertEquals("schema:Product", updatedState.currentDocument?.type)
        assertEquals("My Product Document", updatedState.currentDocument?.name)

        viewModel.addPropertyToEntity(updatedState.currentDocument!!, "schema:price", 199.99)
        val docWithProp = viewModel.state.value.currentDocument!!
        assertEquals(1, docWithProp.properties["schema:price"]?.size)
        assertEquals(199.99, docWithProp.properties["schema:price"]?.first()?.value)

        viewModel.setViewMode(WorkspaceViewMode.CARD_FORM)
        assertEquals(WorkspaceViewMode.CARD_FORM, viewModel.state.value.viewMode)

        val initialDark = viewModel.state.value.isDarkMode
        viewModel.toggleDarkMode()
        assertEquals(!initialDark, viewModel.state.value.isDarkMode)
    }
}
