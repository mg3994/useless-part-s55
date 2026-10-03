import 'package:flutter/material.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:kaisel/kaisel.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/bloc/editor_state.dart';
import 'package:stores/routing/routes.dart';
import 'package:stores/theme/app_theme.dart';
import 'package:stores/ui/pages/home_page.dart';
import 'package:stores/ui/pages/schema_catalog_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final editorCubit = EditorCubit();
  await editorCubit.init();

  runApp(
    BlocSignalProvider<EditorCubit>(
      create: (_) => editorCubit,
      child: const JsonLdStudioApp(),
    ),
  );
}

class JsonLdStudioApp extends StatefulWidget {
  const JsonLdStudioApp({super.key});

  @override
  State<JsonLdStudioApp> createState() => _JsonLdStudioAppState();
}

class _JsonLdStudioAppState extends State<JsonLdStudioApp> {
  late final KaiselRouterConfig<AppRoute> _routerConfig;

  @override
  void initState() {
    super.initState();
    _routerConfig = KaiselRouterConfig<AppRoute>(
      initial: const EditorRoute(),
      builder: (context, route) => switch (route) {
        EditorRoute() => const HomePage(),
        SchemaCatalogRoute() => SchemaCatalogPage(
            cubit: context.read<EditorCubit>(),
          ),
        SettingsRoute() => const HomePage(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSignalBuilder<EditorCubit, EditorState>(
      builder: (context, state) {
        return MaterialApp.router(
          title: 'JSON-LD Studio • Schema.org Visual Editor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: _routerConfig,
        );
      },
    );
  }
}
