import 'package:carelink_app/models/animal_statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalStatisticsService {
  AnimalStatisticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<AnimalStatistics> watchAnimalStatistics() {
    return _firestore
        .collectionGroup('animals')
        .snapshots()
        .map(AnimalStatistics.fromSnapshot);
  }
}
