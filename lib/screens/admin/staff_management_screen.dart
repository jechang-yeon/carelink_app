import 'package:carelink_app/screens/admin/edit_staff_screen.dart';
import 'package:flutter/material.dart';
import '../../models/staff_model.dart';
import '../../services/user_service.dart';
import 'add_staff_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    // 데스크탑 레이아웃에 내장될 때를 대비하여 Scaffold를 분리
    return Scaffold(
      appBar: AppBar(
        title: const Text('직원 관리'),
      ),
      body: StreamBuilder<List<StaffModel>>(
        stream: _userService.getAllStaff(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('등록된 직원이 없습니다.'));
          }

          final staffList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                  title: Text(staff.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(staff.email),
                  trailing: Text(staff.role,
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditStaffScreen(staff: staff),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddStaffScreen()),
          );
        },
        tooltip: '신규 직원 등록',
        child: const Icon(Icons.add),
      ),
    );
  }
}