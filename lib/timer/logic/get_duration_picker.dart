import 'package:clock_app/clock/types/time.dart';
import 'package:clock_app/common/utils/date_time.dart';
import 'package:clock_app/common/widgets/spinner_time_picker.dart';
import 'package:clock_app/settings/data/general_settings_schema.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/timer/types/time_duration.dart';
import 'package:clock_app/timer/widgets/dial_duration_picker.dart';
import 'package:flutter/material.dart';

Widget getDurationPicker(BuildContext context, TimeDuration duration,
    void Function(TimeDuration) onDurationChange) {
  Orientation orientation = MediaQuery.of(context).orientation;

  DurationPickerType type = appSettings
      .getGroup("General")
      .getGroup("Display")
      .getSetting("Duration Picker")
      .value;

  Widget picker;

  ThemeData theme = Theme.of(context);
  TextTheme textTheme = theme.textTheme;
  ColorScheme colorScheme = theme.colorScheme;
  var width = MediaQuery.of(context).size.width;


  switch (type) {
    case DurationPickerType.spinner:
      picker = TimePickerSpinner(
        time: duration.toDateTime(),
        is24HourMode: true,
        normalTextStyle: orientation == Orientation.portrait
            ? textTheme.displayMedium
                ?.copyWith(color: colorScheme.onSurface.withOpacity(0.5))
            : textTheme.displaySmall
                ?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
        highlightedTextStyle: orientation == Orientation.portrait
            ? textTheme.displayMedium?.copyWith(color: colorScheme.onSurface)
            : textTheme.displaySmall?.copyWith(color: colorScheme.onSurface),
        // spacing: 50,
        // itemHeight: orientation == Orientation.portrait
        //     ? null
        //     : dialogSize.height / 6,
        isShowSeconds: true,
        isForce2Digits: true,
        onTimeChange: (DateTime time) {
          onDurationChange(time.toTimeDuration());
        },
      );
      break;
    case DurationPickerType.rings:
      picker = SizedBox(
        height: width - 64,
        width: width - 64,
        child: DialDurationPicker(
          duration: duration,
          onChange: (TimeDuration newDuration) {
            onDurationChange(newDuration);
          },
        ),
      );

      break;
  }

  return picker;
}