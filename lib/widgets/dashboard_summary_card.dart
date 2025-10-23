import 'package:carelink_app/models/animal_statistics.dart';
import 'package:carelink_app/models/shelter_list_state.dart';
import 'package:carelink_app/services/animal_statistics_service.dart';
import 'package:carelink_app/services/shelter_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardSummaryCard extends StatelessWidget {
  DashboardSummaryCard({
    super.key,
    this.padding = const EdgeInsets.all(24.0),
    this.title = '운영 현황',
    this.description,
    this.emptyMessage = '아직 등록된 보호소가 없습니다. 새로운 보호소를 추가해보세요.',
    this.metricTileMinWidth = 220,
    this.maxColumns = 3,
    ShelterService? shelterService,
    AnimalStatisticsService? animalStatisticsService,
  })  : assert(metricTileMinWidth > 0, 'metricTileMinWidth는 0보다 커야 합니다.'),
        assert(maxColumns > 0, 'maxColumns는 0보다 커야 합니다.'),
        assert(title.trim().isNotEmpty, 'title은 비어 있을 수 없습니다.'),
        _shelterService = shelterService ?? ShelterService(),
        _animalStatisticsService =
            animalStatisticsService ?? AnimalStatisticsService();

  final ShelterService _shelterService;
  final AnimalStatisticsService _animalStatisticsService;
  final EdgeInsetsGeometry padding;
  final String title;
  final String? description;
  final String? emptyMessage;
  final double metricTileMinWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: padding,
        child: StreamBuilder<ShelterListState>(
          stream: _shelterService.watchShelters(),
          builder: (
              BuildContext context,
              AsyncSnapshot<ShelterListState> shelterSnapshot,
              ) {
            final bool shelterLoading =
                shelterSnapshot.connectionState == ConnectionState.waiting &&
                    !shelterSnapshot.hasData;
            final ShelterListState shelterState =
                shelterSnapshot.data ?? const ShelterListState.empty();

            return StreamBuilder<AnimalStatistics>(
              stream: _animalStatisticsService.watchAnimalStatistics(),
              builder: (
                  BuildContext context,
                  AsyncSnapshot<AnimalStatistics> animalSnapshot,
                  ) {
                final bool animalLoading =
                    animalSnapshot.connectionState == ConnectionState.waiting &&
                        !animalSnapshot.hasData;
                final AnimalStatistics statistics =
                    animalSnapshot.data ?? const AnimalStatistics.empty();

                final bool isLoading = shelterLoading || animalLoading;
                final bool hasError =
                    shelterSnapshot.hasError || animalSnapshot.hasError;
                final Object? error =
                    shelterSnapshot.error ?? animalSnapshot.error;
                final bool hasAnyData =
                    shelterSnapshot.hasData || animalSnapshot.hasData;

                return _SummaryContent(
                  theme: theme,
                  isLoading: isLoading,
                  shelterState: shelterState,
                  statistics: statistics,
                  error: hasError ? error : null,
                  canShowMetrics: !hasError || hasAnyData,
                  title: title,
                  description: description,
                  emptyMessage: emptyMessage,
                  metricTileMinWidth: metricTileMinWidth,
                  maxColumns: maxColumns,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.theme,
    required this.isLoading,
    required this.shelterState,
    required this.statistics,
    required this.canShowMetrics,
    required this.title,
    required this.metricTileMinWidth,
    required this.maxColumns,
    this.error,
    this.description,
    this.emptyMessage,
  });

  final ThemeData theme;
  final bool isLoading;
  final ShelterListState shelterState;
  final AnimalStatistics statistics;
  final bool canShowMetrics;
  final Object? error;
  final String title;
  final String? description;
  final String? emptyMessage;
  final double metricTileMinWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = theme.textTheme;
    final String titleText = title.trim();
    final String? descriptionContent = _normalizeText(description);
    final Color descriptionColor = theme.colorScheme.onSurfaceVariant
        .withValues(alpha: theme.brightness == Brightness.dark ? 0.85 : 0.7);
    final TextStyle? descriptionStyle = descriptionContent != null
        ? textTheme.bodyMedium?.copyWith(
      color: descriptionColor,
    )
        : null;

    final int statusCount = shelterState.availableStatuses
        .where((String status) => status != '전체')
        .length;

    final NumberFormat formatter = NumberFormat.decimalPattern('ko_KR');
    String formatShelter(int value) => '${formatter.format(value)}곳';
    String formatAnimal(int value) => '${formatter.format(value)}마리';

    final List<_MetricData> metrics = <_MetricData>[
      _MetricData(
        icon: Icons.home_outlined,
        iconColor: theme.colorScheme.primary,
        label: '등록된 보호소',
        value: formatShelter(shelterState.totalCount),
      ),
      _MetricData(
        icon: Icons.fact_check_outlined,
        iconColor: theme.colorScheme.secondary,
        label: '운영 상태 종류',
        value: '${formatter.format(statusCount)}개',
      ),
      _MetricData(
        icon: Icons.pets_outlined,
        iconColor: theme.colorScheme.tertiary,
        label: '전체 보호 동물',
        value: formatAnimal(statistics.total),
      ),
      _MetricData(
        icon: Icons.cruelty_free_outlined,
        iconColor: theme.colorScheme.primaryContainer,
        label: '강아지',
        value: formatAnimal(statistics.dogs),
      ),
      _MetricData(
        icon: Icons.pets,
        iconColor: theme.colorScheme.secondaryContainer,
        label: '고양이',
        value: formatAnimal(statistics.cats),
      ),
      _MetricData(
        icon: Icons.emoji_nature_outlined,
        iconColor: theme.colorScheme.errorContainer,
        label: '기타 동물',
        value: formatAnimal(statistics.others),
      ),
    ];

    final String? resolvedEmptyMessage = (!isLoading &&
        shelterState.totalCount == 0 &&
        error == null)
        ? _normalizeText(emptyMessage)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (descriptionContent != null && descriptionStyle != null) ...[
          const SizedBox(height: 4),
          Text(
            descriptionContent,
            style: descriptionStyle,
          ),
        ],
        const SizedBox(height: 24),
        if (isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 24),
        ],
        if (error != null) ...[
          _SummaryError(
            title: '요약 정보를 불러오는 중 오류가 발생했습니다.',
            detail: error.toString(),
          ),
          const SizedBox(height: 24),
        ],
        if (resolvedEmptyMessage != null) ...[
          _SummaryEmptyState(
            message: resolvedEmptyMessage,
          ),
          if (canShowMetrics) const SizedBox(height: 24),
        ],
        if (canShowMetrics)
          _MetricsGrid(
            metrics: metrics,
            minTileWidth: metricTileMinWidth,
            maxColumns: maxColumns,
          ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.metrics,
    required this.minTileWidth,
    required this.maxColumns,
  });

  final List<_MetricData> metrics;
  final double minTileWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double availableWidth = constraints.maxWidth;
        if (!availableWidth.isFinite || availableWidth <= 0) {
          availableWidth = MediaQuery.of(context).size.width;
        }

        int columns = availableWidth ~/ minTileWidth;
        if (columns < 1) {
          columns = 1;
        } else if (columns > maxColumns) {
          columns = maxColumns;
        }

        final double spacing = 16.0;
        final double itemWidth = columns == 1
            ? availableWidth
            : (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 16.0,
          children: metrics
              .map(
                (_MetricData data) => SizedBox(
              width: itemWidth,
              child: _SummaryMetric(data: data),
            ),
          )
              .toList(),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color iconColor = data.iconColor ?? theme.colorScheme.primary;
    final Color backgroundColor = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.6);
    final Color valueColor = theme.colorScheme.onSurface;
    final Color labelColor = theme.colorScheme.onSurfaceVariant
        .withValues(alpha: theme.brightness == Brightness.dark ? 0.9 : 0.75);

    return Semantics(
      label: data.label,
      value: data.value,
      child: Tooltip(
        message: '${data.label} • ${data.value}',
        waitDuration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(data.icon, size: 28, color: iconColor),
              const SizedBox(height: 12),
              Text(
                data.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.title, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background = theme.colorScheme.errorContainer;
    final Color foreground = theme.colorScheme.onErrorContainer;
    final String? detailText = detail?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detailText != null && detailText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryEmptyState extends StatelessWidget {
  const _SummaryEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: theme.brightness == Brightness.dark ? 0.45 : 0.75);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
}

String? _normalizeText(String? value) {
  if (value == null) {
    return null;
  }

  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}





