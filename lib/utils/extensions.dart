import 'dart:developer' as d;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  String replaceCharAt(int index, String newChar) {
    return substring(0, index) + newChar + substring(index + 1);
  }

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

  bool isImageExtenstion(
      {List<String> imgExt = const <String>['png', 'jpg', 'jpeg', 'gif']}) {
    if (!contains('.')) return false;

    final ext = substring(lastIndexOf('.') + 1).toString();
    return imgExt.contains(ext);
  }
}

extension Str on int {
  String toOrdinal() {
    /// TODO: extend range, not accurate after 100
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

extension Dob on double {
  String removeZero() {
    RegExp regex = RegExp(r'([.]*0)(?!.*\d)');

    String s = toString().replaceAll(regex, '');
    return s;
  }

  double formatToTwoDecimalPlaces() {
    return (this * 100).round() / 100;
  }
}

extension WrapIt on Widget {
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

extension Logger<E> on E {
  E log([String key = '@']) {
    d.log('$key:${toString()}');
    return this;
  }
}

extension DateHelpers on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }

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

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = Set();
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}
