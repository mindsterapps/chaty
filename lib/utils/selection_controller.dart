import 'package:flutter/material.dart';

/// Controller for managing a list of selected items, typically used for selection state in UI components.
class SelectedController extends ValueNotifier<List> {
  /// Creates a [SelectedController] with an empty selection.
  SelectedController() : super([]);

  /// Selects all items in the provided [items] list.
  void selectAll(List items) {
    value = items;
    notifyListeners();
  }

  /// Clears the current selection.
  void clearSelection() {
    value = [];
    notifyListeners();
  }

  /// Returns true if the item with the given [id] is selected.
  bool isSelected(String id) {
    return value.contains(id);
  }

  /// Toggles the selection state of the item with the given [id].
  void toggleSelection(String id) {
    if (value.contains(id)) {
      value.remove(id);
    } else {
      value.add(id);
    }
    notifyListeners();
  }

  /// Removes the item with the given [id] from the selection.
  void remove(String id) {
    value.remove(id);
    notifyListeners();
  }

  /// Adds the item with the given [id] to the selection.
  void add(String id) {
    value.add(id);
    notifyListeners();
  }

  /// Removes all items from the selection.
  void removeAll() {
    value = [];
    notifyListeners();
  }

  /// Adds all items in the provided [ids] list to the selection.
  void addAll(List ids) {
    value.addAll(ids);
    notifyListeners();
  }
}
