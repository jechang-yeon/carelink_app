import 'dart:async';

import 'package:carelink_app/models/shelter.dart';
import 'package:carelink_app/models/shelter_list_state.dart';
import 'package:carelink_app/models/staff_model.dart';
import 'package:carelink_app/screens/admin/staff_management_screen.dart';
import 'package:carelink_app/screens/auth/login_screen.dart';
import 'package:carelink_app/screens/logs/activity_log_screen.dart';
import 'package:carelink_app/screens/shelter/add_shelter_screen.dart';
import 'package:carelink_app/screens/shelter/edit_shelter_screen.dart';
import 'package:carelink_app/screens/shelter/shelter_detail_screen.dart';
import 'package:carelink_app/services/shelter_service.dart';
import 'package:carelink_app/widgets/dashboard_summary_card.dart';
import 'package:carelink_app/widgets/delete_confirmation_dialog.dart';
import 'package:carelink_app/widgets/responsive_layout.dart';
import 'package:carelink_app/widgets/shelter_filter_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final StaffModel user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _desktopSelectedIndex = 0;
  final ShelterService _shelterService = ShelterService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  String? _statusFilter;

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
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final String trimmedValue = value.trim();
    _searchDebounce?.cancel();
    if (trimmedValue == _searchQuery) {
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = trimmedValue;
      });
    });
  }

  void _clearSearch() {
    if (_searchQuery.isEmpty) {
      return;
    }
    _searchDebounce?.cancel();
    if (!mounted) {
      return;
    }
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _onStatusFilterChanged(String? value) {
    final String? normalizedValue =
    (value == null || value == '전체') ? null : value;
    if (_statusFilter == normalizedValue) {
      return;
    }
    setState(() {
      _statusFilter = normalizedValue;
    });
  }

  void _resetFilters() {
    final bool hadSearch = _searchQuery.isNotEmpty;
    final bool hadStatus = _statusFilter != null;
    if (!hadSearch && !hadStatus) {
      return;
    }
    _searchDebounce?.cancel();
    if (hadSearch) {
      _searchController.clear();
    }
    setState(() {
      if (hadSearch) {
        _searchQuery = '';
      }
      if (hadStatus) {
        _statusFilter = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(context),
      desktopBody: _buildDesktopLayout(context),
    );
  }

  Scaffold _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('케어링크 대시보드'),
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

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      if (widget.user.role == 'SystemAdmin')
        IconButton(
          icon: const Icon(Icons.manage_accounts_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const StaffManagementScreen()),
            );
          },
          tooltip: '직원 관리',
        ),
      IconButton(
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
      IconButton(
        icon: const Icon(Icons.logout_outlined),
        onPressed: () => _signOut(context),
        tooltip: '로그아웃',
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          child: DashboardSummaryCard(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<ShelterListState>(
            stream: _shelterService.watchShelters(
              searchQuery: _searchQuery,
              statusFilter: _statusFilter,
            ),
            builder: (context, snapshot) {
              final bool isInitialLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData;
              final ShelterListState state =
                  snapshot.data ?? const ShelterListState.empty();
              final List<String> statuses = state.availableStatuses;

              String dropdownValue = _statusFilter ?? '전체';
              if (!statuses.contains(dropdownValue)) {
                dropdownValue = '전체';
                if (_statusFilter != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _statusFilter = null;
                    });
                  });
                }
              }

              final bool filtersActive =
                  _searchQuery.isNotEmpty || _statusFilter != null;
              final bool showFilteredChip =
                  state.isFiltered || filtersActive;

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
                listContent = Center(
                  child: Text(
                    filtersActive
                        ? '선택한 조건에 맞는 보호소가 없습니다.'
                        : '등록된 보호소가 없습니다.',
                  ),
                );
              } else {
                listContent = ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                  itemCount: state.shelters.length,
                  itemBuilder: (context, index) {
                    final shelter = state.shelters[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFF7A00),
                          child: Icon(Icons.home, color: Colors.white),
                        ),
                        title: Text(
                          shelter.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('주소: ${shelter.address}'),
                              Text('상세 주소: ${shelter.addressDetail}'),
                              const SizedBox(height: 4),
                              Text('상태: ${shelter.status}'),
                              Text('관리자 UID: ${shelter.managerUid}'),
                            ],
                          ),
                        ),
                        trailing: (widget.user.role == 'SystemAdmin' ||
                            widget.user.role == 'AreaManager')
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
                                  builder: (context) => EditShelterScreen(
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
                                          _deleteShelter(context, shelter),
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
                      ),
                    );
                  },
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
                    child: ShelterFilterBar(
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      onClearSearch: _clearSearch,
                      statuses: statuses,
                      selectedStatus: dropdownValue,
                      onStatusChanged: _onStatusFilterChanged,
                      filtersActive: filtersActive,
                      onResetFilters: _resetFilters,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          '보호소 목록',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text('총 ${state.totalCount}곳'),
                        ),
                        if (showFilteredChip)
                          Chip(
                            backgroundColor: const Color(0xFFFFF3E0),
                            label: Text('필터 결과 ${state.filteredCount}곳'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(child: listContent),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}









