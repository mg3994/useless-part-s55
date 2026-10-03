import 'package:kaisel/kaisel.dart';

sealed class AppRoute extends KaiselRoute {
  const AppRoute();
}

final class EditorRoute extends AppRoute {
  const EditorRoute({this.documentId});
  final String? documentId;

  @override
  List<Object?> get props => [documentId];
}

final class SchemaCatalogRoute extends AppRoute {
  const SchemaCatalogRoute();

  @override
  List<Object?> get props => [];
}

final class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  List<Object?> get props => [];
}
