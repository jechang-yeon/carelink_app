import 'package:flutter/material.dart';
import '../screens/search/address_search_screen.dart';

class AddressInputField extends StatelessWidget {
  final TextEditingController mainAddressController;
  final TextEditingController detailAddressController;

  const AddressInputField({
    super.key,
    required this.mainAddressController,
    required this.detailAddressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: mainAddressController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: '주소',
                  hintText: '오른쪽 버튼으로 주소를 검색하세요.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? '주소를 검색해주세요.' : null,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddressSearchScreen(),
                  ),
                );

                if (result != null && result is String) {
                  mainAddressController.text = result;
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              child: const Text('검색'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: detailAddressController,
          decoration: const InputDecoration(
            labelText: '상세 주소',
            hintText: '동, 호수 등 상세 주소를 입력하세요.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}