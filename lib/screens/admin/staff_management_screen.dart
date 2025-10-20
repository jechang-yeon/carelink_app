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
    // Scaffold 대신 StreamBuilder를 바로 반환하여 다른 화면에 내장될 수 있도록 함
    return StreamBuilder<List<StaffModel>>(
      stream: _userService.getAllStaff(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('등록된 직원이 없습니다.'));
        }

        final staffList = snapshot.data!;

        // 데스크탑 UI를 고려하여 FloatingActionButton을 ListView 위에 배치
        return Scaffold(
          body: ListView.builder(
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(staff.name),
                subtitle: Text(staff.email),
                trailing: Text(staff.role,
                    style: const TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditStaffScreen(staff: staff),
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
            backgroundColor: const Color(0xFFFF7A00),
            tooltip: '신규 직원 등록',
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        );
      },
    );
  }
}