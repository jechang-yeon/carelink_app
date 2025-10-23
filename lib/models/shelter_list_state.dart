import 'package:carelink_app/models/shelter.dart';

class ShelterListState {
  const ShelterListState({
    required this.shelters,
    required this.availableStatuses,
    required this.totalCount,
    required this.filteredCount,
  });

  const ShelterListState.empty()
      : shelters = const <Shelter>[],
        availableStatuses = const <String>['전체'],
        totalCount = 0,
        filteredCount = 0;

  final List<Shelter> shelters;
  final List<String> availableStatuses;
  final int totalCount;
  final int filteredCount;

  bool get hasShelters => shelters.isNotEmpty;
  bool get hasAnyShelters => totalCount > 0;
  bool get isFiltered => totalCount != filteredCount;
}

