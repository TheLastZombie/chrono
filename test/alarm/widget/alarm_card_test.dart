import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/alarm/widgets/alarm_card.dart';
import 'package:clock_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as timezone_db;

const testKey = Key('key');
var sampleAlarm = Alarm(const TimeOfDay(hour: 2, minute: 30));

void main() {
  group('AlarmCard', () {
    setUp(
      () async {
        timezone_db.initializeTimeZones();
        sampleAlarm = Alarm(const TimeOfDay(hour: 2, minute: 30));
      },
    );

    testWidgets(
      'shows alarm time correctly',
      (tester) async {
        await renderWidget(tester);

        expect(find.text("2:30"), findsOneWidget);
      },
    );

    testWidgets(
      'shows time period correctly',
      (tester) async {
        await renderWidget(tester);

        expect(find.text("AM"), findsOneWidget);
      },
    );

    group("shows switch correctly", () {
      testWidgets(
        'on enabled alarm',
        (tester) async {
          await renderWidget(tester);
          final finder = find.byWidgetPredicate(
              (widget) => widget is Switch && widget.value == true,
              description: 'Switch is enabled');

          expect(finder, findsOneWidget);
        },
      );

      testWidgets(
        'on disabled alarm',
        (tester) async {
          sampleAlarm.disable();
          await renderWidget(tester);
          final finder = find.byWidgetPredicate(
              (widget) => widget is Switch && widget.value == false,
              description: 'Switch is disabled');

          expect(finder, findsOneWidget);
        },
      );
    });

    group("shows label correctly", () {
      testWidgets(
        'when label is empty',
        (tester) async {
          await renderWidget(tester);
          // final finder = find.byWidgetPredicate(
          //     (widget) => widget is Switch && widget.value == true,
          //     description: 'Switch is enabled');

          // expect(find.text("2:30"), findsOneWidget);
        },
      );
      testWidgets(
        'when label is present',
        (tester) async {
          sampleAlarm.setSettingWithoutNotify("Label", "Test Label");
          await renderWidget(tester);
          expect(find.text("Test Label"), findsOneWidget);
        },
      );
    });
  });
}

Future<void> renderWidget(WidgetTester tester, [Alarm? alarm]) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: defaultTheme,
      home: Scaffold(
        body: AlarmCard(
          alarm: alarm ?? sampleAlarm,
          onEnabledChange: (value) {},
          onPressDelete: () {},
          key: testKey,
        ),
      ),
    ),
  );
  //action
}