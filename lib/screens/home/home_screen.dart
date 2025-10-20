import 'package:carelink_app/models/staff_model.dart';
import 'package:carelink_app/screens/admin/staff_management_screen.dart';
import 'package:carelink_app/screens/auth/login_screen.dart';
import 'package:carelink_app/widgets/dashboard_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carelink_app/models/shelter.dart';
import 'package:carelink_app/services/map_service.dart';
import 'package:carelink_app/widgets/delete_confirmation_dialog.dart';
import 'package:carelink_app/widgets/responsive_layout.dart';
import 'package:carelink_app/screens/shelter/add_shelter_screen.dart';
import 'package:carelink_app/screens/shelter/edit_shelter_screen.dart';
import 'package:carelink_app/screens/shelter/shelter_detail_screen.dart';
import 'package:carelink_app/screens/logs/activity_log_screen.dart';

class HomeScreen extends StatefulWidget {
  final StaffModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _desktopSelectedIndex = 0;

  Future<void> _deleteShelter(BuildContext context, Shelter shelter) async {
    try {
      await FirebaseFirestore.instance
          .collection('shelters')
          .doc(shelter.id)
          .delete();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('케어링크 대시보드'),
        backgroundColor: const Color(0xFF4A4A4A),
        actions: _buildAppBarActions(context),
      ),
      body: _buildDashboardContent(),
      floatingActionButton: widget.user.role == 'SystemAdmin'
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddShelterScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFFF7A00),
        tooltip: '신규 보호소 개설',
        child: const Icon(Icons.add, color: Colors.white),
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
          icon: const Icon(Icons.manage_accounts),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const StaffManagementScreen()),
            );
          },
          tooltip: '직원 관리',
        ),
      IconButton(
        icon: const Icon(Icons.receipt_long),
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
        icon: const Icon(Icons.logout),
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
      children: [
        const DashboardSummaryCard(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('shelters')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    '아직 운영중인 보호소가 없습니다.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final shelters = snapshot.data!.docs
                  .map((doc) => Shelter.fromFirestore(doc))
                  .toList();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: shelters.length,
                itemBuilder: (context, index) {
                  final shelter = shelters[index];
                  final mapUrl = (shelter.latitude != null &&
                      shelter.longitude != null)
                      ? MapService.getStaticMapUrl(
                    latitude: shelter.latitude!,
                    longitude: shelter.longitude!,
                    width: 120,
                    height: 80,
                  )
                      : null;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: mapUrl != null
                            ? Image.network(
                          mapUrl,
                          width: 100,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.map, size: 40),
                        )
                            : Container(
                          width: 100,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.map,
                              color: Colors.grey, size: 40),
                        ),
                      ),
                      title: Text(shelter.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text('${shelter.address} ${shelter.addressDetail}'),
                      trailing: (widget.user.role == 'SystemAdmin' || widget.user.role == 'AreaManager')
                          ? PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditShelterScreen(shelter: shelter),
                              ),
                            );
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (context) => DeleteConfirmationDialog(
                                title: '보호소 삭제',
                                content: '정말로 ${shelter.name} 보호소를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
                                onConfirm: () => _deleteShelter(context, shelter),
                              ),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('수정'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('삭제'),
                          ),
                        ],
                      )
                          : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShelterDetailScreen(user: widget.user, shelter: shelter),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}