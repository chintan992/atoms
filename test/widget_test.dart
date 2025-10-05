// This is a basic Flutter widget test for the Atmos Weather App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:atmos/providers/weather_provider.dart';
import 'package:atmos/providers/settings_provider.dart';

void main() {
  testWidgets('Atmos Weather App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => WeatherProvider()),
          ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Atmos Weather App'),
            ),
          ),
        ),
      ),
    );

    // Verify that our app title is displayed.
    expect(find.text('Atmos Weather App'), findsOneWidget);
  });
}
