import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/shelter.dart';
import '../models/shelter_list_state.dart';

/// 보호소 관련 Firestore 처리를 담당하는 서비스입니다.
///
/// 보호소 목록 스트림, 검색/상태 필터링, 삭제 시 하위 컬렉션 정리 등의 공통 로직을 제공합니다.
class ShelterService {
  ShelterService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<ShelterListState> watchShelters({
    String searchQuery = '',
    String? statusFilter,
  }) {
    return _firestore
        .collection('shelters')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<Shelter> shelters =
      snapshot.docs.map((doc) => Shelter.fromFirestore(doc)).toList();
      return ShelterService.buildShelterListState(
        shelters,
        searchQuery: searchQuery,
        statusFilter: statusFilter,
      );
    });
  }

  @visibleForTesting
  static ShelterListState buildShelterListState(
      List<Shelter> shelters, {
        String searchQuery = '',
        String? statusFilter,
      }) {
    final String normalizedQuery = searchQuery.trim().toLowerCase();
    final String? normalizedStatus =
    (statusFilter == null || statusFilter.trim().isEmpty)
        ? null
        : statusFilter.trim();

    final Set<String> statusSet = {
      for (final Shelter shelter in shelters)
        if (shelter.status.trim().isNotEmpty) shelter.status.trim(),
    };

    Iterable<Shelter> filtered = shelters;

    if (normalizedQuery.isNotEmpty) {
      filtered = filtered.where((Shelter shelter) {
        final String name = shelter.name.toLowerCase();
        final String address = shelter.address.toLowerCase();
        final String detail = shelter.addressDetail.toLowerCase();
        return name.contains(normalizedQuery) ||
            address.contains(normalizedQuery) ||
            detail.contains(normalizedQuery);
      });
    }

    if (normalizedStatus != null) {
      filtered = filtered.where(
            (Shelter shelter) => shelter.status.trim() == normalizedStatus,
      );
    }

    final List<Shelter> filteredShelters = filtered.toList();
    final List<String> sortedStatuses = statusSet.toList()
      ..removeWhere((status) => status == '전체')
      ..sort((a, b) => a.compareTo(b));

    return ShelterListState(
      shelters: filteredShelters,
      availableStatuses: <String>['전체', ...sortedStatuses],
      totalCount: shelters.length,
      filteredCount: filteredShelters.length,
    );
  }

  /// 보호소 문서를 삭제하기 전에 animals 하위 컬렉션을 정리합니다.
  ///
  /// Firestore는 서버에서 하위 컬렉션을 자동으로 삭제하지 않으므로,
  /// 클라이언트 단에서 배치 단위로 정리한 뒤 보호소 문서를 제거합니다.
  Future<void> deleteShelterWithAnimals(Shelter shelter) async {
    final DocumentReference<Map<String, dynamic>> shelterRef =
    _firestore.collection('shelters').doc(shelter.id);

    try {
      await _deleteAnimalsInBatches(shelterRef);
      await shelterRef.delete();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '보호소 삭제 중 Firestore 오류 발생(${shelter.id}): ${error.message}',
      );
      Error.throwWithStackTrace(error, stackTrace);
    } catch (error, stackTrace) {
      debugPrint('보호소 삭제 중 알 수 없는 오류(${shelter.id}): $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _deleteAnimalsInBatches(
      DocumentReference<Map<String, dynamic>> shelterRef,
      ) async {
    const int batchSize = 500;
    final CollectionReference<Map<String, dynamic>> animalsRef =
    shelterRef.collection('animals');

    while (true) {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await animalsRef.limit(batchSize).get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
      in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}




