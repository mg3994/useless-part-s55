import 'package:flutter/material.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:kaisel/kaisel.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/bloc/editor_state.dart';
import 'package:stores/routing/routes.dart';
import 'package:stores/ui/components/card_form_view.dart';
import 'package:stores/ui/components/jsonld_preview_pane.dart';
import 'package:stores/ui/components/markup_sidebar.dart';
import 'package:stores/ui/components/miller_columns_view.dart';
import 'package:stores/ui/components/tree_view.dart';
import 'package:stores/ui/components/workspace_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSignalBuilder<EditorCubit, EditorState>(
      builder: (context, state) {
        final cubit = context.read<EditorCubit>();
        final currentDoc = state.currentDocument;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1050;

            if (isDesktop) {
              return Scaffold(
                body: Row(
                  children: [
                    // Left 1st Pane: Active Markups
                    MarkupSidebar(
                      cubit: cubit,
                      state: state,
                      onOpenCatalog: () {
                        context.router<AppRoute>().push(const SchemaCatalogRoute());
                      },
                    ),

                    // Center 2nd Pane: Workspace
                    Expanded(
                      child: Column(
                        children: [
                          if (currentDoc != null)
                            WorkspaceHeader(
                              cubit: cubit,
                              state: state,
                              document: currentDoc,
                            ),
                          Expanded(
                            child: currentDoc == null
                                ? const Center(child: Text('No Document Selected'))
                                : _buildWorkspaceView(cubit, state, currentDoc),
                          ),
                        ],
                      ),
                    ),

                    // Right 3rd Pane: Live JSON-LD
                    JsonLdPreviewPane(code: state.jsonLdOutput),
                  ],
                ),
              );
            }

            // Mobile / Tablet Tabbed Layout
            return Scaffold(
              body: IndexedStack(
                index: state.activeMobileTab,
                children: [
                  MarkupSidebar(
                    cubit: cubit,
                    state: state,
                    onOpenCatalog: () {
                      context.router<AppRoute>().push(const SchemaCatalogRoute());
                    },
                  ),
                  Column(
                    children: [
                      if (currentDoc != null)
                        WorkspaceHeader(
                          cubit: cubit,
                          state: state,
                          document: currentDoc,
                        ),
                      Expanded(
                        child: currentDoc == null
                            ? const Center(child: Text('No Document Selected'))
                            : _buildWorkspaceView(cubit, state, currentDoc),
                      ),
                    ],
                  ),
                  JsonLdPreviewPane(code: state.jsonLdOutput),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: state.activeMobileTab,
                onDestinationSelected: (idx) => cubit.setActiveMobileTab(idx),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.folder_outlined),
                    selectedIcon: Icon(Icons.folder),
                    label: 'Markups',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.edit_note_outlined),
                    selectedIcon: Icon(Icons.edit_note),
                    label: 'Workspace',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.code_outlined),
                    selectedIcon: Icon(Icons.code),
                    label: 'JSON-LD',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkspaceView(
    EditorCubit cubit,
    EditorState state,
    dynamic currentDoc,
  ) {
    switch (state.viewMode) {
      case WorkspaceViewMode.columns:
        return MillerColumnsView(cubit: cubit, rootEntity: currentDoc);
      case WorkspaceViewMode.tree:
        return SchemaTreeView(cubit: cubit, rootEntity: currentDoc);
      case WorkspaceViewMode.cards:
        return CardFormView(cubit: cubit, rootEntity: currentDoc);
    }
  }
}
