import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalStatistics {
  const AnimalStatistics({
    required this.total,
    required this.dogs,
    required this.cats,
    required this.others,
  });

  const AnimalStatistics.empty()
      : total = 0,
        dogs = 0,
        cats = 0,
        others = 0;

  final int total;
  final int dogs;
  final int cats;
  final int others;

  static const Set<String> _dogKeywords = {
    '개',
    '강아지',
    '멍멍이',
    'dog',
    'dogs',
  };

  static const Set<String> _catKeywords = {
    '고양이',
    '냥이',
    'cat',
    'cats',
  };

  bool get isEmpty => total == 0;

  factory AnimalStatistics.fromSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
    return AnimalStatistics.fromDocuments(snapshot.docs);
  }

  factory AnimalStatistics.fromDocuments(
      Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
      ) {
    var total = 0;
    var dogs = 0;
    var cats = 0;
    var others = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in documents) {
      total++;
      final Map<String, dynamic> data = doc.data();
      final String species = (data['species'] ?? data['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (_matchesKeyword(species, _dogKeywords)) {
        dogs++;
      } else if (_matchesKeyword(species, _catKeywords)) {
        cats++;
      } else {
        others++;
      }
    }

    return AnimalStatistics(
      total: total,
      dogs: dogs,
      cats: cats,
      others: others,
    );
  }

  AnimalStatistics copyWith({
    int? total,
    int? dogs,
    int? cats,
    int? others,
  }) {
    return AnimalStatistics(
      total: total ?? this.total,
      dogs: dogs ?? this.dogs,
      cats: cats ?? this.cats,
      others: others ?? this.others,
    );
  }

  Map<String, int> toMap() {
    return <String, int>{
      'total': total,
      'dogs': dogs,
      'cats': cats,
      'others': others,
    };
  }

  static bool _matchesKeyword(String value, Set<String> keywords) {
    if (value.isEmpty) {
      return false;
    }
    if (keywords.contains(value)) {
      return true;
    }
    for (final String keyword in keywords) {
      if (keyword.isEmpty) {
        continue;
      }
      if (value.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
