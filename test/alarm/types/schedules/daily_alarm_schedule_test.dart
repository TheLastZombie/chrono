import 'package:clock_app/alarm/types/schedules/daily_alarm_schedule.dart';
import 'package:clock_app/common/utils/date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DailyAlarmSchedule schedule = DailyAlarmSchedule();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyAlarmSchedule', () {
    setUp(() {
      schedule = DailyAlarmSchedule();
    });

    test('schedule sets currentScheduleDateTime to correct value', () async {
      const timeOfDay = TimeOfDay(hour: 10, minute: 30);

      bool result = await schedule.schedule(timeOfDay);

      expect(result, true);
      expect(schedule.currentScheduleDateTime?.hour, timeOfDay.hour);
      expect(schedule.currentScheduleDateTime?.minute, timeOfDay.minute);
    });
    group('schedules alarm in the future', () {
      test(
        'when time of day is more than current time of day',
        () async {
          final dateTime = DateTime.now().add(const Duration(minutes: 1));
          final timeOfDay = dateTime.toTimeOfDay();

          bool result = await schedule.schedule(timeOfDay);

          expect(result, true);
          expect(
              schedule.currentScheduleDateTime?.isAfter(DateTime.now()), true);
        },
      );
      test(
        'when time of day is less than current time of day',
        () async {
          final dateTime = DateTime.now().subtract(const Duration(minutes: 1));
          final timeOfDay = dateTime.toTimeOfDay();

          bool result = await schedule.schedule(timeOfDay);

          expect(result, true);
          expect(
              schedule.currentScheduleDateTime?.isAfter(DateTime.now()), true);
        },
      );
    });

    group('cancel', () {
      test(
        'sets currentScheduleDateTime to null',
        () async {
          const timeOfDay = TimeOfDay(hour: 10, minute: 30);

          await schedule.schedule(timeOfDay);
          schedule.cancel();

          expect(schedule.currentScheduleDateTime, null);
        },
      );
    });

    test('isFinished returns false', () {
      expect(schedule.isFinished, false);
    });

    test('isDisabled returns false', () {
      expect(schedule.isDisabled, false);
    });

    test('alarmRunners returns list with one item', () {
      expect(schedule.alarmRunners.length, 1);
    });

    group('hasId()', () {
      test('returns false when id is not in alarmRunners', () {
        expect(schedule.hasId(-1), false);
      });
      test('returns true when id is in alarmRunners', () {
        schedule.schedule(const TimeOfDay(hour: 10, minute: 30));
        expect(schedule.hasId(schedule.currentAlarmRunnerId), true);
      });
    });

    test('toJson() returns correct value', () async {
      const timeOfDay = TimeOfDay(hour: 10, minute: 30);
      await schedule.schedule(timeOfDay);

      expect(schedule.toJson(), {
        'alarmRunner': {
          'id': schedule.currentAlarmRunnerId,
          'currentScheduleDateTime':
              schedule.currentScheduleDateTime?.millisecondsSinceEpoch,
        },
      });
    });

    test('fromJson() creates DailyAlarmSchedule with correct values', () async {
      final scheduleDate = DateTime.now().add(const Duration(minutes: 1));
      final Map<String, dynamic> json = {
        'alarmRunner': {
          'id': 50,
          'currentScheduleDateTime': scheduleDate.millisecondsSinceEpoch,
        },
      };

      final DailyAlarmSchedule scheduleFromJson =
          DailyAlarmSchedule.fromJson(json);

      expect(scheduleFromJson.currentAlarmRunnerId, 50);
      expect(scheduleFromJson.currentScheduleDateTime?.millisecondsSinceEpoch,
          scheduleDate.millisecondsSinceEpoch);
    });
  });
}
