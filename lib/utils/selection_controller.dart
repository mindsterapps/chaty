import 'package:flutter/material.dart';

class SelectedController extends ValueNotifier<List> {
  SelectedController() : super([]);

  void selectAll(List items) {
    value = items;
    notifyListeners();
  }

  void clearSelection() {
    value = [];
    notifyListeners();
  }

  bool isSelected(String id) {
    return value.contains(id);
  }

  void toggleSelection(String id) {
    if (value.contains(id)) {
      value.remove(id);
    } else {
      value.add(id);
    }
    notifyListeners();
  }

  void remove(String id) {
    value.remove(id);
    notifyListeners();
  }

  void add(String id) {
    value.add(id);
    notifyListeners();
  }

  void removeAll() {
    value = [];
    notifyListeners();
  }

  void addAll(List ids) {
    value.addAll(ids);
    notifyListeners();
  }
}
