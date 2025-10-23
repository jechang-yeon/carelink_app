import 'package:carelink_app/models/animal_statistics.dart';
import 'package:carelink_app/models/shelter.dart';
import 'package:carelink_app/models/shelter_list_state.dart';
import 'package:carelink_app/models/staff_model.dart';
import 'package:carelink_app/screens/admin/staff_management_screen.dart';
import 'package:carelink_app/screens/auth/login_screen.dart';
import 'package:carelink_app/screens/logs/activity_log_screen.dart';
import 'package:carelink_app/screens/shelter/add_shelter_screen.dart';
import 'package:carelink_app/screens/shelter/edit_shelter_screen.dart';
import 'package:carelink_app/screens/shelter/shelter_detail_screen.dart';
import 'package:carelink_app/services/animal_statistics_service.dart';
import 'package:carelink_app/services/shelter_service.dart';
import 'package:carelink_app/widgets/delete_confirmation_dialog.dart';
import 'package:carelink_app/widgets/responsive_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final StaffModel user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _desktopSelectedIndex = 0;
  final ShelterService _shelterService = ShelterService();
  final AnimalStatisticsService _animalStatisticsService =
  AnimalStatisticsService();

  Future<void> _deleteShelter(BuildContext context, Shelter shelter) async {
    try {
      await _shelterService.deleteShelterWithAnimals(shelter);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${shelter.name} 보호소 정보가 삭제되었습니다.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(context),
      desktopBody: _buildDesktopLayout(context),
    );
  }

  Scaffold _buildMobileLayout(BuildContext context) {
    final Color titleColor = _resolveDashboardTitleColor(context);
    final double baseIconSize = Theme.of(context).iconTheme.size ?? 24;
    final double scaledIconSize = baseIconSize * 1.2;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: kToolbarHeight + 20.0,
        iconTheme: IconThemeData(color: titleColor, size: scaledIconSize),
        actionsIconTheme:
        IconThemeData(color: titleColor, size: scaledIconSize),
        title: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: _buildDashboardAppBarTitle(context),
        ),
        actions: _buildAppBarActions(context),
      ),
      body: _buildDashboardContent(),
      floatingActionButton: (widget.user.role == 'SystemAdmin' ||
          widget.user.role == 'AreaManager')
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddShelterScreen(),
            ),
          );
        },
        tooltip: '신규 보호소 개설',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Scaffold _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _desktopSelectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _desktopSelectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Icon(Icons.pets, size: 40, color: Color(0xFFFF7A00)),
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('대시보드'),
              ),
              if (widget.user.role == 'SystemAdmin')
                const NavigationRailDestination(
                  icon: Icon(Icons.manage_accounts_outlined),
                  selectedIcon: Icon(Icons.manage_accounts),
                  label: Text('직원 관리'),
                ),
              const NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('활동 기록'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _signOut(context),
                    tooltip: '로그아웃',
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildDesktopContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardAppBarTitle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle = theme.appBarTheme.titleTextStyle ??
        theme.textTheme.titleLarge ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
    final double baseFontSize = baseStyle.fontSize ?? 20;
    final double scaledFontSize = baseFontSize * 1.5;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'CareLink\n',
            style: baseStyle.copyWith(
              fontSize: scaledFontSize,
              fontWeight: FontWeight.w300,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: 'Dashboard',
            style: baseStyle.copyWith(
              fontSize: scaledFontSize,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveDashboardTitleColor(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle = theme.appBarTheme.titleTextStyle ??
        theme.textTheme.titleLarge ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
    return baseStyle.color ?? theme.colorScheme.onSurface;
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    const EdgeInsets padding = EdgeInsets.only(top: 12.0);
    return [
      if (widget.user.role == 'SystemAdmin')
        Padding(
          padding: padding,
          child: IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const StaffManagementScreen()),
              );
            },
            tooltip: '직원 관리',
          ),
        ),
      Padding(
        padding: padding,
        child: IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ActivityLogScreen(),
              ),
            );
          },
          tooltip: '전체 활동 기록',
        ),
      ),
      Padding(
        padding: padding,
        child: IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () => _signOut(context),
          tooltip: '로그아웃',
        ),
      ),
    ];
  }

  Widget _buildDesktopContent() {
    int adjustedIndex = _desktopSelectedIndex;
    if (widget.user.role != 'SystemAdmin' && _desktopSelectedIndex > 0) {
      adjustedIndex = _desktopSelectedIndex + 1;
    }

    switch (adjustedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const StaffManagementScreen();
      case 2:
        return const ActivityLogScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildProtectionOverviewSection(context),
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '보호소 목록',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<ShelterListState>(
            stream: _shelterService.watchShelters(),
            builder: (context, snapshot) {
              final bool isInitialLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData;
              final ShelterListState state =
                  snapshot.data ?? const ShelterListState.empty();

              Widget listContent;
              if (snapshot.hasError) {
                listContent = Center(
                  child: Text(
                    '데이터를 불러오는 중 오류가 발생했습니다: ${snapshot.error}',
                  ),
                );
              } else if (isInitialLoading) {
                listContent = const Center(child: CircularProgressIndicator());
              } else if (!state.hasShelters) {
                listContent = const Center(
                  child: Text('등록된 보호소가 없습니다.'),
                );
              } else {
                listContent = ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                  itemCount: state.shelters.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final shelter = state.shelters[index];
                    final bool canManage = widget.user.role == 'SystemAdmin' ||
                        widget.user.role == 'AreaManager';
                    final String addressLine = [
                      shelter.address.trim(),
                      shelter.addressDetail.trim(),
                    ].where((segment) => segment.isNotEmpty).join(' ');
                    final String managerUid = shelter.managerUid.trim();
                    final String managerContact =
                    shelter.managerContact.trim();
                    final List<String> managerSegments = [
                      if (managerUid.isNotEmpty) '관리자 UID $managerUid',
                      if (managerContact.isNotEmpty)
                        '연락처 $managerContact',
                    ];
                    final String managerLine = managerSegments.join(' · ');

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShelterDetailScreen(
                              user: widget.user,
                              shelter: shelter,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFFF7A00),
                              child: Icon(Icons.home, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shelter.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (addressLine.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(addressLine),
                                  ],
                                  if (managerLine.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(managerLine),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            canManage
                                ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'view') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ShelterDetailScreen(
                                            user: widget.user,
                                            shelter: shelter,
                                          ),
                                    ),
                                  );
                                } else if (value == 'edit') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditShelterScreen(
                                            shelter: shelter,
                                          ),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        DeleteConfirmationDialog(
                                          title: '보호소 삭제',
                                          content:
                                          '정말로 ${shelter.name} 보호소를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
                                          onConfirm: () =>
                                              _deleteShelter(
                                                  context, shelter),
                                        ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: ListTile(
                                    leading:
                                    Icon(Icons.visibility_outlined),
                                    title: Text('상세 보기'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('정보 수정'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    title: Text(
                                      '보호소 삭제',
                                      style: TextStyle(
                                          color: Colors.red.shade700),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              return listContent;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProtectionOverviewSection(BuildContext context) {
    return StreamBuilder<AnimalStatistics>(
      stream: _animalStatisticsService.watchAnimalStatistics(),
      builder: (context, snapshot) {
        final ThemeData theme = Theme.of(context);
        final TextTheme textTheme = theme.textTheme;
        final NumberFormat formatter = NumberFormat.decimalPattern('ko_KR');
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;
        final bool hasError = snapshot.hasError;
        final AnimalStatistics statistics =
            snapshot.data ?? const AnimalStatistics.empty();

        String formatCount(int value) => formatter.format(value);

        final List<_ProtectionMetric> metrics = [
          _ProtectionMetric(
            semanticLabel: '총 보호 동물',
            value: formatCount(statistics.total),
            iconBuilder: (double size, Color color) =>
                Icon(Icons.pets, size: size, color: color),
          ),
          _ProtectionMetric(
            semanticLabel: '강아지',
            value: formatCount(statistics.dogs),
            iconBuilder: (double size, Color color) =>
                Icon(Icons.cruelty_free_outlined, size: size, color: color),
          ),
          _ProtectionMetric(
            semanticLabel: '고양이',
            value: formatCount(statistics.cats),
            iconBuilder: (double size, Color color) =>
                Icon(Icons.pets_outlined, size: size, color: color),
          ),
          _ProtectionMetric(
            semanticLabel: '기타 동물',
            value: formatCount(statistics.others),
            iconBuilder: (double size, Color color) => Icon(
              Icons.emoji_nature_outlined,
              size: size,
              color: color,
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '보호 현황',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            if (isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  '보호 현황 정보를 불러오는 중 오류가 발생했습니다.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            _ProtectionMetricsRow(
              metrics: metrics,
              textTheme: textTheme,
              defaultIconColor: theme.colorScheme.primary,
            ),
          ],
        );
      },
    );
  }
}

class _ProtectionMetricsRow extends StatelessWidget {
  const _ProtectionMetricsRow({
    required this.metrics,
    required this.textTheme,
    required this.defaultIconColor,
  });

  final List<_ProtectionMetric> metrics;
  final TextTheme textTheme;
  final Color defaultIconColor;

  @override
  Widget build(BuildContext context) {
    const double minTileWidth = 120;
    const double itemSpacing = 24;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double requiredWidth = metrics.length * minTileWidth +
            (metrics.length - 1) * itemSpacing;

        if (maxWidth.isFinite && maxWidth >= requiredWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int index = 0; index < metrics.length; index++) ...[
                Expanded(
                  child: _ProtectionMetricTile(
                    metric: metrics[index],
                    textTheme: textTheme,
                    iconColor: defaultIconColor,
                    expand: true,
                    minWidth: minTileWidth,
                  ),
                ),
                if (index != metrics.length - 1)
                  const SizedBox(width: itemSpacing),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int index = 0; index < metrics.length; index++) ...[
                _ProtectionMetricTile(
                  metric: metrics[index],
                  textTheme: textTheme,
                  iconColor: defaultIconColor,
                  minWidth: minTileWidth,
                ),
                if (index != metrics.length - 1)
                  const SizedBox(width: itemSpacing),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProtectionMetric {
  const _ProtectionMetric({
    required this.value,
    required this.semanticLabel,
    required this.iconBuilder,
  });

  final String value;
  final String semanticLabel;
  final Widget Function(double size, Color color) iconBuilder;
}

class _ProtectionMetricTile extends StatelessWidget {
  const _ProtectionMetricTile({
    required this.metric,
    required this.textTheme,
    required this.iconColor,
    this.minWidth = 120,
    this.expand = false,
  });

  final _ProtectionMetric metric;
  final TextTheme textTheme;
  final Color iconColor;
  final double minWidth;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    const double resolvedIconSize = 36;
    final Widget iconWidget = metric.iconBuilder(resolvedIconSize, iconColor);

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(height: 8),
        Text(
          metric.value,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    final Widget wrappedContent = expand
        ? Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: content,
      ),
    )
        : SizedBox(width: minWidth, child: content);

    return Semantics(
      label: metric.semanticLabel,
      value: metric.value,
      child: wrappedContent,
    );
  }
}

















