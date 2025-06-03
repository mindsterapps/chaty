import 'package:flutter/material.dart';

/// A widget that displays a date divider in a chat, such as "Today", "Yesterday", or a formatted date.
class DateDivider extends StatelessWidget {
  /// The date to display in the divider.

  /// Creates a [DateDivider] widget.
  const DateDivider({
    Key? key,
    required this.label,
  }) : super(key: key);

  /// [label] displays a text in date divider in a chat,
  ///
  ///  such as "Today", "Yesterday", or a formatted date
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
      ),
    );
  }
}
