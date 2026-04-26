import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:teco_app/app.dart';
import 'package:teco_app/features/auth/domain/entities/app_auth_state.dart';
import 'package:teco_app/features/auth/presentation/providers/auth_providers.dart';

class TestAuthController extends AuthController {
  @override
  Future<AppAuthState> build() async {
    return const AppAuthState.unauthenticated();
  }
}

void main() {
  testWidgets('App shows auth shell when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(TestAuthController.new),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.text('Cadastrar'), findsOneWidget);
    expect(find.textContaining('Bem-vindo'), findsOneWidget);
  });
}
