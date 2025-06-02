import 'dart:developer' as d;
import 'package:flutter/material.dart';

/// Extension methods for String to provide utility functions.
extension StringExtension on String {
  /// Append the svg location to the string
  String asAssetSvg() => 'assets/svgs/$this.svg';

  /// Append the image location to the string
  String asAssetImg() => 'assets/images/$this';

  /// Append the gif location to the string
  String asAssetGif() => 'assets/gifs/$this';

  ///
  ///capitalize first letter of every word
  String capitalizeAllWord() {
    var result = this[0].toUpperCase();
    for (int i = 1; i < length; i++) {
      if (this[i - 1] == " ") {
        result = result + this[i].toUpperCase();
      } else {
        result = result + this[i].toLowerCase();
      }
    }
    return result;
  }

  /// Replaces the character at the specified [index] in the string with [newChar].
  ///
  /// Returns a new string with the character at [index] replaced by [newChar].
  ///
  /// Throws a [RangeError] if [index] is out of bounds.
  ///
  /// Example:
  /// ```dart
  /// 'hello'.replaceCharAt(1, 'a'); // returns 'hallo'
  /// ```
  String replaceCharAt(int index, String newChar) {
    return substring(0, index) + newChar + substring(index + 1);
  }

  /// Converts the string to a double, or returns null if conversion fails.
  double? toDouble() {
    try {
      if (isEmpty) {
        return null;
      }
      return double.parse(this);
    } catch (ex) {
      debugPrint(ex.toString());
      return null;
    }
  }

  /// Checks if the string has an image file extension.
  ///
  /// [imgExt] is the list of valid image extensions.
  bool isImageExtenstion(
      {List<String> imgExt = const <String>['png', 'jpg', 'jpeg', 'gif']}) {
    if (!contains('.')) return false;

    final ext = substring(lastIndexOf('.') + 1).toString();
    return imgExt.contains(ext);
  }
}

/// Extension methods for int to provide ordinal string conversion.
extension Str on int {
  /// Converts the integer to its ordinal representation (e.g., 1st, 2nd).
  String toOrdinal() {
    if (this < 0) throw Exception('Invalid Number');
    if (this >= 11 && this <= 13) {
      return '${this}th';
    }
    switch (this % 10) {
      case 1:
        return '$this st';
      case 2:
        return '$this nd';
      case 3:
        return '$this rd';
      default:
        return '$this th';
    }
  }
}

/// Extension methods for double to provide formatting utilities.
extension Dob on double {
  /// Removes trailing zeros from a double's string representation.
  String removeZero() {
    RegExp regex = RegExp(r'([.]*0)(?!.*\d)');

    String s = toString().replaceAll(regex, '');
    return s;
  }

  /// Formats the double to two decimal places.
  double formatToTwoDecimalPlaces() {
    return (this * 100).round() / 100;
  }
}

/// Extension methods for Widget to wrap it in a Container with optional size and alignment.
extension WrapIt on Widget {
  /// Wraps the widget in a [Container] with optional [height], [width], and [alignment].
  Widget box({
    double? height,
    double? width,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Container(
      height: height,
      width: width,
      alignment: alignment,
      child: this,
    );
  }
}

/// Extension for logging any object with an optional key.
extension Logger<E> on E {
  /// Logs the object with an optional [key] and returns the object.
  E log([String key = '@']) {
    d.log('$key:${toString()}');
    return this;
  }
}

/// Extension methods for DateTime to provide date helpers.
extension DateHelpers on DateTime {
  /// Returns true if the date is today.
  bool get isToday {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  /// Returns true if the date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }

  /// Returns a human-readable string representing the time elapsed since this date.
  String timeAgo({bool numericDates = true}) {
    final date2 = DateTime.now();
    final difference = date2.difference(this);

    if ((difference.inDays / 7).floor() >= 1) {
      return (numericDates) ? '1 week ago' : 'Last week';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }
}

/// An extension on [List] that provides functionality for handling unique elements
/// based on a specified identifier type [Id].
///
/// This extension can be used to add utility methods for extracting or filtering
/// unique elements from a list, where uniqueness is determined by a property or
/// identifier of type [Id].
///
/// Type Parameters:
/// - [E]: The type of elements in the list.
/// - [Id]: The type used to determine uniqueness (e.g., a field or property of [E]).
///
/// Example usage:
/// ```dart
/// final users = [User(id: 1), User(id: 2), User(id: 1)];
/// final uniqueUsers = users.uniqueBy((user) => user.id);
/// ```
extension Unique<E, Id> on List<E> {
  /// Returns a new list containing unique elements based on the provided [id] function.
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = Set();
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}
