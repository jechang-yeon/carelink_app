import 'package:carelink_app/services/map_service.dart';
import 'package:flutter/material.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, String>> _suggestions = <Map<String, String>>[];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final String query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = <Map<String, String>>[];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, String>> suggestions =
      await MapService.searchAddressSuggestions(query);
      setState(() {
        _suggestions = suggestions;
        if (suggestions.isEmpty) {
          _errorMessage = '검색 결과가 없습니다. 다른 키워드를 시도해보세요.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '주소 검색 중 오류가 발생했습니다. 다시 시도해주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectSuggestion(Map<String, String> suggestion) async {
    if (!mounted) return;

    final String placeId = suggestion['placeId'] ?? '';
    if (placeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 주소 정보를 불러올 수 없습니다.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    Map<String, dynamic>? detail;
    try {
      detail = await MapService.fetchPlaceDetail(placeId);
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }

    if (detail == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 주소의 상세 정보를 가져올 수 없습니다.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(detail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      labelText: '주소 검색',
                      hintText: '예: 서울특별시 중구 세종대로 110',
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions = <Map<String, String>>[];
                            _errorMessage = null;
                          });
                          _searchFocusNode.requestFocus();
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildResultArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          _errorMessage ?? '검색어를 입력해 주소를 찾아보세요.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, String> suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(suggestion['description'] ?? ''),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }
}
