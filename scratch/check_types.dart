import 'package:kaisel/kaisel.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:stores/bloc/editor_cubit.dart';
import 'package:stores/routing/routes.dart';

void main() {
  final cubit = EditorCubit();
  print('cubit.state type: ${cubit.state.runtimeType}');
  print('cubit.state.value type: ${cubit.state.value.runtimeType}');

  // Check KaiselRouter methods via reflection or dummy usage
  final config = KaiselRouterConfig<AppRoute>(
    initial: const EditorRoute(),
    builder: (context, route) => throw UnimplementedError(),
  );
  print('Config: ${config.runtimeType}');
}
