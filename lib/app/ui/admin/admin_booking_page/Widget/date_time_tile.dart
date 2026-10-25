import 'package:flutter/material.dart';

const _primary = Color(0xFF003399);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Date + time picker tile: tap the date side for a calendar,
/// tap the time pill for a clock. Both dialogs use the app colours.
class DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateTimeTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  Widget _themed(BuildContext context, Widget? child) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: _primary,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: _ink,
        ),
        dialogBackgroundColor: Colors.white,
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          headerBackgroundColor: _primary,
          headerForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primary),
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final first = firstDate ?? DateTime.now().subtract(const Duration(days: 1));
    final d = await showDatePicker(
      context: context,
      initialDate: value.isBefore(first) ? first : value,
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: _themed,
    );
    if (d == null) return;
    onChanged(DateTime(d.year, d.month, d.day, value.hour, value.minute));
  }

  Future<void> _pickTime(BuildContext context) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      builder: _themed,
    );
    if (t == null) return;
    onChanged(DateTime(value.year, value.month, value.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_weekdays[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]} ${value.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(context),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateText,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 36, color: _border),
          InkWell(
            onTap: () => _pickTime(context),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 16, color: _primary),
                  const SizedBox(width: 6),
                  Text(
                    TimeOfDay.fromDateTime(value).format(context),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}