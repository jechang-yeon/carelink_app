import 'package:flutter/material.dart';

class ShelterFilterBar extends StatelessWidget {
  const ShelterFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.statuses,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.filtersActive,
    required this.onResetFilters,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final List<String> statuses;
  final String selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final bool filtersActive;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> options = statuses.isEmpty ? const <String>['전체'] : statuses;

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (BuildContext context, TextEditingValue value, _) {
              final bool hasText = value.text.isNotEmpty;
              return TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: hasText
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClearSearch,
                  )
                      : null,
                  hintText: '보호소 이름 또는 주소를 검색하세요',
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFFFF7A00)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isNarrow = constraints.maxWidth < 520;
              final Widget dropdown = _StatusDropdown(
                options: options,
                selectedStatus: selectedStatus,
                onStatusChanged: onStatusChanged,
              );
              final Widget resetButton = TextButton.icon(
                onPressed: filtersActive ? onResetFilters : null,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('필터 초기화'),
                style: TextButton.styleFrom(
                  foregroundColor:
                  filtersActive ? theme.colorScheme.primary : theme.disabledColor,
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    dropdown,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: resetButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: dropdown),
                  const SizedBox(width: 12),
                  resetButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.options,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final List<String> options;
  final String selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final List<String> normalizedOptions =
    options.isEmpty ? const <String>['전체'] : options;
    final String value = normalizedOptions.contains(selectedStatus)
        ? selectedStatus
        : normalizedOptions.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: normalizedOptions
              .map(
                (String status) => DropdownMenuItem<String>(
              value: status,
              child: Text(status),
            ),
          )
              .toList(),
          onChanged: onStatusChanged,
        ),
      ),
    );
  }
}

